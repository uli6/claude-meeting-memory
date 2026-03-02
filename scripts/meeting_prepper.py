#!/usr/bin/env python3
"""
Meeting Prepper (modo automático)
- Consulta Google Calendar: próxima reunião nos próximos 30 min
- Gera briefing via Claude (action_points, memory, memoria_agente, MEMORY.md)
- Envia DM para Slack (U01DHE5U6MA)

Executar via meeting_prepper_wrapper.sh (carrega secrets do 1Password).
Cron: */10 * * * * (a cada 10 min)

Em redes corporativas com VPN: export GOOGLE_SKIP_SSL_VERIFY=1
"""
import os
import ssl
from datetime import datetime, timedelta
from pathlib import Path

# VPN/proxy corporativo: bypass SSL para todas as conexões HTTPS
if os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1" or os.environ.get("SLACK_SKIP_SSL_VERIFY") == "1":
    ssl._create_default_https_context = ssl._create_unverified_context

# User ID do destinatário da DM. Definir SLACK_DM_USER_ID em meeting-prepper-secrets.env.
# Obter em Slack: perfil > Mais > Copiar ID do membro (ex: U01DHE5U6MA)
SLACK_USER_ID = os.environ.get("SLACK_DM_USER_ID", "U01DHE5U6MA")
PROCESSED_FILE = ".processed_meetings.txt"
MEMORY_DIR = Path(os.environ.get("MEMORY_DIR", os.path.expanduser("~/.claude/memory")))


def get_env(name: str, default: str = None) -> str:
    val = os.environ.get(name, default)
    if val is None:
        raise SystemExit(f"Error: {name} not set")
    return val


