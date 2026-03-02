# Business Flow — Meeting Prepper

Document detailing the business flow of **Meeting Prepper**: from trigger to briefing delivery and exceptions.

---

## 1. Objective

Prepare the user for meetings with an **executive briefing** that combines:
- **Active pending items** (uncompleted action points) relevant to the meeting
- **Historical context** (daily memory, projects, people, decisions) useful for that meeting

The delivery can be **automatic** (cron + Google Calendar + Slack) or **on-demand** (skill in Claude Code, with meeting data provided by the user).

---

## 2. Two modes of operation

| Mode | Trigger | Meeting Source | Delivery |
|------|---------|-------------------|----------|
| **Automatic** | Cron every 10 min | Google Calendar API (next 30 min) | Slack DM (U01DHE5U6MA) |
| **On-demand** | User asks for "meeting briefing" / "meeting prepper" | Title (and optionally participants/description) provided by user | Chat (Claude shows the briefing) |

The **briefing content** is the same in both modes: template **Active Pending Items** + **Historical Context**, generated from the same memory files.

---

## 3. Automatic flow (cron + script)

### 3.1 Trigger

- **Cron OpenClaw**: every 10 minutes (`*/10 * * * *`, Europe/Madrid).
- Session key: `agent:main:cron:meeting_prepper`.
- The agent executes the script:
  `/home/ulisses/.openclaw/workspace/scripts/meeting_prepper_wrapper.sh`

### 3.2 Authentication and secrets

1. The **wrapper** reads `OP_SERVICE_ACCOUNT_TOKEN` from `op_secrets.env` and exports it to the environment.
2. Executes: `op run --env-file=op_secrets.env -- python3 meeting_prepper.py`
3. **1Password** injects into the environment (from refs in `op_secrets.env`):
   - `GOOGLE_CAL_CLIENT_ID`
   - `GOOGLE_CAL_CLIENT_SECRET`
   - `GOOGLE_CAL_REFRESH_TOKEN`
   - (optional) `WHATSAPP_TARGET` (default: +351919651334)

If the token or refs fail, the script exits with an error and cron reports to the user (reconfigure: see `GOOGLE_CAL_RECONFIGURE.md`).

### 3.3 Getting meetings (Google Calendar)

1. **OAuth2**: refresh token → access token; build Google Calendar API v3 client.
2. **"Unavailable" rule**:
   - If there's an event **"Unavailable"** at **00:00** or **all-day** on that day (Europe/Madrid), the script **does not process any meeting** and exits with success (exit 0). Log: "Day marked as Unavailable. Meeting Prepper does not execute."
3. **Time window**: events that **start** in the **next 30 minutes** (UTC).
4. **Filters**:
   - Only events **with participants** (attendees); personal blocks without participants are ignored.
   - Events with title "Unavailable" (individual) are ignored.
5. **Data per meeting**: `uid`, `title`, `description`, `participants`, `start`.

If there are no events in this window: log "No meetings in the next 30 minutes.", exit 0.

### 3.4 Prevent resends (processed meetings cache)

