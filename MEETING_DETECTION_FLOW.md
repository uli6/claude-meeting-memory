# Meeting Detection Flow - Himalaya + Plann Integration

**Overview:** How the system detects upcoming meetings and generates briefings using Himalaya (email) and Plann (calendar).

---

## Architecture

### Three Information Sources

```
┌─────────────────────┬──────────────────┬────────────────────┐
│   Himalaya (IMAP)   │  Plann (CalDAV)  │  Memory System      │
├─────────────────────┼──────────────────┼────────────────────┤
│ • Recent emails     │ • Calendar events│ • Action points    │
│ • Email threads     │ • Meeting times  │ • Historical notes │
│ • Participants      │ • Meeting titles │ • Project context  │
│ • Email context     │ • Attendees      │ • People profiles  │
└─────────────────────┴──────────────────┴────────────────────┘
```

---

## Two Operating Modes

### Mode 1: Automatic Calendar Monitoring (Optional)

**Enabled when:** Plann is configured during setup

**Process:**
```
Every 10 minutes (cron: */10 * * * *)
    ↓
Calendar Watcher Script (calendar_watcher.sh)
    ├─ Query Plann for meetings in next 30 minutes
    ├─ Cache results to: ~/.claude/memory/.cache/upcoming_meetings.json
    ├─ Track processed meetings (avoid duplicates)
    └─ Optional: Send Slack notification about new meetings
```

**User Experience:**
- Automatic: User doesn't need to do anything
- Slack DM: "📅 Upcoming meeting in 30 minutes: Sales Review"
- No interruption: Runs silently in background

**Files:**
- Script: `~/.claude/scripts/calendar_watcher.sh`
- Cache: `~/.claude/memory/.cache/upcoming_meetings.json`
- Log: `~/.claude/logs/calendar_watcher.log`

---

### Mode 2: On-Demand Meeting Briefing (Always Available)

**Triggered when:** User asks `/pre-meeting "Meeting title"` or "What do I need to know for Sales Review?"

**Process:**
```
User: "Meeting briefing for Sales Review"
    ↓
/pre-meeting Skill
    ├─ Prompt for meeting details (if not provided)
    │   ├─ Title: "Sales Review"
    │   ├─ Participants: "John, Maria, Alex"
    │   └─ Description: (optional)
    │
    ├─ Search Himalaya emails
    │   ├─ Query: himalaya envelope list --limit 50
    │   ├─ Filter by: meeting title + participant names
    │   └─ Extract: From, Subject, Date, body preview
    │
    ├─ Read Memory System
    │   ├─ action_points.md (pending items)
    │   ├─ MEMORY.md (executive summary)
    │   ├─ memoria_agente/*.md (people, projects, context)
    │   └─ memory/YYYY-MM-DD.md (daily notes)
    │
    ├─ Generate Briefing via Claude API
    │   ├─ System prompt: Read memory files
    │   ├─ User prompt: Meeting details + email context
    │   └─ Format: Pending Items + Historical Context + Email Context
    │
    └─ Display Briefing
        🔥 ACTIVE PENDING ITEMS: [3 items for John/Maria]
        📚 HISTORICAL CONTEXT: [Sales trends, budget decisions]
        📧 EMAIL CONTEXT: [Discussed pricing, timeline concerns]
```

**User Experience:**
- On-demand: User asks whenever needed
- Rich context: Combines calendar/email/memory
- Quick turnaround: Generated in ~5-10 seconds

---

## Data Flow Diagram

### When Both Himalaya AND Plann Configured

