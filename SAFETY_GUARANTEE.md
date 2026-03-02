# Safety Guarantee

## NO AUTONOMOUS ACTIONS

This system **NEVER** performs actions on behalf of the user without explicit user command.

### What This System NEVER Does

- ❌ **Send emails** - Never composes or sends emails
- ❌ **Delete emails** - Never deletes or modifies email messages
- ❌ **Post to Slack on behalf of user** - Never sends messages to other users or channels (except direct message to user's own Slack ID)
- ❌ **Create calendar events** - Never modifies calendar
- ❌ **Modify external data** - Never changes anything outside `~/.claude/memory/`

### What This System IS ALLOWED To Do

- ✅ **Send Slack DMs to user only** - Sends meeting briefings directly to the user's Slack ID (provided during setup)

### What This System ONLY Does

#### Read Operations (Read-Only)
- ✅ Reads emails from Gmail (via Gmail API, read-only scope)
- ✅ Reads Slack messages (only when user explicitly shares link)
- ✅ Reads Google Docs (when user provides link)
- ✅ Reads calendar events (only for display purposes)

#### Write Operations (Local Only)
- ✅ Writes to `~/.claude/memory/` files
- ✅ Updates action_points.md, MEMORY.md, people.md, projects.md
- ✅ Stores summaries and extracted information locally
- ✅ Marks action items as closed based on content matching

#### Process Operations (Information Only)
- ✅ Analyzes content with Gemini API
- ✅ Extracts keywords, dates, people, projects
- ✅ Generates briefings for Claude chat
- ✅ Sends meeting briefings to user's Slack DM (optional, configured during setup)
- ✅ Suggests action item closures (user still controls action_points.md)

---

## Critical Safety Principles

### 1. No External State Changes
- System **only reads** from external services
- System **only writes** to local files in `~/.claude/memory/`
- No changes to Gmail, Slack, Google Calendar, or any external system

### 2. User Control Always
- User decides what to do with extracted information
- User manually takes actions (send email, post to Slack, etc.)
- System only provides data and suggestions

### 3. Local Data Only
- All sensitive information stays on user's machine
- No data sent to external services except:
  - Gmail API (read-only credentials)
  - Google Calendar API (read-only)
  - Gemini API (for processing, no storage)

### 4. Transparent Operations
- All actions are logged in console output
- User can see exactly what the system is doing
- No hidden operations

---

## What Happens With Action Items

When an email is processed:

```
1. Email arrives
2. Gemini processes content
3. Action items EXTRACTED (added to local file)
4. Content CHECKED against open items
5. Matching items SUGGESTED for closure
6. **USER REVIEWS** action_points.md
7. User MANUALLY marks items complete if appropriate
```

**System never automatically marks items as closed in a way that affects external systems.**
Items are only marked in local `action_points.md` file that user controls.

---

## Permissions Granted

### Gmail API
- **Scope:** `gmail.readonly` - READ ONLY
- **Used for:** Fetching unread emails
- **Never used for:** Sending, deleting, modifying emails

### Google Calendar API
- **Scope:** `calendar.readonly` - READ ONLY
- **Used for:** Reading meeting times (for meeting-prepper)
- **Never used for:** Creating, modifying, or deleting events

### Google Drive API
- **Scope:** `drive.readonly` - READ ONLY
- **Used for:** Reading Google Docs content
- **Never used for:** Creating, modifying, or deleting files

### Gemini API
- **Used for:** Processing and analyzing text
- **Never used for:** Creating external actions

---

## User Responsibilities

While the system is safe, users should:

1. **Review extracted information** - Check that summaries are accurate
2. **Verify action items** - Ensure extracted actions are correct before acting on them
3. **Control action_points.md** - Manually mark items as complete when appropriate
4. **Monitor memory files** - Periodically review what's stored in `~/.claude/memory/`
5. **Keep credentials safe** - Protect Google OAuth tokens and Slack tokens

---

## Slack Messaging Feature

### How It Works

The system CAN send meeting briefings directly to your Slack account:

1. **During setup**, you provide your Slack Member ID (e.g., `U01DHE5U6MA`)
2. **When a meeting briefing is generated**, it's automatically sent to your Slack DM
3. **Only you receive it** - Messages go exclusively to your private Slack account
4. **No other users are involved** - The system never posts to channels or mentions other users

### Important Boundaries

- ✅ **CAN:** Send briefings to YOUR Slack DM
- ❌ **CANNOT:** Send to other users
- ❌ **CANNOT:** Post to public channels
- ❌ **CANNOT:** Mention other people
- ❌ **CANNOT:** Create reminders or workflows on behalf of user
- ❌ **CANNOT:** Interact with Slack beyond sending you DMs

### Disabling Slack Messages

If you don't want Slack messages:

1. Don't provide your Slack ID during setup (skip Phase 4)
2. Briefings will still appear in Claude Code chat
3. Can enable later by reconfiguring

### Why This Is Safe

- ✅ Only you receive messages (not others)
- ✅ No external posting or mentions
- ✅ No automation on other users' behalf
- ✅ You control the Slack token (can revoke anytime)
- ✅ User ID provided explicitly during setup

---

## How to Verify

To verify the system is safe:

1. **Check the code**
   ```bash
   grep -i "send\|delete\|post\|slack.*message\|email.*send" \
     ~/.claude/scripts/email_memory_processor.py \
     ~/.claude/scripts/email_memory_gemini_notes.py
   ```
   (Will find only references to "sender" from emails, never "send" as an action)

2. **Check memory files**
   ```bash
   ls -la ~/.claude/memory/
   ```
   All files are local, no external sync

3. **Review logs**
   - Check console output when scripts run
   - See exactly what operations were performed

4. **Audit credentials**
   ```bash
   # No credentials stored in plain text
   # All tokens in secure keychain/secret service
   security dump-keychain | grep claude  # macOS
   ```

---

## Incident Response

If you suspect the system is performing unwanted actions:

1. **Stop the cron job**
   ```bash
   crontab -e
   # Comment out the email automation lines
   ```

2. **Review logs**
   ```bash
   cat ~/.claude/logs/email_memory_*.log
   ```

3. **Check memory files**
   ```bash
   ls -la ~/.claude/memory/
   ```

4. **Revoke credentials**
   ```bash
   # Google: https://myaccount.google.com/permissions
   # Slack: https://api.slack.com/apps
   ```

---

## Summary

✅ **Safe by design** - System only reads and stores data locally
✅ **User controlled** - All actions require explicit user decision
✅ **Transparent** - All operations visible in logs and files
✅ **Non-invasive** - No changes to external systems

This is a **data aggregation and storage system**, not an automation system that takes actions on your behalf.
