# Business Flow — Meeting Prepper

Document detailing the business flow of **Meeting Prepper**: from trigger to briefing delivery.

---

## 1. Objective

Prepare the user for meetings with an **executive briefing** that combines:
- **Active pending items** (uncompleted action points) relevant to the meeting
- **Historical context** (daily memory, projects, people, decisions) useful for that meeting
- **Email context** (recent emails via Himalaya IMAP) relevant to participants or topics

The delivery is **on-demand** (skill in Claude Code, with meeting data provided by the user).

---

## 2. Mode of operation (On-demand)

| Aspect | Detail |
|--------|--------|
| **Trigger** | User asks for "meeting briefing" / "meeting prepper" / "prepare me for the meeting" |
| **Meeting source** | Title (mandatory) + Participants/description (optional) provided by user |
| **Email source** | Himalaya IMAP (`himalaya envelope list`) — searches by meeting title and participant names |
| **Delivery** | Chat (Claude shows the briefing) |

The **briefing content** combines: **Active Pending Items** + **Historical Context** + **Email Context**, generated from memory files and emails.

---

## 3. On-demand flow (Claude Code skill)

Used when the user explicitly asks for a briefing (e.g., "meeting briefing", "meeting prepper", "prepare me for meeting X") **reading emails via Himalaya**.

### 3.1 Trigger

- Phrases like: "meeting briefing", "meeting prepper", "prepare me for the meeting", "what do I need to know for meeting X".
- Or the user shares meeting title/participants/description and asks for a summary.

### 3.2 Getting meeting data

- If the user already provided **title** (and optionally **participants** and **description**): use that data.
- If not: ask the user to provide meeting details (title and if possible participants and description).

### 3.3 Reading emails (Himalaya - IMAP)

1. **Command**: `himalaya envelope list --limit 50` — get the last 50 emails
2. **Filtering**: search emails where **subject** or **sender** contain:
   - Meeting title
   - Participant names
   - Related topics
3. **Context extraction**: extract From, Subject, Date and body preview (first 500 chars) from matching emails
4. **Limit**: maximum 10 emails for briefing context (to stay within token limits)

### 3.4 Reading memory files (mandatory)

In Claude Code, paths are in `~/.claude/memory/`:

| File | Purpose |
|------|---------|
| `~/.claude/memory/action_points.md` | Active pending items (items without `[x]`) → **Active Pending Items** section |
| `~/.claude/memory/memory/YYYY-MM-DD.md` | Daily memory (today's context) |
| `~/.claude/memory/memoria_agente/*.md` | Profile, people, projects, pending items, decisions, guidelines, etc. |
| `~/.claude/memory/MEMORY.md` | General executive memory (current state, projects, next steps) |

### 3.5 Briefing generation

- **Exact format**:
  - **ACTIVE PENDING ITEMS:** list only incomplete items relevant to participants or meeting topic; or "No active pending items".
  - **HISTORICAL CONTEXT:** concise summary of what's useful for this meeting (avoid generic text).
  - **EMAIL CONTEXT:** summary of key topics from related emails (decisions, discussions, topics mentioned by participants); or "No related emails found".
- Filter pending items by relevance; always include the Active Pending Items section.

### 3.6 Delivery

- Show the briefing to the user in the chat.

---

## 4. Data sources (summary)

| Data | File / origin |
|------|---------|
| Active pending items | `~/.claude/memory/action_points.md` |
| Daily memory | `~/.claude/memory/memory/YYYY-MM-DD.md` |
| People, projects, profile, general pending items | `~/.claude/memory/memoria_agente/*.md` |
| Executive state, decisions, next steps | `~/.claude/memory/MEMORY.md` |
| Emails | Himalaya IMAP CLI (`himalaya envelope list`, `himalaya read <msg-id>`) |
| **Memory primary source** | Local memory files in `~/.claude/memory/` |
| **Email primary source** | Himalaya IMAP — configured in `~/.config/himalaya/config.toml` |

---

## 5. Business rules and exceptions

- **Himalaya not configured**: skill displays warning "Himalaya not configured. Configure at `~/.config/himalaya/config.toml`".
- **No emails found**: skill continues with memory context only (doesn't fail).
- **Participant not found in emails**: skill uses only memory and action_points (emails are optional).
- **Himalaya CLI error**: skill gracefully falls back to memory-only briefing.

---

## 6. Flow diagram (on-demand)

```
[User: "meeting briefing X"]
       → [Claude asks for title/participants if not provided]
       → [Himalaya: himalaya envelope list --limit 50]
       → [Filter emails by subject/sender match]
       → [Read: action_points.md, memory/YYYY-MM-DD.md, memoria_agente/*, MEMORY.md]
       → [Generate briefing: Active Pending Items + Historical Context + Email Context]
       → [Show in chat]
```
