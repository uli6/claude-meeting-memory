---
name: remind-me
description: "Creates action point entries in action_points.md. Use when the user says 'remind me of this', 'remind me to', 'remind me' or similar."
---

# Remind Me (Create Action Points)

Creates action point entries directly in your memory when you want to capture something to do.

## Triggers

Use this skill when the user says:
- "remind me to [action]"
- "remind me of [action]"
- "add to action points: [action]"
- "create an action point for [action]"

## How It Works

When you ask me to remind you of something, I:

1. **Parse the action** — Extract the main action or task from what you said
2. **Format it** — Create a properly structured entry
3. **Add to memory** — Write it to `~/.claude/memory/action_points.md`

## Entry Format

All action points follow this structure:

```markdown
- [ ] [Action Description] (Created: YYYY-MM-DD)
  - [Optional details]
```

Examples:
```markdown
- [ ] Call Sheila about M&A process (Created: 2026-03-02)
- [ ] Review project proposal before Thursday meeting (Created: 2026-03-02)
  - Meeting with marketing team
- [ ] Follow up on budget approval (Created: 2026-03-02)
  - CFO response needed by Friday
```

## Destination

All action points are saved to: `~/.claude/memory/action_points.md`

Your `/pre-meeting` briefing will include these action points automatically.