- File: `workspace/memory/.processed_meetings.txt`
- Contains one **UID per line** (Google Calendar event ID or `title|start_iso`).
- For each meeting obtained:
  - If the UID is in the file → **ignore** (don't generate briefing or send). Log: "Meeting already processed, skipping: [title]".
  - If not → continue to briefing generation.

### 3.5 Briefing generation (reasoner)

For each meeting **not** processed:

1. **Invocation**: `openclaw agent --agent reasoner --message "<prompt>" --timeout 180`
2. **Prompt** includes:
   - Meeting title, participants, and description.
   - **Mandatory instructions**: read (via tools) the files:
     - `workspace/memory/action_points.md` — pending items
     - `workspace/memory/YYYY-MM-DD.md` — daily memory (today's date)
     - `workspace/memoria_agente/*.md` — profile, people, projects, pending items, etc.
     - `workspace/MEMORY.md` — executive memory
   - Request for output in exact format:
     - **ACTIVE PENDING ITEMS:** only items not marked with `[x]` relevant to participants/topic; or "No active pending items".
     - **HISTORICAL CONTEXT:** concise summary of what's useful for this meeting (notes, projects, people, decisions, risks).
3. **Timeout**: 180 s for the reasoner; the script has extra buffer (195 s) in `subprocess.run`.
4. If reasoner fails or returns empty: log the error, **do not** mark UID as processed (will be retried in next cycle). Move to next meeting.

### 3.6 Delivery via Slack DM

1. **Send**: Slack SDK `conversations.open` + `chat.postMessage` to user `U01DHE5U6MA`.
2. If send fails: log the error, **do not** mark UID as processed. Move to next meeting.
3. If send succeeds:
   - **Append** the UID to `memory/.processed_meetings.txt`.
   - Log: "Briefing sent via Slack."

### 3.7 Cron agent behavior

- If the script **sends** briefing via Slack: agent responds with **NO_REPLY** (avoid duplicating message in chat).
- If the script **fails** (Calendar error, 1Password, timeout, etc.): agent responds with error message to user.
- Service account errors (1Password) or Google authentication (403, expired refresh token): indicate to Ulisses that reconfiguration is needed (`GOOGLE_CAL_RECONFIGURE.md`).

---

## 4. On-demand flow (Claude Code skill)

Used when the user explicitly asks for a briefing (e.g., "meeting briefing", "meeting prepper", "prepare me for meeting X") **without** depending on cron or Google Calendar.

### 4.1 Trigger

- Phrases like: "meeting briefing", "meeting prepper", "prepare me for the meeting", "what do I need to know for meeting X".
- Or the user shares meeting title/participants/description and asks for a summary.

### 4.2 Getting meeting data

- If the user already provided **title** (and optionally **participants** and **description**): use that data.
- If not: ask the user to provide meeting details (title and if possible participants and description) or to paste invite/Google Calendar data.

### 4.3 Reading files (mandatory)

In Claude Code, paths are in `~/.claude/memory/` (synchronized from Notion via `sync-notion-memory.sh`):

| File | Purpose |
|------|---------|
| `~/.claude/memory/action_points.md` | Active pending items (items without `[x]`) → **Active Pending Items** section |
| `~/.claude/memory/memory/YYYY-MM-DD.md` | Daily memory (today's context) |
| `~/.claude/memory/memoria_agente/*.md` | Profile, people, projects, pending items, decisions, guidelines, etc. |
| `~/.claude/memory/MEMORY.md` | General executive memory (current state, projects, next steps) |

### 4.4 Briefing generation

- **Exact format**:
  - **ACTIVE PENDING ITEMS:** list only incomplete items relevant to participants or meeting topic; or "No active pending items".
  - **HISTORICAL CONTEXT:** concise summary of what's useful for this meeting (avoid generic text).
- Filter pending items by relevance; always include the Active Pending Items section.

### 4.5 Delivery

- Show the briefing to the user in the chat.
- Optional: suggest manual send via Slack or running wrapper in OpenClaw for the complete flow (Calendar + automatic send).

---

## 5. Data sources (summary)

| Data | File / origin |
|------|-------------------|
| Active pending items | `~/.claude/memory/action_points.md` (Claude Code) / `workspace/memory/action_points.md` (OpenClaw) |
| Daily memory | `~/.claude/memory/memory/YYYY-MM-DD.md` / `workspace/memory/YYYY-MM-DD.md` |
| People, projects, profile, general pending items | `~/.claude/memory/memoria_agente/*.md` / `workspace/memoria_agente/*.md` |
| Executive state, decisions, next steps | `~/.claude/memory/MEMORY.md` / `workspace/MEMORY.md` |
| Processed meetings (automatic flow only) | `workspace/memory/.processed_meetings.txt` |
| Meetings (automatic flow only) | Google Calendar API (next 30 min) |
| **Primary source** | Notion [Clawdia Memory](https://www.notion.so/Clawdia-Memory-312d9a25aaca80689a81cbe3376ab260) — sync via `~/.claude/scripts/sync-notion-memory.sh` |

---

## 6. Business rules and exceptions

- **"Unavailable" day**: event "Unavailable" at 00:00 or all-day → don't execute Meeting Prepper that day (automatic flow).
- **Meeting already processed**: UID in `.processed_meetings.txt` → don't generate new briefing or resend (automatic flow).
- **Reasoner or Slack failure**: don't add UID to cache; in next cycle (10 min) the same meeting will be retried.
- **Timeout**: reasoner 180 s; cron with margin (e.g. 300 s). If session ends before send, the meeting is not marked as processed and will be reprocessed.

---

## 7. Flow diagram (automatic)

```
[Cron 10 min] → [Wrapper: export OP_SERVICE_ACCOUNT_TOKEN]
       → [op run → meeting_prepper.py]
       → [Load op_secrets.env / resolve 1Password credentials]
       → [Google Calendar API: events next 30 min, with participants]
       → [If "Unavailable" day → exit 0]
       → [For each event not in .processed_meetings.txt]
              → [openclaw agent reasoner: read action_points, memory, memoria_agente, MEMORY.md]
              → [Generate briefing: Active Pending Items + Historical Context]
              → [send_slack(briefing)]
              → [Append UID to .processed_meetings.txt]
       → [Log "Briefing sent" / NO_REPLY in cron]
```
