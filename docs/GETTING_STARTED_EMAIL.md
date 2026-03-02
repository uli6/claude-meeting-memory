# Getting Started with Email Automation

Learn how to automatically process emails with Gemini and save them to your memory system.

## 🎯 What You'll Get

After setup, you'll have:

- ✅ Automatic email collection every 10 minutes
- ✅ Gemini AI processing for intelligent summaries
- ✅ Structured notes saved to your memory system
- ✅ Action items automatically extracted
- ✅ Organized by date and topic
- ✅ Full crontab automation

## 🚀 Quick Start (15 minutes)

### Step 1: Prepare Gmail API (5 minutes)

```bash
# 1. Create a Google Cloud Project
#    Visit: https://console.cloud.google.com/
#    - Click "Create Project"
#    - Name it: "Claude Email Memory"
#    - Click "Create"

# 2. Enable Gmail API
#    - Go to "APIs & Services" > "Library"
#    - Search for "Gmail API"
#    - Click "Enable"

# 3. Create a Service Account
#    - Go to "APIs & Services" > "Credentials"
#    - Click "Create Credentials" > "Service Account"
#    - Name: "claude-email-reader"
#    - Click "Create and Continue"
#    - Grant role: "Editor"
#    - Click "Continue" then "Done"

# 4. Create and Download JSON Key
#    - Click on the service account you created
#    - Go to "Keys" tab
#    - Click "Add Key" > "Create new key"
#    - Choose "JSON" format
#    - Click "Create"
#    - The JSON file will download automatically

# 5. Save the JSON file
mkdir -p ~/.claude/secrets
cp ~/Downloads/YOUR-KEY-FILE.json ~/.claude/secrets/gmail-service-account.json
```

### Step 2: Get Gemini API Key (3 minutes)

```bash
# 1. Visit: https://makersuite.google.com/app/apikey
# 2. Click "Create API Key"
# 3. Copy the key
# 4. Store in Keychain (macOS) or Secret Service (Linux)
#    Run: security add-generic-password -a $USER -s "claude-code-gemini-api-key" -w "YOUR-KEY"
#    Or: secret-tool store --label="Claude Code" gemini-api-key "YOUR-KEY"
```

### Step 3: Configure Email Automation (5 minutes)

```bash
# 1. Copy example configuration
cp templates/email_config.json ~/.claude/config/email_config.json

# 2. Edit with your email and settings
nano ~/.claude/config/email_config.json

# 3. Update these fields:
#    - gmail.email: Your Gmail address
#    - gmail.service_account_json: Path to the JSON file you saved
#    - Any other customizations you want

# 4. Verify the configuration
python3 -m json.tool ~/.claude/config/email_config.json
```

### Step 4: Test the Setup (2 minutes)

```bash
# 1. Test email processing
python3 ~/.claude/scripts/email_memory_processor.py

# Output should show:
#   ✓ Config loaded
#   ✓ Gmail API connected
#   ✓ Fetched X emails
#   ✓ Processing email... [1/X]
#   ...

# 2. Check if files were created
ls -la ~/.claude/memory/memoria_agente/

# 3. Check if action items were extracted
cat ~/.claude/memory/action_points.md
```

---

## 📅 Enable Automatic Running (Crontab)

Once testing works, enable automation:

```bash
# 1. Open crontab editor
crontab -e

# 2. Add this line at the bottom
*/10 * * * * ~/.claude/scripts/email_memory_cron.sh >> ~/.claude/logs/email_memory.log 2>&1

# 3. Save and exit (Ctrl+X, Y, Enter in nano)

# 4. Verify it was added
crontab -l
```

**What this does:**
- Runs every 10 minutes
- Checks for new emails from Gmail
- Processes with Gemini AI
- Saves results to your memory
- Logs all activity

---

## 🔧 Configuration Guide

### Basic Configuration

For most users, these defaults work fine:

```json
{
  "gmail": {
    "enabled": true,
    "service_account_json": "~/.claude/secrets/gmail-service-account.json",
    "email": "your-email@gmail.com",
    "labels_to_check": ["INBOX"],
    "max_results": 10
  },
  "gemini": {
    "enabled": true,
    "model": "gemini-1.5-flash"
  },
  "filtering": {
    "max_age_days": 1,
    "min_content_length": 50
  },
  "automation": {
    "cron_interval": "*/10 * * * *"
  }
}
```

### Advanced Configuration

For complete options and scenarios, see [EMAIL_CONFIG_REFERENCE.md](EMAIL_CONFIG_REFERENCE.md)

**Common customizations:**

1. **Check multiple Gmail labels:**
   ```json
   "labels_to_check": ["INBOX", "IMPORTANT", "WORK"]
   ```

2. **Only process priority emails:**
   ```json
   "priority_keywords": ["urgent", "action", "deadline"]
   ```

3. **Ignore promotional content:**
   ```json
   "ignore_subjects": ["newsletter", "promotional", "marketing"]
   ```

4. **Run less frequently (to save API quota):**
   ```json
   "cron_interval": "*/30 * * * *"
   ```

5. **Use more accurate AI model:**
   ```json
   "model": "gemini-1.5-pro"
   ```

---

## 📝 What Gets Saved

### Memory Files

Emails are saved as organized markdown files:

```
~/.claude/memory/memoria_agente/
├── 2026-03-02_from_john@company.com.md
├── 2026-03-02_email_summary.md
├── gemini_notes/
│   ├── 2026-03-02_meeting_notes.md
│   └── 2026-03-02_project_updates.md
└── 2026-03-03_from_maria@company.com.md
```

