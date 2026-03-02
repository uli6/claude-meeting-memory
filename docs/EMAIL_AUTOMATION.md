# Email Automation with Gemini Integration

Complete guide to automatically collecting emails and generating memory notes via Gemini AI.

## Overview

This automation system runs every 10 minutes to:
1. **Check email** - Fetch new emails from your inbox
2. **Extract with Gemini** - Use Gemini AI to intelligently extract key information
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
Send to Gemini API
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

### 2. Gemini API Setup

#### Get API Key
```bash
1. Go to https://makersuite.google.com/app/apikey
2. Create new API key
3. Store securely (in Keychain)
```

#### Scope of Access
```
Models Available:
  - gemini-1.5-flash (faster, cheaper)
  - gemini-1.5-pro (more accurate)
  - gemini-2.0-flash (latest)

Recommended: gemini-1.5-flash for email processing
```

### 3. Local Setup

```bash
# Install Python dependencies
pip3 install google-auth-oauthlib google-api-client google-generativeai python-dotenv

# Create email config
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
  "gemini": {
    "enabled": true,
    "model": "gemini-1.5-flash",
    "temperature": 0.7,
    "max_tokens": 1000
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
  "gemini_notes": {
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
| `gemini` | Gemini AI settings | model selection, temperature, token limits |
| `filtering` | Email filtering | age limit, content length, keywords, ignore patterns |
| `memory` | Note storage | directory path, organization, action point updates |
| `gemini_notes` | Special handling | subdirectory organization, extraction options |
| `automation` | Cron scheduling | interval, timeout, retry settings |
| `logging` | Log management | file path, log level, file rotation |
| `security` | Security settings | SSL verification, keychain usage, secret masking |

### Environment Setup

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export CLAUDE_EMAIL_AUTOMATION=true
export CLAUDE_GEMINI_MODEL=gemini-1.5-flash
```

---

## Automation Script

### Main Script: `email_memory_cron.sh`

```bash
#!/bin/bash

# Email Memory Automation via Crontab
# Runs every 10 minutes to collect emails and generate memory notes

set -euo pipefail

CLAUDE_HOME="${HOME}/.claude"
LOGS_DIR="${CLAUDE_HOME}/logs"
CONFIG_FILE="${CLAUDE_HOME}/config/email_config.json"

mkdir -p "$LOGS_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGS_DIR/email_memory.log"
}

log "════════════════════════════════════════════════════════════════"
log "Email Memory Automation started"

# Check if enabled
if [[ ! -f "$CONFIG_FILE" ]]; then
    log "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Run Python script
python3 "${CLAUDE_HOME}/scripts/email_memory_processor.py" >> "$LOGS_DIR/email_memory.log" 2>&1

log "Email Memory Automation completed"
```

### Python Script: `email_memory_processor.py`

