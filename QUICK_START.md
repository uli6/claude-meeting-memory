# Quick Start - Claude Meeting Memory

Get up and running in 5 minutes.

## Installation (1 minute)

### First Time Setup
```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

Follow the interactive prompts:
1. Accept system checks ✓
2. Enter Google credentials (browser opens automatically)
3. Enter Slack token + Member ID
4. Accept security disclaimer
5. Done!

### Reconfigure from Scratch
If you want to reset everything and start over:
```bash
bash setup.sh --reinstall
```

This removes old configuration but preserves your user profile.

**Troubleshooting:** See [SETUP_GUIDE.md](./SETUP_GUIDE.md#troubleshooting)

## First Steps (2 minutes)

### 1. Fill Your Profile

```bash
nano ~/.claude/memory/memoria_agente/perfil_usuario.md
```

Add:
- Your role and team
- Team members
- Recurring meetings
- Current projects

This makes briefings more personalized.

### 2. Test the Skills

**Read a document:**
```
/read-this https://docs.google.com/document/d/YOUR_DOC_ID/edit
```

**Get a briefing:**
```
/pre-meeting
```

**Create an action item:**
```
/remind-me Check the dashboard metrics
```

## Daily Usage (1 minute)

### Morning
```
/pre-meeting        # See briefing for the day
```

### During Meetings
```
/remind-me https://slack.com/archives/.../123    # Track action items
```

### Evening (Optional)
```
nano ~/.claude/memory/MEMORY.md    # Add notes about your day
```

## Automatic Briefings (Already Enabled!)

✨ **NEW:** If you configured Google OAuth during setup, automatic briefing checks are **already enabled**!

The setup script automatically:
- Adds crontab entry to run every 10 minutes
- Creates `~/.claude/logs/` for briefing logs
- Sends meeting briefings to Slack 30 minutes before each meeting

**Monitor your briefings:**
```bash
tail -f ~/.claude/logs/pre_meeting_cron.log
```

**Disable if needed:**
```bash
crontab -e
# Find and delete the pre_meeting_cron.sh line
```

**Need to set it up manually?**
See [CRONTAB_SETUP.md](./docs/CRONTAB_SETUP.md) for detailed instructions.

## Your Memory System

- `~/.claude/memory/action_points.md` - Your action items
- `~/.claude/memory/MEMORY.md` - Daily notes
- `~/.claude/memory/memoria_agente/` - Detailed context
- `~/.claude/claude.json` - Skills configuration

## The Three Skills

| Skill | Purpose | Frequency |
|-------|---------|-----------|
| `/read-this URL` | Save docs to memory | As needed |
| `/pre-meeting` | Get meeting briefing | Daily |
| `/remind-me TEXT` | Track action items | During meetings |

## Documentation

- **[HOW_TO_USE.md](./docs/HOW_TO_USE.md)** - Complete skill guide
- **[CRONTAB_SETUP.md](./docs/CRONTAB_SETUP.md)** - Automate briefings
- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Detailed setup walkthrough
- **[TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)** - Common issues
- **[GOOGLE_OAUTH_SETUP.md](./docs/GOOGLE_OAUTH_SETUP.md)** - Get Google credentials
- **[SLACK_SETUP.md](./docs/SLACK_SETUP.md)** - Get Slack credentials

## Common Tasks

**Update your profile:**
```bash
nano ~/.claude/memory/memoria_agente/perfil_usuario.md
```

**View action items:**
```bash
cat ~/.claude/memory/action_points.md
```

**Find a document you read:**
```bash
grep -r "dashboard" ~/.claude/memory/
```

**Test everything is working:**
```bash
bash ~/.claude/scripts/validate.sh
```

**View briefing logs (automation):**
```bash
tail -20 ~/.claude/logs/pre_meeting_cron.log
```

## Need Help?

- **Setup issues?** See [SETUP_GUIDE.md](./SETUP_GUIDE.md)
- **How to use skills?** See [HOW_TO_USE.md](./docs/HOW_TO_USE.md)
- **Automation questions?** See [CRONTAB_SETUP.md](./docs/CRONTAB_SETUP.md)
- **Troubleshooting?** See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)
- **Bug report?** Open issue: https://github.com/uli6/claude-meeting-memory/issues

## What's Next?

1. ✓ Install setup.sh
2. ✓ Fill your profile
3. ✓ Test the skills
4. **→ Read [HOW_TO_USE.md](./docs/HOW_TO_USE.md) for detailed usage**
5. **→ Enable automation with [CRONTAB_SETUP.md](./docs/CRONTAB_SETUP.md)**

---

**You're ready!** Start using `/read-this`, `/pre-meeting`, and `/remind-me` to build your meeting memory system.
