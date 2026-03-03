# Business Rules - Meeting Memory System

**Overview:** Complete set of business rules governing the behavior of the Meeting Memory system with Himalaya (email) and Plann (calendar) integration.

---

## 1. Setup & Installation Rules

### 1.1 Himalaya Configuration (MANDATORY)
- ✅ **Always offered** during setup (Phase 3)
- ✅ **Required** for the system to function with email context
- ✅ **Supported providers:** Gmail, ProtonMail, Fastmail, Outlook, any IMAP server
- ✅ **Configuration:** Interactive `himalaya account configure`
- ✅ **Storage:** Credentials stored in `~/.config/himalaya/config.toml` (Himalaya manages this)
- ❌ **Setup cannot continue if:** Himalaya installation fails AND user chooses to skip

### 1.2 Plann Configuration (OPTIONAL)
- ✅ **Always offered** during setup (Phase 3.5) - BUT user can skip
- ✅ **Optional** - system works without it using email alone
- ✅ **Supported providers:** Nextcloud, Radicale, FastMail, any CalDAV server
- ✅ **Configuration:** Interactive `plann account configure`
- ✅ **Storage:** Credentials stored in `~/.config/` (Plann manages this)
- ✅ **If configured successfully → Cron job automatically installed**
- ✅ **If skipped → No cron job, system uses email-only mode**

### 1.3 Cron Installation Rule
- **RULE:** Cron job installed **IF AND ONLY IF** Plann validates successfully
- **Schedule:** `*/10 * * * *` (every 10 minutes)
- **Script:** `~/.claude/scripts/calendar_watcher.sh`
- **User Control:** Can be removed/modified via `crontab -e` anytime
- **Persistence:** Stays until user removes it

---

## 2. Calendar Watcher Rules (Runs Every 10 Minutes)

### 2.1 Execution Prerequisites
- **Rule 1:** Only run if Plann CLI is installed (`command -v plann`)
- **Rule 2:** Only run if Plann has calendars configured (`plann calendar list` succeeds)
- **Rule 3:** If either fails → log warning and exit gracefully (return 0, not error)

### 2.2 Meeting Detection Window
- **Rule:** Check for meetings in **next 30 minutes** from current time
- **Time calculation:**
  - Start: Current UTC time
  - End: Current UTC time + 30 minutes
- **Timezone:** Always UTC for consistency

### 2.3 Cache Management
- **Rule 1:** Save calendar results to: `~/.claude/memory/.cache/upcoming_meetings.json`
- **Rule 2:** Format must be valid JSON
- **Rule 3:** Update cache every 10 minutes (even if no new meetings)
- **Rule 4:** Keep processed meetings list in: `~/.claude/memory/.cache/processed_meetings.txt`

### 2.4 Deduplication Rules
- **Rule 1:** Track each processed meeting by title
- **Rule 2:** Same meeting title should NOT generate multiple notifications
- **Rule 3:** Use `processed_meetings.txt` to check if already processed
- **Rule 4:** Add meeting to processed file ONLY after successful notification
- **Rule 5:** Cleanup: Keep only last 100 entries in processed file (prevent unbounded growth)

### 2.5 Slack Notification Rules (Optional)
- **Rule 1:** Only send if `SLACK_BOT_TOKEN` is configured
- **Rule 2:** Only send for **NEW** meetings (not in processed_meetings.txt)
- **Rule 3:** Do NOT fail if Slack notification fails (log warning, continue)
- **Rule 4:** Format: "📅 Upcoming meeting in 30 minutes: [Meeting Title]"
- **Rule 5:** Send to user ID in `SLACK_DM_USER_ID` environment variable

### 2.6 Logging Rules
- **Rule 1:** Log all activity to: `~/.claude/logs/calendar_watcher.log`
- **Rule 2:** Include timestamp in format: `[YYYY-MM-DD HH:MM:SS]`
- **Rule 3:** Log levels: INFO, WARN, ERROR
- **Rule 4:** Always log: start, calendar check, cache update, meetings detected, notifications sent
- **Rule 5:** Keep logs for debugging (no cleanup)

### 2.7 Error Handling Rules
- **Rule 1:** If Plann not installed → log warning, return 0 (success)
- **Rule 2:** If Plann not configured → log warning, return 0 (success)
- **Rule 3:** If date calculation fails → use fallback (try Linux format, then macOS format)
- **Rule 4:** If JSON parsing fails → log warning, skip deduplication check
- **Rule 5:** NEVER exit with error code (always return 0 for cron stability)