```python
#!/usr/bin/env python3

import os
import json
import sys
from datetime import datetime
from pathlib import Path

# Add scripts to path
sys.path.insert(0, os.path.expanduser("~/.claude/scripts"))

try:
    from secrets_helper import get_secret
except ImportError:
    print("ERROR: secrets_helper.py not found", file=sys.stderr)
    sys.exit(1)

try:
    from google.oauth2.service_account import Credentials
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
    import google.generativeai as genai
except ImportError:
    print("ERROR: Missing Google/Gemini libraries", file=sys.stderr)
    print("Install: pip3 install google-auth google-api-client google-generativeai", file=sys.stderr)
    sys.exit(1)


class EmailMemoryProcessor:
    def __init__(self):
        self.config_path = Path.home() / ".claude" / "config" / "email_config.json"
        self.memory_path = Path.home() / ".claude" / "memory" / "memoria_agente"
        self.action_points_path = Path.home() / ".claude" / "memory" / "action_points.md"

        self.load_config()
        self.setup_clients()

    def load_config(self):
        """Load configuration from JSON file"""
        try:
            with open(self.config_path) as f:
                self.config = json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Config file not found: {self.config_path}")
        except json.JSONDecodeError:
            raise ValueError(f"Invalid JSON in config file: {self.config_path}")

    def setup_clients(self):
        """Initialize Gmail and Gemini clients"""

        # Setup Gmail
        if self.config["gmail"]["enabled"]:
            self.setup_gmail()

        # Setup Gemini
        if self.config["gemini"]["enabled"]:
            self.setup_gemini()

    def setup_gmail(self):
        """Setup Gmail API client"""
        try:
            service_account_file = os.path.expanduser(
                self.config["gmail"]["service_account_json"]
            )

            credentials = Credentials.from_service_account_file(
                service_account_file,
                scopes=['https://www.googleapis.com/auth/gmail.readonly']
            )

            self.gmail_service = build('gmail', 'v1', credentials=credentials)
            print("✓ Gmail API connected")
        except Exception as e:
            print(f"ERROR: Gmail setup failed: {e}", file=sys.stderr)
            raise

    def setup_gemini(self):
        """Setup Gemini API client"""
        try:
            api_key = get_secret("gemini-api-key")
            if not api_key:
                api_key = os.getenv("GEMINI_API_KEY")

            if not api_key:
                raise ValueError("Gemini API key not found")

            genai.configure(api_key=api_key)
            self.gemini_model = genai.GenerativeModel(
                self.config["gemini"]["model"]
            )
            print("✓ Gemini API configured")
        except Exception as e:
            print(f"ERROR: Gemini setup failed: {e}", file=sys.stderr)
            raise

    def fetch_emails(self):
        """Fetch recent emails from Gmail"""
        try:
            query = f"is:unread newer_than:{self.config['filtering']['max_age_days']}d"

            results = self.gmail_service.users().messages().list(
                userId='me',
                q=query,
                maxResults=self.config["gmail"]["max_results"]
            ).execute()

            messages = results.get('messages', [])
            print(f"✓ Fetched {len(messages)} emails")
            return messages
        except Exception as e:
            print(f"ERROR: Failed to fetch emails: {e}", file=sys.stderr)
            return []

    def get_email_content(self, message_id):
        """Get full email content"""
        try:
            message = self.gmail_service.users().messages().get(
                userId='me',
                id=message_id,
                format='full'
            ).execute()

            headers = message['payload']['headers']
            from_header = next(h['value'] for h in headers if h['name'] == 'From')
            subject = next(h['value'] for h in headers if h['name'] == 'Subject')
            date = next(h['value'] for h in headers if h['name'] == 'Date')

            # Get body
            body = self.extract_body(message['payload'])

            return {
                'id': message_id,
                'from': from_header,
                'subject': subject,
                'date': date,
                'body': body
            }
        except Exception as e:
            print(f"ERROR: Failed to get email content: {e}", file=sys.stderr)
            return None

    def extract_body(self, payload):
        """Extract email body from payload"""
        if 'parts' in payload:
            parts = payload['parts']
            data = next((p['body']['data'] for p in parts
                        if p['mimeType'] == 'text/plain'), None)
        else:
            data = payload['body'].get('data')

        if data:
            import base64
            return base64.urlsafe_b64decode(data).decode('utf-8')
        return ""

    def process_with_gemini(self, email_content):
        """Use Gemini to extract and summarize email"""
        prompt = f"""
Analyze this email and extract key information:

From: {email_content['from']}
Subject: {email_content['subject']}
Date: {email_content['date']}

Content:
{email_content['body']}

Please provide:
1. Main topic/project
2. Key decisions made
3. Action items (with owners if mentioned)
4. Important dates/deadlines
5. People mentioned
6. Follow-up needed

Format as structured markdown suitable for memory system.
"""

        try:
            response = self.gemini_model.generate_content(
                prompt,
                temperature=self.config["gemini"]["temperature"]
            )
            return response.text
        except Exception as e:
            print(f"ERROR: Gemini processing failed: {e}", file=sys.stderr)
            return None

    def save_to_memory(self, email_content, processed_content):
        """Save processed email to memory"""
        try:
            # Determine filename
            date_str = datetime.now().strftime("%Y-%m-%d")

            # Extract sender name
            from_email = email_content['from'].split('<')[-1].rstrip('>')
            sender_name = email_content['from'].split('<')[0].strip()

            # Create filename
            if self.config["memory"]["include_sender_files"]:
                filename = f"{date_str}_from_{sender_name.lower().replace(' ', '_')}.md"
            else:
                filename = f"{date_str}_email_summary.md"

            filepath = self.memory_path / filename

            # Create content
            content = f"""# Email: {email_content['subject']}

**From:** {email_content['from']}
**Date:** {email_content['date']}
**Saved:** {datetime.now().isoformat()}

## Extracted Information

{processed_content}

---

## Original Email

{email_content['body'][:500]}... (truncated)

**Source:** Email from {sender_name}
"""

            # Save file
            with open(filepath, 'a') as f:
                f.write(content + "\n\n---\n\n")

            print(f"✓ Saved to {filepath}")
            return filepath
        except Exception as e:
            print(f"ERROR: Failed to save memory: {e}", file=sys.stderr)
            return None

    def extract_action_items(self, processed_content, email_content):
        """Extract action items and add to action_points.md"""
        try:
            # Parse processed content for action items
            lines = processed_content.split('\n')
            action_items = []

            in_actions_section = False
            for line in lines:
                if 'Action' in line and 'item' in line.lower():
                    in_actions_section = True
                elif in_actions_section:
                    if line.strip().startswith('-') or line.strip().startswith('•'):
                        action_items.append(line.strip().lstrip('-•').strip())
                    elif line.startswith('#'):
                        in_actions_section = False

            # Add to action_points.md
            if action_items:
                with open(self.action_points_path, 'a') as f:
                    f.write("\n# From Email\n\n")
                    sender = email_content['from'].split('<')[0].strip()
                    for item in action_items:
                        f.write(f"- [ ] {item}\n")
                        f.write(f"  - Source: Email from {sender}, {email_content['date']}\n")
                        f.write(f"  - Context: {email_content['subject']}\n\n")

                print(f"✓ Added {len(action_items)} action items")
        except Exception as e:
            print(f"ERROR: Failed to extract action items: {e}", file=sys.stderr)

    def run(self):
        """Main automation loop"""
        try:
            # Fetch emails
            messages = self.fetch_emails()
            if not messages:
                print("No new emails to process")
                return

            # Process each email
            for message in messages:
                print(f"\nProcessing message: {message['id']}")

                # Get content
                email_content = self.get_email_content(message['id'])
                if not email_content:
                    continue

                # Skip if too short
                if len(email_content['body']) < self.config["filtering"]["min_content_length"]:
                    print("  Skipped (too short)")
                    continue

                # Process with Gemini
                processed = self.process_with_gemini(email_content)
                if not processed:
                    continue

                # Save to memory
                self.save_to_memory(email_content, processed)

                # Extract action items
                self.extract_action_items(processed, email_content)

            print("\n✓ Email processing completed")
        except Exception as e:
            print(f"ERROR: Automation failed: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    processor = EmailMemoryProcessor()
    processor.run()
```

