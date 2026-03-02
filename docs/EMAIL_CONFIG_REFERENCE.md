# Email Configuration Reference

Complete reference for configuring email automation with Gemini integration.

## Quick Setup (3 Steps)

```bash
# 1. Copy example config
cp templates/email_config.json ~/.claude/config/email_config.json

# 2. Edit with your settings
nano ~/.claude/config/email_config.json

# 3. Test the setup
python3 ~/.claude/scripts/email_memory_processor.py

# 4. Enable cron automation (optional)
crontab -e
# Add: */10 * * * * ~/.claude/scripts/email_memory_cron.sh >> ~/.claude/logs/email_memory.log 2>&1
```

---

## Configuration Sections

### Gmail Configuration

```json
{
  "gmail": {
    "enabled": true,
    "service_account_json": "~/.claude/secrets/gmail-service-account.json",
    "email": "your-gmail@gmail.com",
    "labels_to_check": ["INBOX", "IMPORTANT"],
    "max_results": 10,
    "exclude_labels": ["SPAM", "TRASH", "ARCHIVED"]
  }
}
```

| Option | Type | Description | Example |
|--------|------|-------------|---------|
| `enabled` | bool | Enable Gmail integration | `true` or `false` |
| `service_account_json` | string | Path to service account JSON file | `~/.claude/secrets/gmail-service-account.json` |
| `email` | string | Your Gmail address | `your-name@gmail.com` |
| `labels_to_check` | array | Gmail labels to monitor | `["INBOX", "IMPORTANT"]` |
| `max_results` | number | Max emails per check | `5` to `100` |
| `exclude_labels` | array | Labels to ignore | `["SPAM", "TRASH"]` |

### Gemini Configuration

```json
{
  "gemini": {
    "enabled": true,
    "model": "gemini-1.5-flash",
    "temperature": 0.7,
    "max_tokens": 1000
  }
}
```

| Option | Type | Description | Default | Options |
|--------|------|-------------|---------|---------|
| `enabled` | bool | Enable Gemini AI processing | `true` | `true`, `false` |
| `model` | string | Gemini model to use | `gemini-1.5-flash` | `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash` |
| `temperature` | float | Creativity level (0-1) | `0.7` | Lower = deterministic, Higher = creative |
| `max_tokens` | number | Max response length | `1000` | `500` to `2000` |

**Model Comparison:**
- `gemini-1.5-flash`: Fast, cheap, good for email summaries (recommended)
- `gemini-1.5-pro`: Slower, more expensive, better accuracy for complex emails
- `gemini-2.0-flash`: Latest, balanced speed and quality

### Filtering Configuration

```json
{
  "filtering": {
    "max_age_days": 1,
    "min_content_length": 50,
    "priority_keywords": ["urgent", "action required", "decision needed"],
    "ignore_subjects": ["unsubscribe", "marketing", "newsletter"]
  }
}
```

| Option | Type | Description | Default | Notes |
|--------|------|-------------|---------|-------|
| `max_age_days` | number | Only process emails newer than N days | `1` | 1 = last 24 hours, 7 = last week |
| `min_content_length` | number | Ignore emails shorter than N chars | `50` | Helps skip automated messages |
| `priority_keywords` | array | Mark emails with these keywords | `["urgent"]` | Case-insensitive |
| `ignore_subjects` | array | Skip emails with these in subject | `["unsubscribe"]` | Case-insensitive, substring match |

### Memory Configuration

```json
{
  "memory": {
    "save_location": "~/.claude/memory/memoria_agente",
    "include_sender_files": true,
    "organize_by_date": true,
    "update_action_points": true,
    "action_points_file": "~/.claude/memory/action_points.md"
  }
}
```

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `save_location` | string | Where to save memory files | `~/.claude/memory/memoria_agente` |
| `include_sender_files` | bool | Create per-sender summary files | `true` |
| `organize_by_date` | bool | Use date-based subdirectories | `true` |
| `update_action_points` | bool | Extract action items to action_points.md | `true` |
| `action_points_file` | string | Path to action points file | `~/.claude/memory/action_points.md` |

