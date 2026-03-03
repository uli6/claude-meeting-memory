---
name: pre-meeting
description: "Generates executive briefings before meetings. Reads emails (Himalaya), action points, daily memory, memoria_agente and MEMORY.md; generates structured briefing (Active Pending Items + Historical Context). Use when the user asks for meeting briefing, meeting prepper, or meeting preparation."
---

# Pre-Meeting (Meeting Briefing Skill)

Generates executive briefing before meetings using emails (Himalaya IMAP), pending items and memory stored in `~/.claude/memory/`. The skill reads emails and local memory files to create contextual briefings.

**Memory sources:** Emails (Himalaya), Action points, daily notes, user profile, people, projects, and executive memory (MEMORY.md)

**Business flow:** See [BUSINESS_FLOW.md](BUSINESS_FLOW.md) for the complete flow.

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

### 2. Read emails and memory files

**First, search emails via Himalaya:**
- Use meeting title and participant names to find related emails
- Extract relevant context from email subjects, senders, and previews

**Then, read files in ~/.claude/memory/:**

All memory files are in `~/.claude/memory/`:

| File | Purpose |
|------|---------|
| `~/.claude/memory/action_points.md` | Active pending items (items not marked with `[x]`) — **source for "Active Pending Items"** |
| `~/.claude/memory/memoria_agente/user_profile.md` | User profile and context |
| `~/.claude/memory/memoria_agente/people.md` | Key people and relationships |
| `~/.claude/memory/memoria_agente/projects.md` | Current projects and status |
| `~/.claude/memory/MEMORY.md` | Executive memory — decisions, dates, important information |

**How to handle missing files:**
- Read all `.md` files in `~/.claude/memory/memoria_agente/` that exist
- If files are empty/missing: continue with available files (they build up over time)
- Memory grows as you use `/read-this` and when email automation populates files

### 3. Generate the briefing with this exact format

Produce an **Executive Briefing** structured like this:

```
🔥 ACTIVE PENDING ITEMS:
(List ONLY the items not marked with [x] from action_points.md that are relevant to this meeting's participants or topic. If none, write "No active pending items".)

📚 HISTORICAL CONTEXT:
(Concise summary of daily notes, memoria_agente and MEMORY.md relevant to this meeting: projects, people, decisions, risk assessment, etc.)

📧 EMAIL CONTEXT:
(Summary of key topics from related emails: decisions, discussions, topics that participants mentioned. If no relevant emails found, say "No related emails found".)
```

Rules:

- Always include the **Active Pending Items** section; don't omit even if there are few.
- Filter pending items by relevance to participants or meeting title when possible.
- Historical context: only what's useful for this meeting; avoid generic text.

### 4. Deliver the result

- Show the briefing to the user in the chat.

## Himalaya Configuration

This skill requires Himalaya to be installed and configured:

```bash
# Install Himalaya (if not already installed)
brew install himalaya  # macOS
# or
apt install himalaya   # Linux

# Configure your email account
himalaya account configure
# Follow the interactive setup to connect your email (Gmail, ProtonMail, etc.)
```

Once configured, the skill automatically reads emails when generating briefings.

## Memory Population

Your memory grows through:

1. **Manual entry** — Edit files in `~/.claude/memory/memoria_agente/` directly
2. **Using /read-this** — When you read documents, summaries are saved to memory
3. **Email context** — Himalaya automatically provides recent emails related to meetings

Start with whatever context you have, and memory builds over time.

## Memory Structure in ~/.claude/

```
~/.claude/
├── memory/
│   ├── action_points.md                    # Your pending items
│   ├── MEMORY.md                           # Executive memory
│   └── memoria_agente/
│       ├── user_profile.md                 # Your profile
│       ├── people.md                       # Key contacts
│       ├── projects.md                     # Current projects
│       └── decisions.md                    # Important decisions
└── skills/
    └── pre-meeting/
        └── SKILL.md
```

## How to Maximize Briefing Quality

**Immediately after setup:**
- Fill your profile: `~/.claude/memory/memoria_agente/user_profile.md`
- Add key people: `~/.claude/memory/memoria_agente/people.md`
- List projects: `~/.claude/memory/memoria_agente/projects.md`

**Over time:**
- Use `/read-this` to save important documents and notes
- Enable email automation (optional) to automatically populate memory
- Update MEMORY.md with strategic context and decisions

The more context you provide, the better your briefings will be.

---

## Summary

1. Get meeting title (and if possible participants and description)
2. Search emails via Himalaya for related topics/participants
3. Read available memory files: action_points.md, memoria_agente/*.md, MEMORY.md
4. Generate briefing with template: **Active Pending Items** + **Historical Context** + **Email Context**
5. Show briefing to user in chat
6. Note: Memory grows over time as you populate it manually; emails are automatically searched