def fetch_next_meeting():
    """Obtém a próxima reunião do Google Calendar (janela 30 min)."""
    import httplib2
    import requests
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from google_auth_httplib2 import AuthorizedHttp
    from googleapiclient.discovery import build

    client_id = get_env("GOOGLE_CAL_CLIENT_ID")
    client_secret = get_env("GOOGLE_CAL_CLIENT_SECRET")
    refresh_token = get_env("GOOGLE_CAL_REFRESH_TOKEN")

    creds = Credentials(
        token=None,
        refresh_token=refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=client_id,
        client_secret=client_secret,
        scopes=["https://www.googleapis.com/auth/calendar.events.readonly"],
    )
    # Token refresh: usar session com verify=False em redes corporativas
    if os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1":
        session = requests.Session()
        session.verify = False
        import urllib3
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        creds.refresh(Request(session=session))
    else:
        creds.refresh(Request())

    # HTTP com SSL desativado (VPN/proxy corporativo)
    http = httplib2.Http(disable_ssl_certificate_validation=(os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1"))
    http = AuthorizedHttp(creds, http=http)
    service = build("calendar", "v3", http=http)
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)

    # Regra "Ausente": evento todo-o-dia "Ausente" hoje → não processar
    day_events = (
        service.events()
        .list(
            calendarId="primary",
            timeMin=today_start.isoformat() + "Z",
            timeMax=today_end.isoformat() + "Z",
            singleEvents=True,
        )
        .execute()
    )
    for ev in day_events.get("items", []):
        if ev.get("status") == "cancelled":
            continue
        title = (ev.get("summary") or "").lower()
        if "ausente" in title:
            start = ev.get("start", {})
            if start.get("date"):  # all-day
                print("Dia marcado como Ausente. Meeting Prepper não executa.")
                return None

    time_min = now.isoformat() + "Z"
    time_max = (now + timedelta(minutes=30)).isoformat() + "Z"

    events = (
        service.events()
        .list(
            calendarId="primary",
            timeMin=time_min,
            timeMax=time_max,
            singleEvents=True,
            orderBy="startTime",
        )
        .execute()
    )

    items = events.get("items", [])
    for ev in items:
        if ev.get("status") == "cancelled":
            continue
        title = ev.get("summary", "(Sem título)")
        if "ausente" in title.lower():
            continue
        attendees = ev.get("attendees") or []
        if not attendees:
            continue
        participants = [a.get("email", a.get("displayName", "?")) for a in attendees]
        description = ev.get("description", "") or ""
        start = ev.get("start", {}).get("dateTime") or ev.get("start", {}).get("date", "")
        uid = ev.get("id") or f"{title}|{start}"
        return {
            "uid": uid,
            "title": title,
            "participants": participants,
            "description": description,
            "start": start,
        }
    return None


def is_processed(uid: str) -> bool:
    f = MEMORY_DIR / PROCESSED_FILE
    if not f.exists():
        return False
    return uid.strip() in {line.strip() for line in f.read_text().splitlines() if line.strip()}


def mark_processed(uid: str) -> None:
    (MEMORY_DIR / PROCESSED_FILE).parent.mkdir(parents=True, exist_ok=True)
    with open(MEMORY_DIR / PROCESSED_FILE, "a") as f:
        f.write(uid + "\n")


def _load_claude_settings() -> dict:
    """Carrega ~/.claude/settings.json e aplica env. Retorna o objeto settings."""
    settings_path = Path(os.path.expanduser("~/.claude/settings.json"))
    if not settings_path.exists():
        return {}
    try:
        import json
        data = json.loads(settings_path.read_text(encoding="utf-8"))
        env = data.get("env", {})
        for k, v in env.items():
            if isinstance(v, str) and k not in os.environ:
                os.environ[k] = v
        return data
    except Exception:
        return {}


def _get_auth_token() -> str:
    """Obtém token: ANTHROPIC_API_KEY > ~/.config/tompero/requester_token > apiKeyHelper (ifood_auth)."""
    # 1. Env (meeting-prepper-secrets.env)
    token = os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if token:
        return token
    # 2. Ficheiro tompero (cron-friendly: sem executar tompero)
    token_file = Path.home() / ".config" / "tompero" / "requester_token"
    if token_file.is_file():
        token = token_file.read_text(encoding="utf-8").strip()
        if token:
            return token
    # 3. apiKeyHelper do settings.json (ifood_auth.sh ou cat ~/.config/tompero/requester_token)
    settings = _load_claude_settings()
    helper = settings.get("apiKeyHelper", "~/.claude/ifood_auth.sh")
    helper = os.path.expanduser(helper)
    if os.path.isfile(helper):
        import subprocess
        try:
            token = subprocess.check_output(["bash", helper], timeout=30).decode().strip()
            if token:
                return token
        except subprocess.CalledProcessError:
            pass
    # 4. Se helper for comando (ex: "cat ~/.config/tompero/requester_token")
    if " " in helper or not os.path.isfile(helper):
        import subprocess
        try:
            token = subprocess.check_output(["bash", "-c", helper], timeout=10).decode().strip()
            if token:
                return token
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
    raise SystemExit("Token não obtido. Verificar: ANTHROPIC_API_KEY, ~/.config/tompero/requester_token, ou apiKeyHelper em settings.json")


def generate_briefing(meeting: dict) -> str:
    """Gera briefing via GenPlat (HTTP direto). Usa config de ~/.claude/settings.json."""
    import requests

    _load_claude_settings()  # aplica env de settings.json
    token = _get_auth_token()
    base_url = os.environ.get("ANTHROPIC_BASE_URL")
    if not base_url:
        raise SystemExit("ANTHROPIC_BASE_URL não definido. Definir em ~/.claude/settings.json env ou no ambiente.")
    custom_headers = {}
    if os.environ.get("ANTHROPIC_CUSTOM_HEADERS"):
        h = os.environ["ANTHROPIC_CUSTOM_HEADERS"]
        if ":" in h:
            k, v = h.split(":", 1)
            custom_headers[k.strip()] = v.strip()

    title = meeting["title"]
    participants_str = ", ".join(meeting["participants"])
    description = meeting["description"] or "(sem descrição)"

    prompt = f"""I have the following meeting in 30 minutes: {title}. Participants: {participants_str}. Description: {description}.

MANDATORY EXECUTION INSTRUCTIONS:
1. Read IMMEDIATELY the file memory/action_points.md.
2. Also read the daily memories: memory/* (and, if useful, other recent files in /memory/).
3. For context on people, projects and profile: read the .md files in memoria_agente/ (e.g. perfil_usuario.md, pessoas.md, projetos.md, pendencias.md) and MEMORY.md if it exists. Use what is relevant for this meeting.
4. **Conflitos:** Em decisões ou preferências conflituantes (duas versões da mesma regra em memoria_agente), usar apenas a entrada mais recente.
5. Search for mentions of the participants in the memories and old files.
6. Generate an Executive Briefing structured exactly like this (output in English):

🔥 ACTIVE ACTION ITEMS: (List here ONLY action items whose assignee (@Name) is one of the meeting participants: {participants_str}. Match by name (e.g. @Ulisses matches "Ulisses Oliveira"). Exclude items for people not in this meeting. Exclude items marked with [x]. Items with @Grupo or generic reminders: include only if relevant to these participants. If none match, say "No active action items").

📚 HISTORICAL CONTEXT: (Summary of old notes, daily memory, memoria_agente and MEMORY.md when relevant, Risk Assessment, etc).

Be direct and never skip the Active Action Items section."""

    # API max 200k tokens. ~1 token ≈ 4 chars. Usar ~50k tokens (~200k chars) para margem.
    MAX_CHARS = 200_000

    def _trunc(s: str, max_chars: int) -> str:
        s = (s or "").strip()
        if len(s) <= max_chars:
            return s
        return s[: max_chars - 80] + "\n\n[... truncado por limite de contexto ...]"

    memory_path = MEMORY_DIR
    action_points = (memory_path / "action_points.md").read_text(encoding="utf-8") if (memory_path / "action_points.md").exists() else ""
    memory_today = ""
    memory_dir = memory_path / "memory"
    if memory_dir.exists():
        files = sorted(memory_dir.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)
        for f in files[:5]:
            memory_today += f"\n--- {f.name} ---\n" + f.read_text(encoding="utf-8")
    memoria_agente = ""
    for f in sorted((memory_path / "memoria_agente").glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True):
        memoria_agente += f"\n--- {f.name} ---\n" + f.read_text(encoding="utf-8")
    memory_md = (memory_path / "MEMORY.md").read_text(encoding="utf-8") if (memory_path / "MEMORY.md").exists() else ""

    # Limites por secção (total ~200k chars)
    ap_max, mem_max, ma_max, mm_max = 20_000, 50_000, 80_000, 50_000

    context = f"""
=== action_points.md ===
{_trunc(action_points, ap_max)}

=== memory (hoje e recentes) ===
{_trunc(memory_today, mem_max) or '(vazio)'}

=== memoria_agente ===
{_trunc(memoria_agente, ma_max) or '(vazio)'}

=== MEMORY.md ===
{_trunc(memory_md, mm_max) or '(vazio)'}
"""

    model = os.environ.get("ANTHROPIC_DEFAULT_SONNET_MODEL", "claude-sonnet-4-20250514")
    url = base_url.rstrip("/") + "/v1/messages"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "anthropic-version": "2023-06-01",
        **custom_headers,
    }
    body = {
        "model": model,
        "max_tokens": 4096,
        "system": f"You have access to the following memory context. Use it to respond to the request. Output the briefing in English.\n{context}",
        "messages": [{"role": "user", "content": prompt}],
    }
    verify_ssl = os.environ.get("GOOGLE_SKIP_SSL_VERIFY") != "1"
    resp = requests.post(url, json=body, headers=headers, timeout=120, verify=verify_ssl)
    resp.raise_for_status()
    data = resp.json()
    content = data.get("content", [])
    text = content[0].get("text", "") if content else ""
    return text.strip()