**File Organization Examples:**

With `organize_by_date: true`:
```
memoria_agente/
├── 2026-03-02_from_john@company.com.md
├── 2026-03-02_email_summary.md
├── 2026-03-03_from_maria@company.com.md
└── 2026-03-03_email_summary.md
```

With `organize_by_date: false`:
```
memoria_agente/
├── from_john@company.com.md
├── from_maria@company.com.md
└── email_summaries.md
```

### Gemini Notes Configuration

```json
{
  "gemini_notes": {
    "enabled": true,
    "organize_in_subdirectory": true,
    "extract_action_items": true,
    "extract_dates": true,
    "extract_key_points": true
  }
}
```

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `enabled` | bool | Enable special Gemini Notes processing | `true` |
| `organize_in_subdirectory` | bool | Use `gemini_notes/` subdirectory | `true` |
| `extract_action_items` | bool | Parse and extract action items | `true` |
| `extract_dates` | bool | Find and extract important dates | `true` |
| `extract_key_points` | bool | Identify key discussion points | `true` |

**What Gets Extracted:**
- **Action Items**: Lists with "- [ ]" checkboxes
- **Dates**: Pattern matching (YYYY-MM-DD, MM/DD/YYYY, etc.)
- **Key Points**: Structured bullet lists and summaries
- **Topics**: Tags/categories from email content

### Automation Configuration

```json
{
  "automation": {
    "cron_interval": "*/10 * * * *",
    "cron_description": "Every 10 minutes",
    "max_concurrent_runs": 1,
    "timeout_seconds": 300,
    "retry_on_failure": true,
    "retry_count": 3,
    "retry_delay_seconds": 60
  }
}
```

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `cron_interval` | string | Crontab schedule expression | `*/10 * * * *` |
| `max_concurrent_runs` | number | Max simultaneous automation runs | `1` |
| `timeout_seconds` | number | Kill process if it takes longer | `300` (5 min) |
| `retry_on_failure` | bool | Retry failed email processing | `true` |
| `retry_count` | number | Number of retry attempts | `3` |
| `retry_delay_seconds` | number | Wait between retries | `60` |

**Crontab Examples:**
- `*/5 * * * *` - Every 5 minutes
- `*/10 * * * *` - Every 10 minutes (recommended)
- `*/30 * * * *` - Every 30 minutes
- `0 * * * *` - Every hour
- `0 9 * * *` - Every day at 9 AM
- `0 9 * * 1-5` - Weekdays at 9 AM

### Logging Configuration

```json
{
  "logging": {
    "enabled": true,
    "log_file": "~/.claude/logs/email_memory.log",
    "log_level": "INFO",
    "max_log_size_mb": 10,
    "archive_old_logs": true
  }
}
```

| Option | Type | Description | Default | Values |
|--------|------|-------------|---------|--------|
| `enabled` | bool | Enable logging | `true` | `true`, `false` |
| `log_file` | string | Where to save logs | `~/.claude/logs/email_memory.log` | Any writable path |
| `log_level` | string | Verbosity level | `INFO` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `max_log_size_mb` | number | Rotate logs at size | `10` | `5` to `100` |
| `archive_old_logs` | bool | Keep old log files | `true` | `true`, `false` |

**Log Levels:**
- `DEBUG`: Detailed information (verbose)
- `INFO`: General information (recommended)
- `WARNING`: Warning messages only
- `ERROR`: Errors only

### Security Configuration

```json
{
  "security": {
    "verify_ssl": true,
    "use_keychain": true,
    "keychain_fallback": "openssl-aes-256",
    "credentials_ttl_hours": 24,
    "mask_secrets_in_logs": true
  }
}
```

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `verify_ssl` | bool | Verify SSL certificates | `true` |
| `use_keychain` | bool | Use OS Keychain for credentials | `true` |
| `keychain_fallback` | string | Fallback storage method | `openssl-aes-256` |
| `credentials_ttl_hours` | number | Credential cache duration | `24` |
| `mask_secrets_in_logs` | bool | Hide credentials in log files | `true` |

