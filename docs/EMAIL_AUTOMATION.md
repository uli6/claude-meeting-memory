# Email Automation with Claude Integration

Complete guide to automatically collecting emails and generating memory notes via Claude AI (integrated with Claude Code).

## Overview

This automation system runs every 10 minutes to:
1. **Check email** - Fetch new emails from your Gmail inbox (via Gmail API)
2. **Extract with Claude** - Use Claude AI (via Claude Code) to intelligently extract key information
3. **Generate notes** - Create structured memory notes automatically
4. **Organize** - Save to `~/.claude/memory/memoria_agente/` by date and topic
5. **Update action items** - Extract and add action items to `action_points.md`

Result: Your memory system stays synchronized with your emails automatically!

---

## What Gets Automated

### Every 10 Minutes

```
Email Check (Gmail API)
    ↓
Parse Email Content
    ↓
Send to Claude API (via Claude Code)
    ↓
Extract Key Information:
  - Topics/Projects
  - Action Items
  - Decisions Made
  - Important Dates
  - People Mentioned
    ↓
Generate Markdown Note
    ↓
Save to Memory Directory
    ↓
Update action_points.md
    ↓
Log Activity
```

### What Gets Saved

**Memory Files:**
```
~/.claude/memory/memoria_agente/
├── 2026-03-02_email_summary.md      (daily digest)
├── 2026-03-02_project_updates.md    (by project)
├── 2026-03-02_meetings_scheduled.md (by type)
└── emails/
    ├── from_john@company.com.md
    ├── from_maria@company.com.md
    └── ...
```

**Action Items:**
```
~/.claude/memory/action_points.md

- [ ] Action 1 (from email from @person)
  - Source: Email from John, 2026-03-02 10:30
  - Context: Project discussion
  - Link: [Original Email](...)
```

---

## Setup Requirements

### 1. Gmail API Setup

#### Step 1: Create Google Cloud Project
```bash
1. Go to https://console.cloud.google.com/
2. Create new project: "Claude Email Memory"
3. Enable Gmail API:
   - APIs & Services > Library
   - Search "Gmail API"
   - Click Enable
```

#### Step 2: Create Service Account
```bash
1. Go to APIs & Services > Credentials
2. Create Credentials > Service Account
3. Name: "claude-email-reader"
4. Grant role: "Editor"
5. Create key: JSON format
6. Save the JSON file securely
```

#### Step 3: Share Gmail Access
```bash
1. Go to Google Account Security Settings
2. Less Secure Apps > Enable
3. Or use OAuth2 (recommended)
```

### 2. Claude API Setup

**Important:** Claude API is accessed through Claude Code's built-in authentication.

You need:
- Claude Code installed (`~/.claude/` directory)
- API key helper configured (`~/.claude/ifood_auth.sh`)
- Anthropic SDK installed

The email automation script uses **Claude Code's authentication** automatically — no extra configuration needed!

### 3. Local Setup

```bash
# Install Python dependencies
pip3 install google-auth-oauthlib google-api-client anthropic

# Create email config
mkdir -p ~/.claude/config
nano ~/.claude/config/email_config.json
```

---

## Configuration

### Email Config File

Create `~/.claude/config/email_config.json`:

**Quick Start:** Copy the example configuration file:
```bash
cp ~/templates/email_config.json ~/.claude/config/email_config.json
nano ~/.claude/config/email_config.json  # Edit with your settings
```

**Full Configuration Options:**

```json
{
  "gmail": {
    "enabled": true,
    "service_account_json": "~/.claude/secrets/gmail-service-account.json",
    "email": "your-gmail@gmail.com",
    "labels_to_check": ["INBOX", "IMPORTANT"],
    "max_results": 10,
    "exclude_labels": ["SPAM", "TRASH", "ARCHIVED"]
  },
  "claude": {
    "enabled": true,
    "model": "claude-opus-4-6",
    "max_tokens": 1024
  },
  "filtering": {
    "max_age_days": 1,
    "min_content_length": 50,
    "priority_keywords": ["urgent", "action required", "decision needed"],
    "ignore_subjects": ["unsubscribe", "marketing", "newsletter"]
  },
  "memory": {
    "save_location": "~/.claude/memory/memoria_agente",
    "include_sender_files": true,
    "organize_by_date": true,
    "update_action_points": true,
    "action_points_file": "~/.claude/memory/action_points.md"
  },
  "notes_processing": {
    "enabled": true,
    "organize_in_subdirectory": true,
    "extract_action_items": true,
    "extract_dates": true,
    "extract_key_points": true
  },
  "automation": {
    "cron_interval": "*/10 * * * *",
    "cron_description": "Every 10 minutes",
    "timeout_seconds": 300,
    "retry_on_failure": true
  },
  "logging": {
    "enabled": true,
    "log_file": "~/.claude/logs/email_memory.log",
    "log_level": "INFO"
  },
  "security": {
    "verify_ssl": true,
    "use_keychain": true,
    "mask_secrets_in_logs": true
  }
}
```

