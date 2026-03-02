---
name: remind-me
description: "Creates entries in action_points.md. Use ALWAYS when the user says 'remind me of this', 'remind me to', 'remind me' or similar. With Slack link executes add_action_point.py. Without link uses the text."
---

# Remind Me (Action Points)

**IMPORTANT:** When the user says "remind me of this", "remind me to", "remind me" or similar — **EXECUTE immediately** the `add_action_point.py` script. **DO NOT** respond that you cannot access Slack links. The script obtains content via API.

## Triggers (execute the script whenever you see)

- "remind me of this" (with Slack link)
- "remind me to [X]"
- "remind me of [X]"
- "add to action points"
- "create an action point"

## Flow

### 1. With Slack link

If the user pastes a Slack URL (e.g., `https://workspace.slack.com/archives/C.../p...`) and says "remind me of this" or similar:

1. Extract the Slack URL from the message.
2. Execute the script with the URL:
   ```bash
   cd ~/.claude/scripts && op run --env-file=meeting-prepper-secrets.env -- python3 add_action_point.py --slack-url "PASTED_URL" "remind me of this"
   ```
3. The script obtains the message content from Slack, uses the LLM to format it, and adds it to `action_points.md`.

### 2. Without Slack link

If the user only says "remind me to talk with Sheila about M&A" (or similar):

1. Execute the script with the text:
   ```bash
   cd ~/.claude/scripts && op run --env-file=meeting-prepper-secrets.env -- python3 add_action_point.py "remind me to talk with Sheila about M&A"
   ```
2. The script uses the LLM to format it and adds it to `action_points.md`.

### 3. Entry format

All entries follow this format:
```
- [ ] @[Name]: [Subject] (Created: YYYY-MM-DD)
```

Example: `- [ ] @Sheila: Pending conversation about M&A processes and Deloitte topic (Created: 2026-02-24)`

## Alternative (without op run)

If the user already has environment variables set (SLACK_BOT_TOKEN, etc.):
```bash
~/.claude/scripts/add_action_point.py "remind me to X"
```

## Paths

- Script: `~/.claude/scripts/add_action_point.py`
- Destination: `~/.claude/memory/action_points.md`
- Secrets: `~/.claude/scripts/meeting-prepper-secrets.env`