def _briefing_to_slack(briefing: str, meeting_title: str) -> tuple[list, str]:
    """Retorna (blocks para mensagem principal, texto estruturado para thread)."""
    import re

    def _to_mrkdwn(text: str) -> str:
        """Converte markdown para mrkdwn do Slack."""
        text = (text or "").strip()
        text = re.sub(r"\*\*(.+?)\*\*", r"*\1*", text)
        text = re.sub(r"^-\s+", "• ", text, flags=re.M)
        text = re.sub(r"^\d+\.\s+", "• ", text, flags=re.M)
        text = re.sub(r"^\*\s+", "• ", text, flags=re.M)
        return text

    pendencias = ""
    contexto = ""
    ctx_match = re.search(r"(?::books:|📚)\s*(?:\*\*)?(?:CONTEXTO HISTÓRICO|HISTORICAL CONTEXT)(?:\*\*)?\s*:?\s*\n+", briefing, re.I)
    if ctx_match:
        pendencias = briefing[: ctx_match.start()].strip()
        contexto = briefing[ctx_match.end() :].strip()
        for prefix in [":fire:", "🔥", "PENDÊNCIAS ATIVAS", "ACTIVE ACTION ITEMS", "pendências ativas"]:
            if prefix.lower() in pendencias.lower():
                idx = pendencias.lower().find(prefix.lower()) + len(prefix)
                pendencias = pendencias[idx:].lstrip(":* \n").strip()
                break
    else:
        pendencias = briefing[:1500] if briefing else ""

    if not pendencias and not contexto:
        pendencias = briefing[:800] if briefing else "Briefing vazio."

    # Mensagem principal: só o intro
    intro = f"Here is your briefing for the meeting *{meeting_title}*"
    main_blocks = [
        {"type": "section", "text": {"type": "mrkdwn", "text": intro}},
        {"type": "context", "elements": [{"type": "mrkdwn", "text": "⏱ You have 30 minutes. See thread for full briefing."}]},
    ]

    # Thread: briefing completo e bem estruturado
    thread_parts = []
    if pendencias:
        thread_parts.append("*🔥 Active Action Items*\n" + _to_mrkdwn(pendencias))
    if contexto:
        thread_parts.append("*📚 Historical Context*\n" + _to_mrkdwn(contexto))
    thread_text = "\n\n---\n\n".join(thread_parts) if thread_parts else briefing

    return main_blocks, thread_text


