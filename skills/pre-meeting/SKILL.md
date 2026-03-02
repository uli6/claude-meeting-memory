---
name: meeting-prepper
description: "Generates executive briefings before meetings. Reads action points, daily memory, memoria_agente and MEMORY.md; generates structured briefing (Active Pending Items + Historical Context). Use when the user asks for meeting briefing, meeting prepper, or meeting preparation."
---

# Meeting Prepper (Claude Code Skill)

Generates executive briefing before meetings using pending items and memory in `~/.claude/memory/`. Data is synchronized from Notion via script; the skill only reads local files.

**Source:** [Clawdia Memory](https://www.notion.so/Clawdia-Memory-312d9a25aaca80689a81cbe3376ab260) on Notion. Synchronize with `~/.claude/scripts/sync-notion-memory.sh` before generating briefings.

**Business flow:** See [BUSINESS_FLOW.md](BUSINESS_FLOW.md) for the complete flow (automatic + on-demand).

## How to execute (Claude Code)

Write one of these phrases in the chat:

- **"Meeting briefing"** or **"Meeting prepper"**
- **"Prepare me for the meeting"**
- **"What do I need to know for the meeting [title]?"**

If you don't specify title/participants, Claude will ask. You can paste calendar or invite data.

---

## When to use

- User asks for "meeting briefing", "meeting prepper", "prepare me for the meeting" or "what do I need to know for meeting X".
- User shares meeting title/participants/description and wants a summary with pending items and context.

## Flow (what to do)

### 1. Get meeting data

- If the user already provided **title**, **participants**, and (optional) **description**, use that data.
- If not: ask the user to provide the meeting details (title and if possible participants and description) or to paste calendar/invite data.

### 2. Read files in ~/.claude/memory/

All paths are in `~/.claude/memory/` (or `$HOME/.claude/memory/`).

| File | Purpose |
|------|---------|
| `~/.claude/memory/action_points.md` | Active pending items (items not marked with `[x]`) — **source for "Active Pending Items"** |
| `~/.claude/memory/memory/YYYY-MM-DD.md` | Daily memory (replace YYYY-MM-DD with today's date) |
| `~/.claude/memory/memoria_agente/*.md` | Profile, people, projects, pending items, etc. |
| `~/.claude/memory/MEMORY.md` | General executive memory — strategic context and next steps |

- Read all `.md` files in `~/.claude/memory/memoria_agente/` that exist.
- If any file doesn't exist, continue with the ones that do and briefly note what's missing.
- If the `~/.claude/memory/memory/` folder is empty or missing, suggest the user run sync: `~/.claude/scripts/sync-notion-memory.sh`

### 3. Generate the briefing with this exact format

Produce an **Executive Briefing** structured like this:

```
🔥 ACTIVE PENDING ITEMS:
(List ONLY the items not marked with [x] from action_points.md that are relevant to this meeting's participants or topic. If none, write "No active pending items".)

📚 HISTORICAL CONTEXT:
(Concise summary of daily notes, memoria_agente and MEMORY.md relevant to this meeting: projects, people, decisions, risk assessment, etc. Be direct.)
```

Rules:

- Always include the **Active Pending Items** section; don't omit even if there are few.
- Filter pending items by relevance to participants or meeting title when possible.
- Historical context: only what's useful for this meeting; avoid generic text.

### 4. Deliver the result

- Show the briefing to the user in the chat.

## Sync (bidirectional: Notion ↔ ~/.claude/memory/)

Before generating briefings, synchronize:

```bash
~/.claude/scripts/sync-notion-memory.sh
```

**Cron (every 30 min):** `*/30 * * * * ~/.claude/scripts/sync-notion-memory.sh >> /tmp/sync-notion-memory.log 2>&1`

- **Bidirectional:** changes from Notion are pulled; local changes are sent to Notion.
- **Timestamp:** always uses the most recent version (Notion vs local).
- **Skip:** if there are no changes on either side, the script exits with "No updates" without doing anything.
- **1Password CLI:** the Notion token is obtained via `op read`. Configure in `~/.claude/scripts/sync-notion-memory.conf` (optional).

## Structure in ~/.claude/

```
~/.claude/
├── memory/                    # Data synchronized from Notion
│   ├── action_points.md
│   ├── MEMORY.md
│   ├── memory/                # Daily memory (YYYY-MM-DD.md)
│   │   └── YYYY-MM-DD.md
│   └── memoria_agente/
│       ├── user_profile.md
│       ├── people.md
│       └── ...
├── scripts/
│   └── sync-notion-memory.sh  # Sync Notion → memory/
└── skills/
    └── pre-meeting/
        └── SKILL.md
```

## Automatic mode (cron + Slack)

A script runs every 10 minutes (`meeting_prepper_wrapper.sh`):

1. Queries **Google Calendar** — next meeting in the next 30 minutes
2. Gets title, participants, and description
3. Generates briefing via Claude (same prompt and sources)
4. Sends **Slack DM** to `U01DHE5U6MA`

See `~/.claude/scripts/README-meeting-prepper.md` for configuration (1Password, cron, etc.).

---

## Summary

1. Get meeting title (and if possible participants and description).
2. Read `~/.claude/memory/action_points.md`, `~/.claude/memory/memory/YYYY-MM-DD.md`, `~/.claude/memory/memoria_agente/*.md`, `~/.claude/memory/MEMORY.md`.
3. Generate briefing with the template **Active Pending Items** + **Historical Context**.
4. Show the briefing to the user. If memory/ is empty, suggest running sync.
