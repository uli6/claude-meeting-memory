#!/usr/bin/env python3
"""
Adiciona entrada em ~/.claude/memory/action_points.md

Uso:
  add_action_point.py "me lembre de falar com Sheila sobre M&A"
  add_action_point.py --slack-url "https://workspace.slack.com/archives/C123/p123..." "me lembre disso"

Formato da entrada: - [ ] @[Nome]: [Assunto] (Criado em: YYYY-MM-DD)
"""
import os
import ssl

if os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1" or os.environ.get("SLACK_SKIP_SSL_VERIFY") == "1":
    ssl._create_default_https_context = ssl._create_unverified_context
import re
from datetime import datetime
from pathlib import Path

def _memory_dir() -> Path:
    """Diretório de memória: MEMORY_DIR ou ~/.claude/memory (relativo ao script)."""
    if os.environ.get("MEMORY_DIR"):
        return Path(os.environ["MEMORY_DIR"])
    # Usar pasta do script: scripts/ -> memory/
    base = Path(__file__).resolve().parent.parent
    return base / "memory"

MEMORY_DIR = _memory_dir()
ACTION_POINTS = MEMORY_DIR / "action_points.md"


def get_env(name: str, default: str = None) -> str:
    val = os.environ.get(name, default)
    if val is None:
        raise SystemExit(f"Error: {name} not set")
    return val


def fetch_slack_message(url: str, token: str) -> str:
    """Extrai channel, ts e thread_ts do URL. Suporta canal, thread e DM (channel_id começa com D)."""
    m = re.search(r"/archives/([A-Za-z0-9]+)/p(\d+)", url)
    if not m:
        raise SystemExit(f"URL Slack inválido: {url}")
    channel_id, ts_raw = m.group(1), m.group(2)
    ts = f"{ts_raw[:10]}.{ts_raw[10:]}" if len(ts_raw) > 10 else ts_raw

    thread_ts = None
    tm = re.search(r"[?&]thread_ts=([\d.]+)", url)
    if tm:
        thread_ts = tm.group(1)

    from slack_sdk import WebClient
    from slack_sdk.errors import SlackApiError

    client_kwargs = {"token": token}
    if os.environ.get("SLACK_SKIP_SSL_VERIFY") == "1" or os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1":
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        client_kwargs["ssl"] = ctx

    client = WebClient(**client_kwargs)
    try:
        def _is_system(msg):
            t = msg.get("text") or ""
            return msg.get("subtype") in {"channel_join", "channel_leave", "group_join", "group_leave"} or "has joined" in t.lower() or "has left" in t.lower()

        def _fetch_replies(parent_ts: str, until_ts: str = None) -> list:
            out = []
            cursor = None
            for _ in range(20):
                kwargs = {"channel": channel_id, "ts": parent_ts, "limit": 200}
                if until_ts:
                    kwargs["latest"] = f"{float(until_ts) + 0.001:.6f}" if "." in until_ts else f"{until_ts}.999999"
                if cursor:
                    kwargs["cursor"] = cursor
                resp = client.conversations_replies(**kwargs)
                ms = resp.get("messages", [])
                out.extend(ms)
                if any(m.get("ts") == ts for m in ms):
                    break
                meta = resp.get("response_metadata", {})
                cursor = meta.get("next_cursor")
                if not cursor or not resp.get("has_more", False):
                    break
            return out

        def _pick_best(msgs_list: list) -> list:
            user_msgs = [m for m in msgs_list if not _is_system(m) and m.get("text")]
            link_msg = next((m for m in msgs_list if m.get("ts") == ts), None)
            if link_msg and not _is_system(link_msg) and link_msg.get("text"):
                return [link_msg]
            if user_msgs:
                return user_msgs
            return msgs_list

        def _has_good_content(m_list):
            return m_list and any(not _is_system(m) and m.get("text") for m in m_list)

        msgs = []
        # 1) Thread (com thread_ts): mensagem é reply na thread
        if thread_ts:
            all_replies = _fetch_replies(thread_ts, until_ts=ts)
            msgs = _pick_best(all_replies)

        # 2) Mensagem como parent da thread (link = raiz)
        if not _has_good_content(msgs):
            try:
                alt = _fetch_replies(ts)
                if _has_good_content(alt):
                    msgs = _pick_best(alt)
            except SlackApiError:
                pass

        # 3) Canal/DM top-level (mensagem direta, não em thread)
        if not _has_good_content(msgs):
            try:
                resp = client.conversations_history(channel=channel_id, latest=ts, inclusive=True, limit=1)
                hist = resp.get("messages", [])
                if hist and not _is_system(hist[0]) and hist[0].get("text"):
                    msgs = hist
            except SlackApiError:
                pass

        # Fallback: usar o que tivermos (mesmo system) para não falhar
        if not msgs and thread_ts:
            try:
                msgs = _pick_best(_fetch_replies(thread_ts))
            except SlackApiError:
                pass

        if not msgs:
            raise SystemExit("Mensagem não encontrada no Slack.")

        def user_name(uid):
            if not uid:
                return ""
            try:
                r = client.users_info(user=uid)
                return r.get("user", {}).get("real_name") or r.get("user", {}).get("name") or uid
            except Exception:
                return uid

        # Ignorar mensagens de sistema (channel_join, etc.) que não têm conteúdo útil
        skip_subtypes = {"channel_join", "channel_leave", "group_join", "group_leave"}

        parts = []
        for m in msgs:
            if m.get("subtype") in skip_subtypes:
                continue
            txt = m.get("text", "").strip()
            if not txt:
                continue
            if "has joined" in txt.lower() or "has left" in txt.lower():
                continue  # ignorar mensagens de sistema
            author = user_name(m.get("user"))
            if author:
                parts.append(f"[{author}]: {txt}")
            else:
                parts.append(txt)
        content = "\n---\n".join(parts) if parts else " ".join(m.get("text", "") for m in msgs)
        if any(m.get("files") for m in msgs):
            content += "\n[anexos]"
        out = content.strip()
        if os.environ.get("ADD_ACTION_POINT_DEBUG"):
            import sys
            dbg = []
            for i, m in enumerate(msgs):
                dbg.append(f"  [{i}] ts={m.get('ts')} text={repr((m.get('text') or '')[:80])}")
            print("[DEBUG] msgs:", len(msgs), "| ts_buscado:", ts, file=sys.stderr)
            print("[DEBUG]", "\n".join(dbg), file=sys.stderr)
            print("[DEBUG] Conteúdo final:", repr(out)[:800], file=sys.stderr)
        return out
    except SlackApiError as e:
        raise SystemExit(f"Slack API error: {e.response.get('error', e)}")