**Key Configuration Sections:**

| Section | Purpose | Key Options |
|---------|---------|------------|
| `gmail` | Gmail API access | service account path, email labels, max results |
| `claude` | Claude AI settings | model selection, token limits |
| `filtering` | Email filtering | age limit, content length, keywords, ignore patterns |
| `memory` | Note storage | directory path, organization, action point updates |
| `notes_processing` | Special handling | subdirectory organization, extraction options |
| `automation` | Cron scheduling | interval, timeout, retry settings |
| `logging` | Log management | file path, log level, file rotation |
| `security` | Security settings | SSL verification, keychain usage, secret masking |

### Claude Model Options

```json
"claude": {
  "model": "claude-opus-4-6"
}
```

Available models:
- `claude-opus-4-6` - Recommended for comprehensive email analysis (smartest)
- `claude-sonnet-4-20250514` - Balanced speed and quality
- `claude-3-haiku-20240307` - Fast and cheap, good for simple summaries

---

## Installation

### Step 1: Get Credentials

**Gmail Service Account:**
1. Go to Google Cloud Console
2. Create service account JSON
3. Save to `~/.claude/secrets/gmail-service-account.json`
4. Restrict permissions to Gmail read-only

**Claude API:**
- Already integrated via Claude Code
- Uses `~/.claude/ifood_auth.sh` for authentication
- No manual configuration needed!

### Step 2: Install Dependencies

```bash
pip3 install google-auth-oauthlib google-api-client anthropic
```

### Step 3: Create Config

```bash
mkdir -p ~/.claude/config
cp templates/email_config.json ~/.claude/config/email_config.json
nano ~/.claude/config/email_config.json
# Edit with your Gmail service account path and preferences
```

### Step 4: Add Crontab

```bash
crontab -e

# Add:
*/10 * * * * ~/.claude/scripts/email_memory_cron.sh >> ~/.claude/logs/email_memory.log 2>&1
```

### Step 5: Test

```bash
# Run manually
bash ~/.claude/scripts/email_memory_cron.sh

# Check logs
tail -f ~/.claude/logs/email_memory.log

# Check generated files
ls -la ~/.claude/memory/memoria_agente/
```

---

## How Claude Code Integration Works

### Authentication Flow

1. **email_memory_processor.py** is launched by cron
2. Script reads `~/.claude/settings.json` (Claude Code config)
3. Gets API key via `apiKeyHelper` (usually `~/.claude/ifood_auth.sh`)
4. Creates Anthropic client with token
5. Claude API calls work seamlessly

### Custom Integration Support

The setup supports iFood internal integration:

```python
# If you have custom base URLs or headers:
export ANTHROPIC_BASE_URL="https://internal-api.ifood.com/claude"
export ANTHROPIC_CUSTOM_HEADERS="X-Team:internal-team"
```

These are picked up automatically by the email processor.

---

## What Gets Collected

### Types of Information

**From Email Headers:**
- Sender name and email
- Subject line
- Date/time received
- Labels/categories

**From Email Body (via Claude):**
- Main topic/project
- Key decisions
- Action items (with owner)
- Deadlines and dates
- People mentioned
- Relationship to your projects
- Priority level

### Memory Files Created

**Daily Digest:**
```markdown
# Emails Summary - 2026-03-02

## From John Smith
- Project updates
- Action items: 2
- Decisions: 1
- Follow-up needed

## From Maria Garcia
- Meeting scheduled
- Documents shared
- Deadlines: 1
```

**By Topic:**
```markdown
# Project: Dashboard Redesign

### Emails related to this project:
- Email 1: Design approval needed
- Email 2: Timeline update
- Email 3: Budget discussion
```