```
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Meeting Memory                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Plann Calendar (CalDAV)                                        │
│  ├─ Every 10 min: Calendar Watcher checks calendar              │
│  └─ Caches upcoming meetings → ~/.claude/memory/.cache/         │
│                                                                 │
│  Himalaya Email (IMAP)                                          │
│  ├─ On-demand: /pre-meeting reads recent emails                 │
│  └─ Filters by title + participants                             │
│                                                                 │
│  Memory System                                                  │
│  ├─ action_points.md - pending items                            │
│  ├─ MEMORY.md - executive summary                               │
│  ├─ memoria_agente/ - context (people, projects)                │
│  └─ memory/YYYY-MM-DD.md - daily notes                          │
│                                                                 │
│  Pre-Meeting Skill                                              │
│  ├─ Triggered: User requests briefing                           │
│  ├─ Gathers: Email context + Memory data                        │
│  ├─ Generates: Briefing via Claude API                          │
│  └─ Delivers: Formatted briefing to user                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### When Only Himalaya Configured

```
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Meeting Memory                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Himalaya Email (IMAP) ✓ Configured                             │
│  ├─ On-demand: /pre-meeting reads recent emails                 │
│  └─ Filters by title + participants                             │
│                                                                 │
│  Plann Calendar (CalDAV) ✗ Skipped                              │
│  └─ (No automatic monitoring)                                   │
│                                                                 │
│  Memory System                                                  │
│  ├─ action_points.md - pending items                            │
│  ├─ MEMORY.md - executive summary                               │
│  ├─ memoria_agente/ - context (people, projects)                │
│  └─ memory/YYYY-MM-DD.md - daily notes                          │
│                                                                 │
│  Pre-Meeting Skill                                              │
│  ├─ Triggered: User requests briefing                           │
│  ├─ Gathers: Email context + Memory data (NO calendar)          │
│  ├─ Generates: Briefing via Claude API                          │
│  └─ Delivers: Formatted briefing to user                        │
│                                                                 │
│  Note: Still works perfectly! Calendar is optional.             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Meeting Detection Algorithm

### Email-Based Detection (Himalaya)

```python
# When user says: "Meeting briefing for Sales Review with John and Maria"

query_terms = ["Sales Review", "John", "Maria"]

for email in himalaya.envelope_list(limit=50):
    if any(term in email.subject.lower() or
           term in email.from.lower()
           for term in query_terms):
        # Include this email in briefing context
        relevant_emails.append(email)
        if len(relevant_emails) >= 10:
            break  # Limit to 10 emails
```

### Calendar-Based Detection (Plann)

```bash
# Every 10 minutes
now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
thirty_min=$(date -u -d '+30 minutes' '+%Y-%m-%dT%H:%M:%SZ')

plann list --from "$now" --to "$thirty_min"
# Returns: meetings in next 30 minutes

# Cache results
echo "$meetings_json" > ~/.claude/memory/.cache/upcoming_meetings.json

# Check for new meetings not yet processed
for meeting in $meetings:
    if meeting.id not in processed_meetings.txt:
        # New meeting detected!
        process_meeting(meeting)
        send_slack_notification(meeting)
        add_to_processed_meetings(meeting)
```

---

## Caching & Deduplication

### Processed Meetings File

**Location:** `~/.claude/memory/.cache/processed_meetings.txt`

**Purpose:** Avoid processing the same meeting multiple times

**Format:**
```
Meeting Title 1
Meeting Title 2
Meeting Title 3
...
```

**Cleanup:** Keeps only last 100 entries (prevents unbounded growth)

### Calendar Cache

**Location:** `~/.claude/memory/.cache/upcoming_meetings.json`

**Format:**
```json
[
  {
    "id": "meeting-123",
    "title": "Sales Review",
    "start": "2026-03-03T14:30:00Z",
    "end": "2026-03-03T15:00:00Z",
    "participants": ["john@example.com", "maria@example.com"]
  },
  ...
]
```

**Updated:** Every 10 minutes by calendar watcher

---

## Logging & Debugging

### Calendar Watcher Logs

**Location:** `~/.claude/logs/calendar_watcher.log`

**View logs:**
```bash
tail -f ~/.claude/logs/calendar_watcher.log
```

**Sample output:**
```
[2026-03-03 14:20:15] [INFO] Calendar watcher started
[2026-03-03 14:20:16] [INFO] Checking for meetings between 2026-03-03T14:20:16Z and 2026-03-03T14:50:16Z
[2026-03-03 14:20:17] [INFO] Calendar cache updated: /Users/user/.claude/memory/.cache/upcoming_meetings.json
[2026-03-03 14:20:17] [INFO] New meeting detected: Sales Review
[2026-03-03 14:20:18] [INFO] Slack notification sent for meeting: Sales Review
[2026-03-03 14:20:18] [INFO] Calendar watcher completed successfully
```

---

## Managing Cron Jobs

### View your crontab