---

## Common Configuration Scenarios

### Scenario 1: Check Only Important Emails (Minimal Load)

```json
{
  "gmail": {
    "labels_to_check": ["IMPORTANT"],
    "max_results": 5,
    "exclude_labels": ["SPAM", "TRASH"]
  },
  "filtering": {
    "max_age_days": 1,
    "min_content_length": 100,
    "priority_keywords": ["urgent", "action", "deadline"]
  },
  "automation": {
    "cron_interval": "*/30 * * * *"
  }
}
```

### Scenario 2: Comprehensive Email Processing

```json
{
  "gmail": {
    "labels_to_check": ["INBOX", "IMPORTANT", "WORK"],
    "max_results": 20,
    "exclude_labels": ["SPAM", "TRASH", "ARCHIVED"]
  },
  "filtering": {
    "max_age_days": 7,
    "min_content_length": 50
  },
  "gemini": {
    "temperature": 0.5,
    "max_tokens": 2000
  },
  "automation": {
    "cron_interval": "*/10 * * * *",
    "timeout_seconds": 600
  }
}
```

### Scenario 3: Gemini Notes Only

```json
{
  "gemini_notes": {
    "enabled": true,
    "organize_in_subdirectory": true,
    "extract_action_items": true,
    "extract_dates": true
  },
  "memory": {
    "save_location": "~/.claude/memory/memoria_agente/gemini_notes",
    "update_action_points": true
  },
  "filtering": {
    "max_age_days": 1
  }
}
```

---

## Troubleshooting Configuration

### Issue: Too Many Emails Being Processed

**Solution:** Adjust filtering:
```json
{
  "filtering": {
    "max_age_days": 1,
    "min_content_length": 200,
    "ignore_subjects": ["newsletter", "promotional", "unsubscribe"]
  },
  "gmail": {
    "max_results": 5
  }
}
```

### Issue: Processing Taking Too Long

**Solution:** Reduce scope and timeout:
```json
{
  "gmail": {
    "max_results": 5,
    "labels_to_check": ["INBOX"]
  },
  "automation": {
    "timeout_seconds": 180,
    "cron_interval": "*/30 * * * *"
  },
  "gemini": {
    "model": "gemini-1.5-flash",
    "max_tokens": 500
  }
}
```

### Issue: Missing Action Items

**Solution:** Ensure extraction is enabled:
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

---

## Testing Your Configuration

```bash
# 1. Validate JSON syntax
python3 -m json.tool ~/.claude/config/email_config.json

# 2. Test email processing manually
python3 ~/.claude/scripts/email_memory_processor.py

# 3. Check generated files
ls -la ~/.claude/memory/memoria_agente/

# 4. View action points
cat ~/.claude/memory/action_points.md

# 5. Check logs
tail -f ~/.claude/logs/email_memory.log

# 6. Test cron command directly
bash ~/.claude/scripts/email_memory_cron.sh
```

---

## Default Configuration

If no configuration file exists, these defaults are used:

```json
{
  "gmail": {
    "enabled": true,
    "labels_to_check": ["INBOX"],
    "max_results": 5
  },
  "gemini": {
    "enabled": true,
    "model": "gemini-1.5-flash",
    "temperature": 0.7
  },
  "filtering": {
    "max_age_days": 1,
    "min_content_length": 50
  },
  "memory": {
    "update_action_points": true,
    "organize_by_date": true
  },
  "automation": {
    "cron_interval": "*/10 * * * *",
    "timeout_seconds": 300
  }
}
```

---

## More Information

- See [EMAIL_AUTOMATION.md](EMAIL_AUTOMATION.md) for setup instructions
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- See example config in `templates/email_config.json`