def format_entry_with_llm(content: str, is_from_slack: bool, slack_url: str = None) -> str:
    """Usa Claude para gerar entrada no formato - [ ] @Nome: Assunto (Criado em: YYYY-MM-DD)."""
    today = datetime.now().strftime("%Y-%m-%d")
    if is_from_slack:
        url_note = f"\nSlack URL (incluir no final da linha): {slack_url}" if slack_url else ""
        prompt = f"""Given this Slack message/thread content, create a single action point entry in Portuguese.

Content:
{content}
{url_note}

Output ONLY one line in this exact format:
- [ ] @[PersonName]: [Brief subject summarizing the action] (Criado em: {today}) [Link](url)

Rules:
- Extract the person/team from context if mentioned. Summarize the actual topic/action from the conversation.
- ALWAYS include the Slack link at the end so the user can reference the source.
- If the content is minimal (e.g. system messages), summarize as: @Slack: Ver conversa no link abaixo (Criado em: {today}) [Link](url)
- No extra text, no explanations."""
    else:
        prompt = f"""Given this reminder request, create a single action point entry in Portuguese.

User request: {content}

Output ONLY one line in this exact format:
- [ ] @[PersonName]: [Brief subject] (Criado em: {today})

Example: "me lembre de falar com Sheila sobre M&A" → - [ ] @Sheila: Conversa pendente sobre processos de M&A (Criado em: {today})
No extra text."""

    settings_path = Path(os.path.expanduser("~/.claude/settings.json"))
    data = {}
    if settings_path.exists():
        import json
        data = json.loads(settings_path.read_text(encoding="utf-8"))
        for k, v in data.get("env", {}).items():
            if isinstance(v, str) and k not in os.environ:
                os.environ[k] = v

    helper = data.get("apiKeyHelper", "~/.claude/ifood_auth.sh")
    helper = str(Path(helper).expanduser())
    if Path(helper).is_file():
        import subprocess
        token = subprocess.check_output(["bash", helper], timeout=30).decode().strip()
    else:
        raise SystemExit("apiKeyHelper não encontrado.")

    import anthropic
    client_kwargs = {"api_key": token}
    if os.environ.get("ANTHROPIC_BASE_URL"):
        client_kwargs["base_url"] = os.environ["ANTHROPIC_BASE_URL"]
        client_kwargs.setdefault("default_headers", {})["Authorization"] = f"Bearer {token}"
    if os.environ.get("ANTHROPIC_CUSTOM_HEADERS"):
        h = os.environ["ANTHROPIC_CUSTOM_HEADERS"]
        if ":" in h:
            k, v = h.split(":", 1)
            client_kwargs.setdefault("default_headers", {})[k.strip()] = v.strip()

    client = anthropic.Anthropic(**client_kwargs)
    msg = client.messages.create(
        model=os.environ.get("ANTHROPIC_DEFAULT_SONNET_MODEL", "claude-sonnet-4-20250514"),
        max_tokens=256,
        messages=[{"role": "user", "content": prompt}],
    )
    text = (msg.content[0].text if msg.content else "").strip()
    if "cannot create" in text.lower() or "cannot determine" in text.lower() or "no actionable" in text.lower():
        text = f"- [ ] @Slack: Ver conversa (Criado em: {today})"
    if not text.startswith("- [ ]"):
        text = "- [ ] " + text
    if f"(Criado em: {today})" not in text:
        text = text.rstrip(")") + f" (Criado em: {today})"
    if slack_url and slack_url not in text and "[Link]" not in text:
        text = text.rstrip() + f" [Link]({slack_url})"
    return text