```bash
crontab -l
```

**Expected output:**
```
# Calendar Watcher - Meeting Detection (Claude Meeting Memory)
*/10 * * * * /Users/user/.claude/scripts/calendar_watcher.sh >> /dev/null 2>&1
```

### Edit/Remove cron jobs

```bash
crontab -e
```

Then:
- **To remove:** Delete the two lines marked with "Calendar Watcher"
- **To modify:** Change `*/10` to different interval (e.g., `*/5` for 5 min, `*/30` for 30 min)
- **To disable:** Comment out the line with `#`

### Verify cron is running

```bash
# Check if process ran recently
tail -20 ~/.claude/logs/calendar_watcher.log

# Check cron system logs (macOS)
log stream --predicate 'process == "cron"' --level debug
```

---

## Troubleshooting

### Cron job not running

1. **Verify cron installed:**
   ```bash
   crontab -l
   # Should show the calendar watcher entry
   ```

2. **Check script permissions:**
   ```bash
   ls -la ~/.claude/scripts/calendar_watcher.sh
   # Should show: -rwxr-xr-x (executable)
   ```

3. **Check logs:**
   ```bash
   tail -50 ~/.claude/logs/calendar_watcher.log
   # Look for errors
   ```

4. **Test script manually:**
   ```bash
   bash ~/.claude/scripts/calendar_watcher.sh
   # Should complete without errors
   ```

### Meetings not detected

1. **Verify Plann configured:**
   ```bash
   plann calendar list
   # Should show your calendars
   ```

2. **Verify calendar readable:**
   ```bash
   plann list --from "2026-03-03T14:00:00Z" --to "2026-03-03T15:00:00Z"
   # Should show upcoming meetings
   ```

3. **Check cache file:**
   ```bash
   cat ~/.claude/memory/.cache/upcoming_meetings.json | python -m json.tool
   # Should show valid JSON with meetings
   ```

### Emails not found in briefing

1. **Verify Himalaya configured:**
   ```bash
   himalaya envelope list --limit 5
   # Should show recent emails
   ```

2. **Search manually:**
   ```bash
   himalaya envelope list --limit 50 | grep -i "sales"
   # Should show matching emails
   ```

3. **Check email filtering logic:**
   - Meeting title must be in email subject or sender
   - Participant names must be in email subject or sender
   - Case-insensitive matching

---

## Performance Notes

### Cron Scheduling

- **Interval:** `*/10 * * * *` (every 10 minutes)
- **Rationale:**
  - Frequent enough to catch meetings within 30-min window
  - Infrequent enough to not overwhelm system
  - Can be adjusted (e.g., `*/5` for 5-min intervals)

### Cache Management

- **Calendar cache:** ~2-5 KB (small JSON file)
- **Processed meetings:** Trimmed to 100 entries (~1-2 KB)
- **Logs:** ~1-2 KB per day

### API Calls

- **Plann:** 1 call per 10 minutes (144 calls/day)
- **Slack:** 0 or 1 per detected meeting
- **Himalaya:** Only on-demand when `/pre-meeting` triggered

---

## Future Enhancements

Possible improvements (out of scope for current migration):

- [ ] Configurable cron interval
- [ ] Slack thread-based briefing (reply in meeting thread)
- [ ] Automatic pre-meeting briefing 5 minutes before meeting
- [ ] HTML email calendar invites parsing
- [ ] Meeting cost calculation (based on attendees)
- [ ] Timezone-aware scheduling
- [ ] Integration with Plann recurring events

---

## Summary

The system provides **two complementary approaches** to meeting detection:

1. **Automatic (Plann):** Background calendar monitoring every 10 minutes
2. **On-Demand (Himalaya):** User-triggered email-based briefing

**Key features:**
- ✅ Works with any IMAP provider (Gmail, ProtonMail, etc.)
- ✅ Works with any CalDAV provider (Nextcloud, Radicale, etc.)
- ✅ Email-only mode (if calendar skipped) still fully functional
- ✅ Automatic deduplication (same meeting not processed twice)
- ✅ Optional Slack notifications
- ✅ Comprehensive logging for debugging
- ✅ User can disable/modify cron anytime

**Result:** Rich, contextual meeting briefings combining emails, calendar, and memory system.