**By Sender:**
```markdown
# From: john@company.com

## March 2, 2026 - 10:30 AM

### Topic: Q1 Planning
...content...

### Action Items:
- [ ] Review proposal
- [ ] Schedule meeting
```

---

## Integration with Other Skills

### /pre-meeting Uses Email Context

When you run `/pre-meeting`:
```
/pre-meeting "Project Review"

📚 RELEVANT CONTEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

From emails (last 7 days):
- Maria: "Dashboard redesign on track"
- John: "Budget approved for new tools"
- Sarah: "Timeline moved back 1 week"

Key decisions from emails:
- Approved budget: $50,000
- New deadline: March 31
- Added 2 engineers to team
```

### /remind-me Can Reference Emails

```
/remind-me Check dashboard mock-ups (from Maria's email today)

# Creates:
- [ ] Check dashboard mock-ups (from Maria's email today)
  - Source: Email from Maria Garcia, 2026-03-02
  - Context: Dashboard Redesign project
```

---

## Customization

### Filter Important Emails Only

Edit config to add custom filters:

```json
"filtering": {
  "priority_keywords": ["urgent", "deadline", "approved", "decision"],
  "only_from": ["manager@company.com", "team@company.com"],
  "ignore_subjects": ["newsletter", "notification", "digest"]
}
```

### Change Frequency

**Every 5 minutes:**
```bash
*/5 * * * * ~/.claude/scripts/email_memory_cron.sh
```

**Every 30 minutes:**
```bash
*/30 * * * * ~/.claude/scripts/email_memory_cron.sh
```

**Business hours only:**
```bash
*/10 9-17 * * 1-5 ~/.claude/scripts/email_memory_cron.sh
```

### Use Different Claude Model

Change in config:
```json
"claude": {
  "model": "claude-sonnet-4-20250514"
}
```

---

## Troubleshooting

### "Gmail API not connected"

```bash
# Verify service account file
ls -la ~/.claude/secrets/gmail-service-account.json

# Check file permissions
chmod 600 ~/.claude/secrets/gmail-service-account.json

# Verify JSON format
jq . ~/.claude/secrets/gmail-service-account.json
```

### "Claude API setup failed"

```bash
# Verify Claude Code is installed
ls -la ~/.claude/

# Check ifood_auth.sh exists and is executable
ls -la ~/.claude/ifood_auth.sh

# Test API key helper
bash ~/.claude/ifood_auth.sh
# Should return API token without error
```

### "No emails being processed"

Check:
1. Email labels match config
2. Unread emails exist
3. Email age is within max_age_days
4. Content length exceeds min_content_length

### "Action items not appearing"

1. Check if Claude is extracting them correctly
2. Verify action_points.md has write permissions
3. Check logs for parsing errors

---

## Privacy & Security

### What's NOT Stored

❌ Full email bodies (only summaries)
❌ Email attachments
❌ User credentials
❌ Email passwords

### What IS Stored

✅ Email summaries (via Claude)
✅ Extracted action items
✅ Topics and decisions
✅ Sender names (not emails)

### Disable Anytime

```bash
# Comment out crontab line
crontab -e
# Change: */10 * * * * ...
#    To: # */10 * * * * ...

# Or delete config
rm ~/.claude/config/email_config.json
```

---

## Advanced: Multiple Email Accounts

Configure multiple Gmail accounts:

```json
"gmail": {
  "accounts": [
    {
      "email": "work@company.com",
      "service_account_json": "~/.claude/secrets/work-gmail.json",
      "labels": ["INBOX", "IMPORTANT"]
    },
    {
      "email": "personal@gmail.com",
      "service_account_json": "~/.claude/secrets/personal-gmail.json",
      "labels": ["INBOX"]
    }
  ]
}
```

---

## Summary

**Email automation provides:**
- ✅ Automatic email collection (via Gmail API)
- ✅ AI-powered extraction via Claude
- ✅ Intelligent summarization
- ✅ Action item tracking
- ✅ Integration with memory system
- ✅ Context for meetings
- ✅ Never miss important info

**Every 10 minutes:**
1. Check for new emails
2. Analyze with Claude (via Claude Code)
3. Save to memory
4. Extract action items
5. Stay in sync

---

**Version:** 2.0.0
**Last Updated:** March 2, 2026
**Architecture:** Claude Code Integration