def append_to_action_points(entry: str) -> None:
    path = ACTION_POINTS.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    content = path.read_text(encoding="utf-8") if path.exists() else ""
    if content and not content.endswith("\n"):
        content += "\n"
    content += entry + "\n"
    path.write_text(content, encoding="utf-8")
    if os.environ.get("ADD_ACTION_POINT_DEBUG"):
        import sys
        print(f"[DEBUG] Escrito em: {path}", file=sys.stderr)


def extract_slack_url_from_text(text: str) -> str | None:
    """Extrai a primeira URL do Slack do texto (ex: link colado na mensagem)."""
    m = re.search(r"https?://[^\s]+slack\.com/archives/[A-Za-z0-9]+/p\d+", text)
    return m.group(0).rstrip("?)") if m else None


def main():
    import sys
    args = sys.argv[1:]
    slack_url = None
    if "--slack-url" in args:
        idx = args.index("--slack-url")
        if idx + 1 < len(args):
            slack_url = args[idx + 1]
            args = args[:idx] + args[idx + 2:]
    text = " ".join(args).strip() if args else ""
    # Se a mensagem contém um link do Slack, usar esse (prioridade sobre --slack-url)
    url_in_text = extract_slack_url_from_text(text)
    if url_in_text:
        slack_url = url_in_text
    if not text and not slack_url:
        print("Uso: add_action_point.py [--slack-url URL] \"me lembre de...\" ou \"me lembre disso\"")
        sys.exit(1)

    content = ""
    is_from_slack = False
    if slack_url and "slack.com" in slack_url:
        token = get_env("SLACK_BOT_TOKEN", "")
        if not token:
            print("SLACK_BOT_TOKEN não definido. Use meeting-prepper-secrets.env ou op run.")
            sys.exit(1)
        content = fetch_slack_message(slack_url, token)
        is_from_slack = True
    else:
        content = text

    entry = format_entry_with_llm(content, is_from_slack, slack_url=slack_url if slack_url else None)
    append_to_action_points(entry)
    print(f"Adicionado a action_points.md:\n{entry}")


if __name__ == "__main__":
    main()
