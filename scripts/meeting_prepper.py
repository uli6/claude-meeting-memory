#!/usr/bin/env python3
"""
Meeting Prepper (on-demand mode)
- Reads emails via Himalaya IMAP for meeting context
- Generates briefing via Claude (action_points, memory, memoria_agente, MEMORY.md)
- Delivered via chat in Claude Code

This script is called by the /pre-meeting skill in Claude Code.
No longer cron-based; it's on-demand only.

For corporate networks with VPN: export GOOGLE_SKIP_SSL_VERIFY=1 (for requests lib)
"""
import os
import subprocess
from datetime import datetime
from pathlib import Path

MEMORY_DIR = Path(os.environ.get("MEMORY_DIR", os.path.expanduser("~/.claude/memory")))


def get_env(name: str, default: str = None) -> str:
    val = os.environ.get(name, default)
    if val is None:
        raise SystemExit(f"Error: {name} not set")
    return val


def fetch_emails_from_himalaya(query_terms: list[str], limit: int = 50) -> list[dict]:
    """
    Gets emails via Himalaya CLI.

    Args:
        query_terms: List of search keywords (meeting title, participants, etc.)
        limit: Maximum number of emails to read

    Returns:
        List of dicts with From, Subject, Date, Body from found emails
    """
    try:
        # Get list of envelopes (last N emails)
        result = subprocess.run(
            ["himalaya", "envelope", "list", "--limit", str(limit)],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            print(f"Himalaya error: {result.stderr}")
            return []

        emails = []
        lines = result.stdout.strip().split("\n")

        # Parse: each line is an envelope (UID Subject From Date)
        # Format: "uid | subject | from | date"
        for line in lines:
            if not line.strip():
                continue
            parts = line.split("|")
            if len(parts) < 4:
                continue

            uid = parts[0].strip()
            subject = parts[1].strip()
            from_addr = parts[2].strip()
            date = parts[3].strip()

            # Check if any search term is in subject or from
            match = any(
                term.lower() in subject.lower() or term.lower() in from_addr.lower()
                for term in query_terms
                if term.strip()
            )

            if match:
                # Try to read email body
                body = ""
                try:
                    read_result = subprocess.run(
                        ["himalaya", "read", uid],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if read_result.returncode == 0:
                        body = read_result.stdout[:500]  # First 500 chars
                except:
                    pass

                emails.append({
                    "uid": uid,
                    "subject": subject,
                    "from": from_addr,
                    "date": date,
                    "body": body
                })

                # Limit to 10 emails for context
                if len(emails) >= 10:
                    break

        return emails
    except FileNotFoundError:
        print("Himalaya not found. Install it: brew install himalaya (or apt install himalaya)")
        return []
    except Exception as e:
        print(f"Error fetching emails: {e}")
        return []


def _load_claude_settings() -> dict:
    """Loads ~/.claude/settings.json and applies env. Returns the settings object."""
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
    """Gets token: ANTHROPIC_API_KEY > ~/.config/tompero/requester_token > apiKeyHelper (ifood_auth)."""
    # 1. Env (meeting-prepper-secrets.env)
    token = os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if token:
        return token
    # 2. tompero file (cron-friendly: without running tompero)
    token_file = Path.home() / ".config" / "tompero" / "requester_token"
    if token_file.is_file():
        token = token_file.read_text(encoding="utf-8").strip()
        if token:
            return token
    # 3. apiKeyHelper from settings.json (ifood_auth.sh or cat ~/.config/tompero/requester_token)
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
    # 4. If helper is a command (e.g., "cat ~/.config/tompero/requester_token")
    if " " in helper or not os.path.isfile(helper):
        import subprocess
        try:
            token = subprocess.check_output(["bash", "-c", helper], timeout=10).decode().strip()
            if token:
                return token
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
    raise SystemExit("Token not obtained. Check: ANTHROPIC_API_KEY, ~/.config/tompero/requester_token, or apiKeyHelper in settings.json")


def generate_briefing(meeting: dict, emails: list[dict]) -> str:
    """Generates briefing via API (HTTP direct). Uses config from ~/.claude/settings.json."""
    import requests

    _load_claude_settings()  # applies env from settings.json
    token = _get_auth_token()
    base_url = os.environ.get("ANTHROPIC_BASE_URL")
    if not base_url:
        raise SystemExit("ANTHROPIC_BASE_URL not defined. Set it in ~/.claude/settings.json env or environment.")
    custom_headers = {}
    if os.environ.get("ANTHROPIC_CUSTOM_HEADERS"):
        h = os.environ["ANTHROPIC_CUSTOM_HEADERS"]
        if ":" in h:
            k, v = h.split(":", 1)
            custom_headers[k.strip()] = v.strip()

    title = meeting["title"]
    participants_str = ", ".join(meeting.get("participants", ["(not specified)"]))
    description = meeting.get("description", "") or "(no description)"

    # Email context
    email_context = ""
    if emails:
        email_context = "Recent emails relevant to this meeting:\n"
        for email in emails[:10]:
            email_context += f"- From: {email['from']}\n  Subject: {email['subject']}\n  Date: {email['date']}\n"
            if email['body']:
                email_context += f"  Preview: {email['body'][:200]}...\n"
        email_context += "\n"

    prompt = f"""I have the following meeting: {title}. Participants: {participants_str}. Description: {description}.

{email_context}

MANDATORY EXECUTION INSTRUCTIONS:
1. Read IMMEDIATELY the file memory/action_points.md.
2. Also read the daily memories: memory/* (and, if useful, other recent files in /memory/).
3. For context on people, projects and profile: read the .md files in memoria_agente/ (e.g. user_profile.md, people.md, projects.md) and MEMORY.md if it exists. Use what is relevant for this meeting.
4. **Conflicts:** When there are conflicting decisions or preferences (two versions of the same rule in memoria_agente), use only the most recent entry.
5. If emails were provided above, search for key topics and participants mentioned.
6. Generate an Executive Briefing structured exactly like this (output in English):

🔥 ACTIVE PENDING ITEMS: (List here ONLY action items that are relevant to this meeting. Match participants by name. Exclude items marked with [x]. If none match, say "No active pending items").

📚 HISTORICAL CONTEXT: (Summary of old notes, daily memory, memoria_agente and MEMORY.md when relevant, Risk Assessment, email topics, etc).

Be direct and never skip the Active Pending Items section."""

    # API max 200k tokens. ~1 token ≈ 4 chars. Use ~50k tokens (~200k chars) for margin.
    MAX_CHARS = 200_000

    def _trunc(s: str, max_chars: int) -> str:
        s = (s or "").strip()
        if len(s) <= max_chars:
            return s
        return s[: max_chars - 80] + "\n\n[... truncated due to context limit ...]"

    memory_path = MEMORY_DIR
    action_points = (memory_path / "action_points.md").read_text(encoding="utf-8") if (memory_path / "action_points.md").exists() else ""
    memory_today = ""
    memory_dir = memory_path / "memory"
    if memory_dir.exists():
        files = sorted(memory_dir.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)
        for f in files[:5]:
            memory_today += f"\n--- {f.name} ---\n" + f.read_text(encoding="utf-8")
    memoria_agente = ""
    if (memory_path / "memoria_agente").exists():
        for f in sorted((memory_path / "memoria_agente").glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True):
            memoria_agente += f"\n--- {f.name} ---\n" + f.read_text(encoding="utf-8")
    memory_md = (memory_path / "MEMORY.md").read_text(encoding="utf-8") if (memory_path / "MEMORY.md").exists() else ""

    # Limits per section (total ~200k chars)
    ap_max, mem_max, ma_max, mm_max = 20_000, 50_000, 80_000, 50_000

    context = f"""
=== action_points.md ===
{_trunc(action_points, ap_max)}

=== memory (today and recent) ===
{_trunc(memory_today, mem_max) or '(empty)'}

=== memoria_agente ===
{_trunc(memoria_agente, ma_max) or '(empty)'}

=== MEMORY.md ===
{_trunc(memory_md, mm_max) or '(empty)'}
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


def main(meeting_title: str = "", participants: list[str] = None, description: str = ""):
    """
    Generates briefing for a meeting.

    Args:
        meeting_title: Meeting title
        participants: List of participants (names/emails)
        description: Meeting description
    """
    if not meeting_title:
        raise SystemExit("meeting_title required")

    if participants is None:
        participants = []

    meeting = {
        "title": meeting_title,
        "participants": participants,
        "description": description,
    }

    # Prepare search terms for emails
    query_terms = [meeting_title]
    query_terms.extend(participants)

    print(f"Meeting Prepper: generating briefing for '{meeting_title}'")
    print(f"Searching for related emails...")

    # Search for emails
    emails = fetch_emails_from_himalaya(query_terms)
    if emails:
        print(f"Found {len(emails)} relevant emails")
    else:
        print("No emails found (continuing with memory context)")

    try:
        briefing = generate_briefing(meeting, emails)
    except Exception as e:
        print(f"Error generating briefing: {e}")
        return 1

    if not briefing:
        print("Empty briefing")
        return 1

    print("\n" + "="*60)
    print(briefing)
    print("="*60)

    return 0


if __name__ == "__main__":
    import sys

    # Arguments: meeting_title [participant1,participant2,...] [description]
    meeting_title = sys.argv[1] if len(sys.argv) > 1 else ""
    participants = []
    description = ""

    if len(sys.argv) > 2:
        participants = [p.strip() for p in sys.argv[2].split(",") if p.strip()]

    if len(sys.argv) > 3:
        description = sys.argv[3]

    exit(main(meeting_title, participants, description))