---

## Installation

### Step 1: Get Credentials

**Gmail Service Account:**
1. Go to Google Cloud Console
2. Create service account JSON
3. Save to `~/.claude/secrets/gmail-service-account.json`
4. Restrict permissions to Gmail read-only

**Gemini API Key:**
1. Go to https://makersuite.google.com/app/apikey
2. Get API key
3. Store using: `security add-generic-password -a $USER -s "claude-code-gemini-api-key" -w "YOUR_KEY"`

### Step 2: Install Dependencies

```bash
pip3 install google-auth-oauthlib google-api-client google-generativeai python-dotenv
```

### Step 3: Create Config

```bash
mkdir -p ~/.claude/config
nano ~/.claude/config/email_config.json
# Paste the config JSON above
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
```

---

## What Gets Collected

### Types of Information

**From Email Headers:**
- Sender name and email
- Subject line
- Date/time received
- Labels/categories

**From Email Body (via Gemini):**
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

### Use Different Gemini Model

Change in config:
```json
"gemini": {
  "model": "gemini-2.0-flash"  # Latest and fastest
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

### "Gemini API key not found"

```bash
# Store in Keychain
security add-generic-password -a $USER -s "claude-code-gemini-api-key" -w "YOUR_KEY"

# Verify
security find-generic-password -a $USER -s "claude-code-gemini-api-key"
```

### "No emails being processed"

Check:
1. Email labels match config
2. Unread emails exist
3. Email age is within max_age_days
4. Content length exceeds min_content_length

### "Action items not appearing"

1. Check if Gemini is extracting them correctly
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

✅ Email summaries (via Gemini)
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
- ✅ Automatic email collection
- ✅ AI-powered extraction via Gemini
- ✅ Intelligent summarization
- ✅ Action item tracking
- ✅ Integration with memory system
- ✅ Context for meetings
- ✅ Never miss important info

**Every 10 minutes:**
1. Check for new emails
2. Analyze with Gemini
3. Save to memory
4. Extract action items
5. Stay in sync

---

**Version:** 1.0.0
**Last Updated:** March 2, 2026