---

## 3. Pre-Meeting Skill Rules

### 3.1 Trigger Rules
- **Rule 1:** Trigger on phrases: "meeting briefing", "meeting prepper", "prepare me for", "what do I need to know"
- **Rule 2:** Also trigger if user provides meeting title + asks for summary
- **Rule 3:** Trigger is case-insensitive

### 3.2 Meeting Data Collection Rules
- **Rule 1:** Title is **MANDATORY** - ask user if not provided
- **Rule 2:** Participants are **OPTIONAL** - use email if not provided
- **Rule 3:** Description is **OPTIONAL** - proceed if not provided
- **Rule 4:** If user provides minimal data, still proceed with whatever they give

### 3.3 Email Search Rules (Himalaya)
- **Rule 1:** Search max 50 emails: `himalaya envelope list --limit 50`
- **Rule 2:** Filter by **meeting title** OR **participant names** (case-insensitive)
- **Rule 3:** Include email if title OR any participant name found in subject OR sender
- **Rule 4:** Limit to maximum **10 emails** for context (to stay within token limits)
- **Rule 5:** Extract: From, Subject, Date, body preview (first 500 chars)
- **Rule 6:** If Himalaya not installed → log warning, proceed with memory-only briefing

### 3.4 Memory File Reading Rules
- **Rule 1:** ALWAYS read: `action_points.md`
- **Rule 2:** ALWAYS read: `memory/YYYY-MM-DD.md` (today's date)
- **Rule 3:** ALWAYS read: `memoria_agente/*.md` (all files)
- **Rule 4:** ALWAYS read: `MEMORY.md`
- **Rule 5:** If any file missing → continue with available files (don't fail)
- **Rule 6:** If directory empty → note "(empty)" in briefing

### 3.5 Pending Items Filtering Rules
- **Rule 1:** Include ONLY items not marked with `[x]` (completed)
- **Rule 2:** Filter by **relevance** to meeting title or participants
- **Rule 3:** Match participant names case-insensitively
- **Rule 4:** If no relevant items → show "No active pending items" (ALWAYS include section)
- **Rule 5:** NEVER skip the "Active Pending Items" section

### 3.6 Briefing Format Rules
- **Rule 1:** Format is ALWAYS:
  ```
  🔥 ACTIVE PENDING ITEMS:
  (list items relevant to this meeting or "No active pending items")

  📚 HISTORICAL CONTEXT:
  (summary of what's useful for this meeting)

  📧 EMAIL CONTEXT:
  (summary of email topics or "No related emails found")
  ```
- **Rule 2:** ALWAYS output in English (even if user prompted in Portuguese)
- **Rule 3:** Be concise and direct (avoid verbose text)
- **Rule 4:** Historical context: only what's relevant, no generic content

### 3.7 Error/Fallback Rules
- **Rule 1:** If Himalaya not configured → warn user, proceed with memory-only briefing
- **Rule 2:** If no emails found → continue with memory context (no error)
- **Rule 3:** If memory files missing → show available context (no error)
- **Rule 4:** If participant not found in emails → OK, use memory and action_points
- **Rule 5:** ALWAYS deliver a briefing (even if partial)

### 3.8 Delivery Rules
- **Rule 1:** Show briefing in chat (no email, no Slack)
- **Rule 2:** Briefing is read-only (user can copy/paste elsewhere)
- **Rule 3:** Include metadata: meeting title, participants, timestamp

---

## 4. System-Wide Rules

### 4.1 Email Context Priority
- **Rule 1:** Emails are **supplementary** (not required for briefing)
- **Rule 2:** Emails should enhance context (not replace memory system)
- **Rule 3:** If no emails found → briefing still works perfectly
- **Rule 4:** Email relevance > recency (relevant old emails > irrelevant recent ones)

### 4.2 Memory System Priority
- **Rule 1:** Memory files are **primary source** of context
- **Rule 2:** action_points.md is **source of truth** for pending items
- **Rule 3:** MEMORY.md provides **executive context**
- **Rule 4:** memoria_agente/*.md provides **person/project context**

### 4.3 Calendar System (Plann) Rules
- **Rule 1:** Calendar is **optional** - system works without it
- **Rule 2:** If calendar configured → cron monitors every 10 minutes
- **Rule 3:** Calendar window is always 30 minutes ahead
- **Rule 4:** Calendar is used for **automatic detection** (user doesn't ask)
- **Rule 5:** Pre-meeting skill doesn't depend on calendar (email + memory sufficient)

### 4.4 Slack Integration Rules
- **Rule 1:** Slack is **optional** - not required for system to function
- **Rule 2:** Only calendar watcher sends Slack messages (not pre-meeting skill)
- **Rule 3:** Slack messages are **informational only** (briefing in chat, not Slack)
- **Rule 4:** If SLACK_BOT_TOKEN not configured → skip notifications (no error)

### 4.5 Credential Storage Rules
- **Rule 1:** Himalaya stores credentials: `~/.config/himalaya/config.toml`
- **Rule 2:** Plann stores credentials: `~/.config/` (Plann manages location)
- **Rule 3:** **NO credentials in setup.sh** - never hardcoded
- **Rule 4:** **NO credentials in logs** - always masked
- **Rule 5:** Setup.sh only asks for credentials, never stores them

### 4.6 File Organization Rules
- **Cache files:** `~/.claude/memory/.cache/`
  - `upcoming_meetings.json` - calendar cache
  - `processed_meetings.txt` - deduplication list
- **Memory files:** `~/.claude/memory/`
  - `action_points.md` - pending items
  - `MEMORY.md` - executive summary
  - `memory/YYYY-MM-DD.md` - daily notes
  - `memoria_agente/*.md` - context (people, projects)
- **Logs:** `~/.claude/logs/`
  - `calendar_watcher.log` - calendar monitoring
- **Scripts:** `~/.claude/scripts/`
  - `calendar_watcher.sh` - cron job

### 4.7 Graceful Degradation Rules
- **Rule 1:** System should **never fail** due to missing optional components
- **Rule 2:** If Himalaya unavailable → use memory only
- **Rule 3:** If Plann unavailable → no calendar monitoring, email-only mode
- **Rule 4:** If Slack unavailable → skip notifications, continue working
- **Rule 5:** If memory files missing → show what's available
- **Rule 6:** ALWAYS show some briefing (even if partial/degraded)

---

## 5. Performance Rules

### 5.1 Response Time Rules
- **Rule 1:** Email search should complete in < 5 seconds
- **Rule 2:** Memory file reading should complete in < 2 seconds
- **Rule 3:** Briefing generation via Claude should complete in < 10 seconds
- **Rule 4:** Total briefing delivery should be < 15 seconds

### 5.2 Resource Usage Rules
- **Rule 1:** Cache files kept minimal (< 10 KB)
- **Rule 2:** Processed meetings list kept to 100 entries (< 2 KB)
- **Rule 3:** Logs rotated or cleaned periodically (not required by rules)
- **Rule 4:** Cron job should use < 5% CPU per run
- **Rule 5:** Memory usage peak < 50 MB per operation

### 5.3 Cron Frequency Rules
- **Rule 1:** Calendar watcher runs every **10 minutes** (not more frequent)
- **Rule 2:** Cron job must complete within **5 minutes** of start (otherwise skip)
- **Rule 3:** Can be adjusted by user (e.g., `*/5` for 5 min, `*/30` for 30 min)

---

## 6. User Control Rules

### 6.1 Configuration Management
- **Rule 1:** User can remove cron job: `crontab -e` → remove "Calendar Watcher" lines
- **Rule 2:** User can modify cron frequency: change `*/10` to desired interval
- **Rule 3:** User can disable cron: comment out line with `#`
- **Rule 4:** User can view logs: `tail -f ~/.claude/logs/calendar_watcher.log`
- **Rule 5:** User can reconfigure Himalaya: `himalaya account configure`
- **Rule 6:** User can reconfigure Plann: `plann account configure`

### 6.2 Data Deletion Rules
- **Rule 1:** User can delete cache: `rm ~/.claude/memory/.cache/upcoming_meetings.json`
- **Rule 2:** User can reset processed meetings: `rm ~/.claude/memory/.cache/processed_meetings.txt`
- **Rule 3:** User can delete logs: `rm ~/.claude/logs/calendar_watcher.log`
- **Rule 4:** Deleting cache/logs doesn't break functionality (just resets state)

---

## 7. Privacy & Security Rules

### 7.1 Credential Rules
- **Rule 1:** Email/calendar passwords NEVER logged
- **Rule 2:** Email/calendar credentials NEVER stored in setup.sh
- **Rule 3:** API keys NEVER hardcoded in scripts
- **Rule 4:** Slack tokens only used for notifications (read from environment)

### 7.2 Data Retention Rules
- **Rule 1:** Emails NOT stored locally (only cached filenames/subjects)
- **Rule 2:** Calendar events NOT stored permanently (only in cache)
- **Rule 3:** Memory files owned by user (under ~/.claude/memory/)
- **Rule 4:** Logs contain only non-sensitive metadata (timestamps, counts)

### 7.3 Access Rules
- **Rule 1:** Only current user can access: ~/.claude/ directory
- **Rule 2:** Cron job runs as current user (no elevated privileges)
- **Rule 3:** Himalaya/Plann CLIs use user-configured credentials

---

## 8. Exception Handling Rules

### 8.1 Himalaya Exceptions
- **Rule 1:** `himalaya envelope list` fails → log warning, continue
- **Rule 2:** `himalaya read` fails for specific email → skip that email, continue
- **Rule 3:** Email parsing fails → log warning, skip email
- **Rule 4:** IMAP connection timeout → log warning, continue with memory-only

### 8.2 Plann Exceptions
- **Rule 1:** `plann calendar list` fails → log warning, return 0 (not error)
- **Rule 2:** `plann list` fails → log warning, use empty cache
- **Rule 3:** Calendar date parsing fails → log warning, retry with fallback format
- **Rule 4:** CalDAV connection timeout → log warning, return 0 (not error)

### 8.3 Slack Exceptions
- **Rule 1:** Slack API returns error → log warning, don't fail cron
- **Rule 2:** User ID invalid → log warning, continue
- **Rule 3:** Network timeout → log warning, return 0 (not error)

### 8.4 JSON Parsing Exceptions
- **Rule 1:** `jq` not installed → skip deduplication, log info
- **Rule 2:** Invalid JSON from Plann → log warning, use empty array
- **Rule 3:** JSON has unexpected format → log warning, handle gracefully

---

## 9. Data Integrity Rules

### 9.1 Cache File Rules
- **Rule 1:** `upcoming_meetings.json` must always be valid JSON
- **Rule 2:** If writing fails → log error, don't update cache
- **Rule 3:** If file corrupted → delete and recreate on next run
- **Rule 4:** Atomic writes preferred (write to temp, move to target)

### 9.2 Processed Meetings File Rules
- **Rule 1:** One meeting title per line
- **Rule 2:** Duplicates should not occur (check before appending)
- **Rule 3:** If file corrupted → log warning, continue without dedup
- **Rule 4:** If file grows too large → trim to last 100 entries

### 9.3 Log File Rules
- **Rule 1:** Append-only (never overwrite)
- **Rule 2:** Include timestamp for every entry
- **Rule 3:** Maintain consistent format: `[TIMESTAMP] [LEVEL] MESSAGE`

---

## 10. Documentation Rules

### 10.1 Setup Documentation
- **Rule 1:** Setup guide must explain both Himalaya and Plann
- **Rule 2:** Must note that Plann is optional, Himalaya is required
- **Rule 3:** Must explain cron setup when Plann configured

### 10.2 Troubleshooting Documentation
- **Rule 1:** Must document how to check cron: `crontab -l`
- **Rule 2:** Must document how to view logs: `tail -f ~/.claude/logs/calendar_watcher.log`
- **Rule 3:** Must document how to remove cron: `crontab -e`
- **Rule 4:** Must explain graceful degradation (works without Plann)

### 10.3 API Documentation
- **Rule 1:** Himalaya: document `envelope list --limit 50` usage
- **Rule 2:** Plann: document `calendar list` and `list --from X --to Y` usage
- **Rule 3:** Document expected output formats
- **Rule 4:** Document error codes and recovery strategies

---

## Summary

These rules ensure:

✅ **Robustness** - System gracefully handles failures
✅ **Simplicity** - Clear, unambiguous behavior
✅ **User Control** - Easy to manage/modify/remove
✅ **Privacy** - No credentials stored or logged
✅ **Flexibility** - Works with/without calendar
✅ **Observability** - Complete logging for debugging
✅ **Consistency** - Predictable behavior across all scenarios