def send_slack_dm(message: str, meeting_title: str = "") -> bool:
    """Envia DM para o utilizador via Slack SDK. Usa Block Kit e thread para melhor legibilidade."""
    import ssl
    from slack_sdk import WebClient
    from slack_sdk.errors import SlackApiError

    token = get_env("SLACK_BOT_TOKEN", "")
    if not token:
        print("SLACK_BOT_TOKEN não definido, ignorando envio Slack")
        return False
    client_kwargs = {"token": token}
    if os.environ.get("SLACK_SKIP_SSL_VERIFY") == "1" or os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1":
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        client_kwargs["ssl"] = ctx
    client = WebClient(**client_kwargs)
    # user_id = destinatário da DM. Para Bot tokens, auth_test retorna o BOT (não o humano).
    # Usar SLACK_DM_USER_ID ou SLACK_USER_ID (U01DHE5U6MA).
    user_id = os.environ.get("SLACK_DM_USER_ID") or SLACK_USER_ID
    if not user_id:
        print("SLACK_DM_USER_ID ou SLACK_USER_ID não definido. Definir em meeting-prepper-secrets.env")
        return False
    try:
        resp = client.conversations_open(users=[user_id])
        channel = resp["channel"]["id"]
        blocks, thread_text = _briefing_to_slack(message, meeting_title or "Reunião")
        intro_text = f"Here is your briefing for the meeting {meeting_title or 'Reunião'}"
        msg_resp = client.chat_postMessage(
            channel=channel,
            text=intro_text,
            blocks=blocks,
        )
        ts = msg_resp.get("ts")
        if ts and thread_text:
            client.chat_postMessage(channel=channel, thread_ts=ts, text=thread_text)
        return True
    except SlackApiError as e:
        print(f"Slack error: {e.response['error']}")
        return False


def main():
    meeting = None
    is_test = os.environ.get("MEETING_PREPPER_TEST") == "1"
    if is_test and os.environ.get("MEETING_PREPPER_TEST_TITLE"):
        title = os.environ["MEETING_PREPPER_TEST_TITLE"]
        participants = os.environ.get("MEETING_PREPPER_TEST_PARTICIPANTS", "").split(",")
        participants = [p.strip() for p in participants if p.strip()] or ["(not specified)"]
        description = os.environ.get("MEETING_PREPPER_TEST_DESCRIPTION", "")
        meeting = {"uid": f"test-{title}", "title": title, "participants": participants, "description": description}
        print(f"Meeting Prepper: modo TESTE com reunião '{title}'")
    else:
        print("Meeting Prepper: verificando agenda...")
        meeting = fetch_next_meeting()
        if not meeting:
            print("Nenhuma reunião nos próximos 30 minutos.")
            return 0
        uid = meeting["uid"]
        if is_processed(uid):
            print(f"Reunião já processada, pulando: {meeting['title']}")
            return 0
        print(f"Reunião encontrada: {meeting['title']}")

    uid = meeting["uid"]
    try:
        briefing = generate_briefing(meeting)
    except Exception as e:
        print(f"Erro ao gerar briefing: {e}")
        return 1

    if not briefing:
        print("Briefing vazio, não enviando")
        return 1

    if send_slack_dm(briefing, meeting.get("title", "")):
        if not is_test:
            mark_processed(uid)
        print("Briefing enviado por Slack.")
    else:
        print("Falha ao enviar Slack, não marcando como processado")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
