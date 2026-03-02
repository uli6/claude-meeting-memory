# How to Use Claude Meeting Memory

Complete guide to using the three skills and automating your meeting briefings.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Skill 1: /read-this](#skill-1-read-this)
3. [Skill 2: /pre-meeting](#skill-2-pre-meeting)
4. [Skill 3: /remind-me](#skill-3-remind-me)
5. [Automation Setup](#automation-setup)
6. [Memory System](#memory-system)
7. [Daily Workflow](#daily-workflow)
8. [Tips & Tricks](#tips--tricks)

---

## Quick Start

After setup completes, you have three powerful skills available:

```bash
# Read Google Docs and add to memory
/read-this https://docs.google.com/document/d/DOC_ID/edit

# Generate a meeting briefing
/pre-meeting

# Create action points from Slack
/remind-me Check project deadline
```

Each skill integrates with your memory system to build context over time.

---

## Skill 1: /read-this

**Purpose:** Read Google Docs and automatically add summaries to your memory.

**What it does:**
- Reads the document content from Google Drive
- Generates a concise summary
- Adds to `~/.claude/memory/memoria_agente/` with metadata
- Indexes by date so you can find it later
- Links back to the original document

### How to Use

#### Basic Usage

```
/read-this https://docs.google.com/document/d/YOUR_DOC_ID/edit
```

You'll see:
```
📖 Reading document: "Project Proposal"...
✓ Document loaded (2,453 words)
✓ Summary generated
✓ Added to memory

📝 SUMMARY:
The project proposes a new dashboard feature that...

📂 Saved to: ~/.claude/memory/memoria_agente/2026-03-02_project_proposal.md
🔗 Original: https://docs.google.com/document/d/YOUR_DOC_ID/edit
```

#### Getting Document URLs

**From Google Docs:**
1. Open the document
2. Click "Share" or address bar
3. Copy the full URL: `https://docs.google.com/document/d/XXXXXXXXXXX/edit`

**From Google Drive:**
1. Right-click document
2. Click "Get link"
3. Use the URL provided

### What Gets Saved

Memory file includes:
- **Title** - Document name
- **Date** - When you read it
- **Summary** - Key points (auto-generated)
- **Full Content** - Searchable text
- **Source Link** - Back to original
- **Tags** - Auto-categorized by content

Example saved file: `~/.claude/memoria_agente/2026-03-02_project_proposal.md`

### Use Cases

**1. Read Meeting Notes**
```
/read-this https://docs.google.com/document/d/123ABC/edit?usp=sharing
```
Saves meeting decisions, action items, and context for future reference.

**2. Read Strategy Documents**
```
/read-this https://docs.google.com/document/d/456DEF/edit
```
Adds company strategy, product roadmap, or team OKRs to your memory.

**3. Read Meeting Agendas** (Before the meeting)
```
/read-this https://docs.google.com/document/d/789GHI/edit
```
Prepares you with context before attending.

**4. Read Feedback or Performance Reviews**
```
/read-this https://docs.google.com/document/d/101JKL/edit
```
Saves feedback for reflection and future planning.

### Tips

- **Read regularly** - Frequent usage builds better context for briefings
- **Read before meetings** - Helps /pre-meeting generate better context
- **Tag important docs** - Manually edit saved files to add custom tags
- **Organize by date** - Files are sorted by date for easy browsing

### Troubleshooting

**"Document not found" or "Access denied"**
- Make sure you have access to the document in Google Drive
- Share it with the Google account used during setup
- Try re-authorizing: Run setup.sh again

**"Connection timeout"**
- Check your internet connection
- Google Drive might be slow - try again in a moment
- Verify setup.sh Google credentials are valid

---

## Skill 2: /pre-meeting

**Purpose:** Generate intelligent meeting briefings based on your calendar, action items, and memory.

**What it does:**
- Reads your next calendar events
- Gathers relevant action items
- Pulls context from your memory
- Generates executive briefing
- Optionally sends via Slack DM

### How to Use

#### Manual Briefing (On-Demand)

```
/pre-meeting
```

Example output:
```
📅 UPCOMING MEETINGS (Next 24 hours)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Team Standup - Today at 9:30 AM (15 min)
   Participants: John, Maria, You

2. Project Review - Today at 2:00 PM (1 hour)
   Participants: Sarah (PM), You, Engineering team

3. 1:1 with Manager - Today at 4:00 PM (30 min)
   Participants: Your Manager, You

🔥 ACTIVE ACTION ITEMS (Relevant to upcoming meetings)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [ ] Finish dashboard prototype (due today) - For Project Review
- [ ] Update quarterly metrics spreadsheet - For 1:1 with Manager
- [ ] Review team feedback from last retro - For Team Standup

📚 RELEVANT CONTEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

From memory (2026-03-02):
- Project Review is about finalizing the dashboard feature
- Last sprint had 3 bugs and 2 enhancements completed
- Manager mentioned career growth goals in last 1:1

Key documents:
- Project Proposal (read 3 days ago)
- Q1 OKRs (read 1 week ago)

💡 TIPS FOR MEETINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Project Review: Bring dashboard demo and metrics
2. 1:1 with Manager: Discuss Q2 goals (you read Q1 docs)
3. Standup: Mention blocker on dashboard (resolved yesterday)
```

#### Get Briefing for Specific Meeting

```
/pre-meeting "Project Review"
```

Returns briefing focused on that specific meeting only.

#### Automatic Briefings (Recommended)

See [Automation Setup](#automation-setup) below for crontab configuration.

### What It Analyzes

**Calendar Events:**
- Event title and time
- Duration
- Participants
- Event description (if provided)

**Action Items:**
- Checks `~/.claude/memory/action_points.md`
- Filters items relevant to participants
- Sorts by due date

**Memory Context:**
- Reads daily notes from `~/.claude/memory/memoria_agente/`
- Searches for relevant documents
- Includes recent learnings and decisions

**Your Profile:**
- Uses `memoria_agente/perfil_usuario.md`
- Personalizes briefing to your role and team

### Use Cases

**1. Before Every Meeting**
```
/pre-meeting
```
Get context and action items before each day.

**2. Quick Check (5 minutes before)**
```
/pre-meeting
```
Get instant reminder of what to discuss.

**3. Weekly Planning**
```
/pre-meeting
```
Monday morning - see full week's meetings with context.

**4. After Unexpected Calendar**
```
/pre-meeting "New Meeting Name"
```
Someone added a meeting last minute? Get instant context.

### Tips

- **Use daily** - Morning briefing habit builds momentum
- **Fill your profile** - Better context = better briefings
- **Read documents** - Use /read-this to add context
- **Keep action items updated** - Use /remind-me to track items
- **Enable automation** - Crontab sends briefings automatically (see below)

### Automatic Briefing (Crontab)

See detailed setup in [Automation Setup](#automation-setup).

---

## Skill 3: /remind-me

**Purpose:** Create and track action items directly from Slack or manual input.

**What it does:**
- Converts Slack messages to action items
- Extracts context and participants
- Adds to `~/.claude/memory/action_points.md`
- Includes metadata (date, owner, due date)
- Searchable for future reference

### How to Use

#### Create from Text (Direct Input)

```
/remind-me Review quarterly metrics before meeting
```

Adds to action_points.md:
```
- [ ] Review quarterly metrics before meeting
  - Created: 2026-03-02
  - Context: Direct input
```

#### Create from Slack Message (Recommended)

Find a Slack message you want to track:

```
1. Right-click the message
2. Click "Copy link"
3. Use the command:

/remind-me https://slack.com/archives/C01ABC/p1234567890123

# Or with additional context:
/remind-me https://slack.com/archives/C01ABC/p1234567890123 "Due: Friday EOD"
```

Creates action item with:
- Message text
- Author (extracted from Slack)
- Channel context
- Timestamp
- Your added due date

#### Create with Owner and Due Date

```
/remind-me Check project deadline @john Friday
```

Adds:
- [ ] Check project deadline
  - Owner: @john
  - Due: Friday
  - Created: Today

#### Create with Priority

```
/remind-me URGENT: Fix production bug
```

Adds to top of list with priority indicator.

### Example Workflow

**Scenario:** In a Slack message, your manager says "Don't forget to update the dashboard metrics"

```
1. Right-click the message
2. Click "Copy link"
3. Run: /remind-me [link]

# Result in action_points.md:
- [ ] Update the dashboard metrics
  - Owner: @manager_name
  - Source: Slack message from #general
  - Date: 2026-03-02
  - Link: https://slack.com/archives/C01ABC/p1234567890123
```

Later, in /pre-meeting, this shows up as a pending action item.

### Viewing Action Items

Action items are stored in: `~/.claude/memory/action_points.md`

Open anytime:
```bash
cat ~/.claude/memory/action_points.md
# or
nano ~/.claude/memory/action_points.md
```

Format:
```markdown
# Action Points

## Active Items

- [ ] Item 1 - Description
  - Owner: @someone
  - Due: YYYY-MM-DD
  - Context: Link or notes

## Completed

- [x] Completed item
  - Completed: YYYY-MM-DD

## Waiting For

- ⏳ Waiting item - blocked on external input
  - Waiting for: @person
  - Expected: YYYY-MM-DD
```

### Managing Items

**Mark as Complete:**
Edit `action_points.md` and change `[ ]` to `[x]`

**Update Due Date:**
Edit the date field manually

**Move to Waiting:**
Change to `⏳` and move to "Waiting For" section

**Archive Old Items:**
Move completed items to "Completed" section (keep for reference)

### Use Cases

**1. During Meetings**
```
/remind-me https://slack.com/archives/C01ABC/p1234567890123
```
When someone assigns you something, track it immediately.

**2. From Email (Converted to Slack)**
Forward important emails to Slack, then:
```
/remind-me [slack_link]
```

**3. Recurring Items**
```
/remind-me Review sprint metrics every Friday
```

**4. Delegated Items**
```
/remind-me @john_doe Deploy new feature @maria_sm Friday EOD
```
Track what you assigned to others.

**5. Personal Goals**
```
/remind-me Complete Python course modules 5-7
```

### Tips

- **Use Slack links** - Preserves context and thread history
- **Be specific** - Include what, who, and when
- **Check daily** - In /pre-meeting briefings
- **Keep updated** - Mark items complete when done
- **Review weekly** - Update and reorganize each Friday

### Troubleshooting

**"Slack message not found"**
- Verify message link format: `https://slack.com/archives/CHANNEL/pTIMESTAMP`
- Make sure you're member of that channel
- Can't access private channels you're not in

**"Link not recognized"**
- Right-click message in Slack
- Select "Copy link to message"
- Make sure full URL is included

---

## Automation Setup

### Automatic Meeting Briefings (Crontab)

Enable automatic briefings every 10 minutes. This script checks your calendar and sends you a Slack DM if there's a meeting in the next 30 minutes.

#### Step 1: Create Wrapper Script

Create `~/.claude/scripts/pre_meeting_cron.sh`:

```bash
#!/bin/bash

# Automatic meeting briefing script for crontab
# Checks calendar every 10 minutes and sends briefing 30 min before meetings

export HOME="/Users/YOUR_USERNAME"  # Replace with your username
export PATH="/usr/local/bin:/usr/bin:/bin"

CLAUDE_HOME="$HOME/.claude"
SLACK_MEMBER_ID="U01ABC123"  # Your Slack Member ID (from setup)

# Source credential helpers
source "$CLAUDE_HOME/scripts/get_secret.sh"

# Get next meeting (simplified - you'd use python/google api)
python3 << 'PYTHON_SCRIPT'
import os
import sys
from datetime import datetime, timedelta
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']

def get_next_event():
    """Get next calendar event in next 30 minutes"""

    try:
        # This would load credentials from keychain
        # For now, simplified implementation
        service = build('calendar', 'v3')

        now = datetime.utcnow().isoformat() + 'Z'
        end = (datetime.utcnow() + timedelta(minutes=30)).isoformat() + 'Z'

        events = service.events().list(
            calendarId='primary',
            timeMin=now,
            timeMax=end,
            singleEvents=True,
            orderBy='startTime'
        ).execute()

        items = events.get('items', [])
        if items:
            return items[0]

        return None
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return None

event = get_next_event()
if event:
    print(event['summary'])
    print(event.get('start', {}).get('dateTime', 'unknown'))

PYTHON_SCRIPT

```

#### Step 2: Modify Script (Recommended)

The above is simplified. For full automation, the script should:

1. Check calendar every 10 minutes
2. Identify meetings in next 30 minutes
3. Generate briefing using /pre-meeting logic
4. Send to your Slack Member ID via bot token

#### Step 3: Add to Crontab

Open crontab editor:
```bash
crontab -e
```

Add this line to check every 10 minutes:
```bash
*/10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

Create logs directory first:
```bash
mkdir -p ~/.claude/logs
```

#### Step 4: Test

```bash
# Run manually to test
bash ~/.claude/scripts/pre_meeting_cron.sh

# Check logs
tail -f ~/.claude/logs/pre_meeting_cron.log

# Verify crontab is set
crontab -l | grep pre_meeting
```

#### Step 5: Monitor

Check if briefings are being sent:
```bash
# View recent cron logs
tail -20 ~/.claude/logs/pre_meeting_cron.log

# Check Slack DMs for briefings
# You should see DMs 30 min before each meeting
```

### What the Automation Does

Every 10 minutes:
1. ✓ Check your Google Calendar
2. ✓ Find meetings in next 30 minutes
3. ✓ Generate briefing with:
   - Meeting details (time, participants)
   - Relevant action items
   - Context from your memory
4. ✓ Send as Slack DM to you
5. ✓ Log activity for debugging

### Disable Automation

Remove from crontab:
```bash
crontab -e
# Delete the line, save and exit

# Or disable temporarily:
# */10 * * * * ~/.claude/scripts/pre_meeting_cron.sh  # (comment out with #)
```

### Advanced: Custom Schedule

**Check every 5 minutes:**
```bash
*/5 * * * * ~/.claude/scripts/pre_meeting_cron.sh
```

**Check every 15 minutes:**
```bash
*/15 * * * * ~/.claude/scripts/pre_meeting_cron.sh
```

**Only during business hours (9am-6pm):**
```bash
*/10 9-17 * * 1-5 ~/.claude/scripts/pre_meeting_cron.sh
```

**Only weekdays:**
```bash
*/10 * * * 1-5 ~/.claude/scripts/pre_meeting_cron.sh
```

---

## Memory System

Your memory is stored in `~/.claude/memory/` and automatically used by all skills.

### Directory Structure

```
~/.claude/memory/
├── action_points.md              # Your action items
├── MEMORY.md                      # Daily notes template
└── memoria_agente/               # Detailed memory files
    ├── perfil_usuario.md         # Your profile (fill this!)
    ├── 2026-03-02_*.md           # Daily notes by date
    ├── 2026-02-28_project_*.md   # Documents you read
    └── ...
```

### Daily Notes

Edit `~/.claude/memory/MEMORY.md` daily:

```markdown
## 📝 Today (2026-03-02)

### Discussions
- Had standup about dashboard progress
- Discussed Q2 OKRs in 1:1

### Decisions
- Decided to move feature launch to next sprint
- Approved budget for new tools

### Next Priorities
- Complete dashboard prototype
- Finish Q2 planning document
```

Add new daily section when you want to capture notes.

### Profile Management

Edit `~/.claude/memory/memoria_agente/perfil_usuario.md`:

```markdown
# Your Profile

## Basic Info
- Role: Senior Engineer
- Team: Platform Engineering
- Manager: John Smith

## Recurring Meetings
- Standup: Daily 9:30am
- 1:1: Wednesdays 4pm
- Project Review: Mondays 2pm

## Current Projects
1. Dashboard Redesign - In Progress
2. Performance Optimization - Paused
```

**Why this matters:** /pre-meeting uses your profile to personalize briefings!

### Organization

**By date:** Auto-created when you use /read-this
```
~/.claude/memory/memoria_agente/2026-03-02_project_proposal.md
~/.claude/memory/memoria_agente/2026-03-01_meeting_notes.md
```

**By project:** Manually organize
```
~/.claude/memory/memoria_agente/dashboard_project/
├── requirements.md
├── design.md
└── progress.md
```

**By topic:** Create as needed
```
~/.claude/memory/memoria_agente/performance_tips.md
~/.claude/memory/memoria_agente/team_learnings.md
```

---

## Daily Workflow

### Morning (30 seconds)

1. **Get daily briefing:**
   ```
   /pre-meeting
   ```
   Review meetings, action items, and context

2. **Add today's notes:**
   ```
   nano ~/.claude/memory/MEMORY.md
   ```

### During Day (as needed)

1. **Track action items:**
   ```
   /remind-me https://slack.com/archives/C01ABC/p123...
   ```

2. **Read important docs:**
   ```
   /read-this https://docs.google.com/document/d/ABC/edit
   ```

### Evening (Optional)

1. **Review day:**
   ```
   nano ~/.claude/memory/MEMORY.md
   # Add what you learned, decided, and accomplished
   ```

2. **Check completed items:**
   ```
   cat ~/.claude/memory/action_points.md
   # Mark items as [x] when done
   ```

### Weekly (Friday)

1. **Weekly review:**
   ```
   nano ~/.claude/memory/MEMORY.md
   # Add weekly summary
   ```

2. **Organize memory:**
   ```
   ls ~/.claude/memory/memoria_agente/
   # Archive old files, create new projects
   ```

3. **Update profile:**
   ```
   nano ~/.claude/memory/memoria_agente/perfil_usuario.md
   # Update projects, goals, changes
   ```

---

## Tips & Tricks

### Maximize /read-this

**1. Read before important meetings:**
```
/read-this https://docs.google.com/document/d/ABC/edit
# Now /pre-meeting has context
```

**2. Read strategy documents:**
```
/read-this https://docs.google.com/document/d/OKRs/edit
/read-this https://docs.google.com/document/d/Roadmap/edit
```

**3. Organize by project:**
```bash
mkdir ~/.claude/memory/memoria_agente/my_project
# All project docs saved there
```

**4. Reference later:**
```bash
grep -r "dashboard" ~/.claude/memory/
# Find all mentions of "dashboard" in your memory
```

### Maximize /pre-meeting

**1. Prepare the day before:**
```
# Read related documents
/read-this https://docs.google.com/document/d/project/edit
# Next morning, /pre-meeting uses that context
```

**2. Fill your profile completely:**
- Add team members
- List recurring meetings
- Document your role
- Describe current projects

**3. Keep action items updated:**
- Add items immediately when assigned
- Check status daily via /pre-meeting
- Mark complete when done

**4. Create sub-briefings:**
```
/pre-meeting "Project Review"
# Get briefing for just that meeting
```

### Maximize /remind-me

**1. Use Slack links (preserves context):**
```
/remind-me https://slack.com/archives/C01ABC/p123
# vs. just text - Slack version is better
```

**2. Create owner tags:**
```
/remind-me @john_doe Complete feature review Friday
# Now you can see who's responsible
```

**3. Sort by due date:**
```bash
# Edit action_points.md to group by due date
# Active Items > Due Today
# Active Items > Due This Week
# Active Items > Due Later
```

**4. Link to documents:**
```
/remind-me Review dashboard metrics
# Edit action_points.md to add link:
# [Dashboard Metrics Doc](https://docs.google.com/...)
```

### Search Your Memory

Find information quickly:
```bash
# Search for specific topic
grep -i "dashboard" ~/.claude/memory/memoria_agente/*

# Find documents from specific date
ls ~/.claude/memory/memoria_agente/2026-03-*

# Find action items mentioning someone
grep -i "@john" ~/.claude/memory/action_points.md

# View recent daily notes
tail -20 ~/.claude/memory/MEMORY.md
```

### Backup Your Memory

Keep your memory safe:

```bash
# Manual backup to cloud (Google Drive example)
tar czf claude_memory_backup.tar.gz ~/.claude/memory/

# Then upload to Google Drive, Dropbox, etc.

# Or use cloud sync
ln -s ~/Dropbox/.claude_memory ~/.claude/memory

# Check backup status
du -sh ~/.claude/memory/
```

### Share Insights

Reference your memory in Slack:
```slack
When discussing Q2 goals:

Based on my notes from yesterday's meeting:
- We decided to focus on performance
- Budget is approved for new tools

Here's what I captured:
[Copy relevant section from ~/.claude/memory/MEMORY.md]
```

---

## Troubleshooting Usage

### Skills Not Working

**Check if setup was successful:**
```bash
bash ~/.claude/scripts/validate.sh
```

**Verify credentials:**
```bash
# Check if Google token exists
security find-generic-password -a $USER -s "claude-code-google-refresh-token" 2>/dev/null

# Check if Slack token exists
security find-generic-password -a $USER -s "claude-code-slack-user-token" 2>/dev/null
```

### /read-this Issues

**"Document not accessible"**
- Share doc with your Google account
- Use full document URL
- Check you have view permission

**"No documents saved"**
- Check directory exists: `ls ~/.claude/memory/memoria_agente/`
- Check file permissions: `chmod 700 ~/.claude/memory/memoria_agente/`

### /pre-meeting Issues

**"No meetings found"**
- Check your Google Calendar in browser
- Verify events show up there first
- Check Google OAuth setup

**"Missing action items"**
- Verify `action_points.md` exists: `ls ~/.claude/memory/action_points.md`
- Add items using `/remind-me`

### /remind-me Issues

**"Can't parse Slack link"**
- Use right-click → "Copy link" in Slack
- Format should be: `https://slack.com/archives/C.../p...`
- Not a channel bookmark, but message link

**"Action point not saving"**
- Check write permissions: `chmod 700 ~/.claude/memory/`
- Check disk space: `df -h`
- Try manual edit of `action_points.md`

### Automation Not Running

**Check crontab is set:**
```bash
crontab -l | grep pre_meeting
```

**Check logs:**
```bash
tail -50 ~/.claude/logs/pre_meeting_cron.log
```

**Test manually:**
```bash
bash ~/.claude/scripts/pre_meeting_cron.sh
```

**Check system cron:**
```bash
# macOS
log stream --predicate 'process == "cron"'

# Linux
sudo tail -f /var/log/syslog | grep cron
```

---

## Advanced Usage

### Integrate with Other Tools

**1. Slack Reminders**
```slack
# Set reminder in Slack
/remind Check dashboard metrics in 1 hour

# Convert to Claude Memory
/remind-me https://slack.com/archives/.../123
```

**2. Calendar Notifications**
- Google Calendar has native notifications
- /pre-meeting supplements with briefing

**3. Email to Action Item**
- Forward to Slack
- Use /remind-me on the Slack message

### Create Custom Reports

**Weekly Summary:**
```bash
# Extract this week's activity
cat ~/.claude/memory/memoria_agente/2026-03-0[1-7]*.md
```

**Monthly Review:**
```bash
# Review entire month
ls -la ~/.claude/memory/memoria_agente/2026-03-* | wc -l

# See all documents read
grep "## 📚 SUMMARY" ~/.claude/memory/memoria_agente/2026-03-*.md
```

**Metrics:**
```bash
# Count action items
grep "^- \[ \]" ~/.claude/memory/action_points.md | wc -l

# Count completed
grep "^- \[x\]" ~/.claude/memory/action_points.md | wc -l
```

### Debug Mode

**Verbose output:**
```bash
bash -x ~/.claude/scripts/pre_meeting_cron.sh
```

**Check credential access:**
```bash
python3 ~/.claude/scripts/secrets_helper.py get google-client-id
python3 ~/.claude/scripts/secrets_helper.py get slack-user-token
```

---

## Getting Help

**For setup issues:**
- See `docs/TROUBLESHOOTING.md`
- Run `bash ~/.claude/scripts/validate.sh`

**For skill usage questions:**
- See this document (HOW_TO_USE.md)
- Review examples in `~/.claude/memory/`

**For bugs or feature requests:**
- GitHub: https://github.com/uli6/claude-meeting-memory/issues
- Include output from `validate.sh`
- Share relevant log files

**For security concerns:**
- See `docs/TROUBLESHOOTING.md#security--permissions`
- Review `SETUP_GUIDE.md#phase-5-security-review`

---

## Summary

Your Claude Meeting Memory system has three core skills:

| Skill | Purpose | Frequency | Time |
|-------|---------|-----------|------|
| `/read-this` | Add context from documents | As needed | 2 min |
| `/pre-meeting` | Get meeting briefing | Daily | 1 min |
| `/remind-me` | Track action items | As needed | 30 sec |

**Best practices:**
- Use `/read-this` for strategic documents
- Check `/pre-meeting` every morning
- Create action items with `/remind-me` during meetings
- Enable crontab for automatic briefings
- Keep your profile updated
- Review memory weekly

**Expected outcome:** You'll walk into meetings prepared, never miss action items, and build institutional knowledge over time.

---

**Version:** 1.0.0
**Last Updated:** March 2, 2026
**Documentation:** https://github.com/uli6/claude-meeting-memory/docs/HOW_TO_USE.md