### Action Points

Extracted action items go here:

```
~/.claude/memory/action_points.md

- [ ] Action 1 (from email from John)
  - Source: Email from John
  - Date: 2026-03-02 10:30
  - Subject: Q1 Planning Discussion

- [ ] Action 2 (from email from Maria)
  - Source: Email from Maria
  - Date: 2026-03-02 14:15
  - Subject: Project Status Update
```

---

## 🔍 Monitoring and Logs

### Check Recent Activity

```bash
# View logs
tail -f ~/.claude/logs/email_memory.log

# See last 50 lines
tail -50 ~/.claude/logs/email_memory.log

# Search for errors
grep ERROR ~/.claude/logs/email_memory.log

# Count processed emails
grep "Processing email" ~/.claude/logs/email_memory.log | wc -l
```

### Debug a Specific Issue

```bash
# Run with debug output
python3 ~/.claude/scripts/email_memory_processor.py

# Check if config is valid
python3 -m json.tool ~/.claude/config/email_config.json

# Test Gmail connection
python3 -c "
from secrets_helper import get_secret
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build

creds = Credentials.from_service_account_file(
    '~/.claude/secrets/gmail-service-account.json',
    scopes=['https://www.googleapis.com/auth/gmail.readonly']
)
service = build('gmail', 'v1', credentials=creds)
results = service.users().messages().list(userId='me').execute()
print(f'Connected! Found {len(results.get(\"messages\", []))} messages')
"
```

---

## 🎛️ Customization Options

### Schedule Variations

**Every 5 minutes (most frequent, highest API usage):**
```bash
*/5 * * * * ~/.claude/scripts/email_memory_cron.sh
```

**Every 15 minutes:**
```bash
*/15 * * * * ~/.claude/scripts/email_memory_cron.sh
```

**Every 30 minutes (recommended to save API quota):**
```bash
*/30 * * * * ~/.claude/scripts/email_memory_cron.sh
```

**Every hour:**
```bash
0 * * * * ~/.claude/scripts/email_memory_cron.sh
```

**Only during work hours (9 AM - 6 PM, weekdays):**
```bash
*/10 9-17 * * 1-5 ~/.claude/scripts/email_memory_cron.sh
```

### Filter Variations

**Process only important emails:**
```json
{
  "gmail": {
    "labels_to_check": ["IMPORTANT"],
    "max_results": 5
  },
  "filtering": {
    "priority_keywords": ["urgent", "action", "deadline"]
  }
}
```

**Process only from specific people (by modifying the script):**
```python
# In email_memory_processor.py, modify fetch_emails():
query = "from:john@company.com OR from:maria@company.com newer_than:1d"
```

**Save to different location:**
```json
{
  "memory": {
    "save_location": "~/.claude/memory/emails"
  }
}
```

---

## 🛠️ Troubleshooting

### Issue: "Gmail API connected" fails

**Solution:** Check the service account JSON file path:
```bash
ls -la ~/.claude/secrets/gmail-service-account.json
# Should exist and be readable
```

### Issue: No emails being processed

**Solution:** Verify filter settings:
```bash
# Check if there are any unread emails
python3 << 'EOF'
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build

creds = Credentials.from_service_account_file(
    os.path.expanduser("~/.claude/secrets/gmail-service-account.json"),
    scopes=['https://www.googleapis.com/auth/gmail.readonly']
)
service = build('gmail', 'v1', credentials=creds)
results = service.users().messages().list(
    userId='me', q='is:unread newer_than:1d'
).execute()
print(f"Found {len(results.get('messages', []))} unread emails in last day")
EOF
```

### Issue: "Gemini setup failed"

**Solution:** Check Gemini API key:
```bash
# Check if key is stored
security find-generic-password -a $USER -s "claude-code-gemini-api-key" -w
# or
secret-tool lookup --label="Claude Code" gemini-api-key
```

### Issue: Action items not being extracted

**Solution:** Check configuration:
```json
{
  "memory": {
    "update_action_points": true
  },
  "gemini_notes": {
    "extract_action_items": true
  }
}
```

### Issue: Processing taking too long

**Solution:** Reduce scope:
```json
{
  "gmail": {
    "max_results": 5
  },
  "automation": {
    "timeout_seconds": 180
  },
  "gemini": {
    "model": "gemini-1.5-flash",
    "max_tokens": 500
  }
}
```

---

## 📚 More Information

- **Complete Configuration Reference:** [EMAIL_CONFIG_REFERENCE.md](EMAIL_CONFIG_REFERENCE.md)
- **Setup Guide:** [EMAIL_AUTOMATION.md](EMAIL_AUTOMATION.md)
- **General Troubleshooting:** [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- **Setup Instructions:** [SETUP_GUIDE.md](../SETUP_GUIDE.md)

---

## ✅ Checklist

Before automation starts, verify:

- [ ] Gmail API enabled in Google Cloud Console
- [ ] Service account JSON downloaded and saved
- [ ] Gemini API key created and stored in Keychain
- [ ] `~/.claude/config/email_config.json` created and configured
- [ ] `python3 ~/.claude/scripts/email_memory_processor.py` runs successfully
- [ ] Memory files created in `~/.claude/memory/memoria_agente/`
- [ ] Crontab entry added for automation
- [ ] Logs directory exists: `~/.claude/logs/`

Once all checked, automation will run automatically every 10 minutes!

---

**Need help?** See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) or check the logs:
```bash
tail -f ~/.claude/logs/email_memory.log
```
