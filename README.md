# Claude Meeting Memory

Automated onboarding system for Claude Code with secure credential management, skill registration, and memory initialization.

## Features

### Core Features (Available Immediately)

✨ **Automatic Setup**
- One-command installation with interactive configuration
- Automatic directory structure creation
- Secure credential storage (Keychain/Secret Service)

📚 **Three Powerful Skills**
- **`/read-this`** - Read Google Docs and add summaries to memory
- **`/pre-meeting`** - Generate meeting briefings (grows with memory)
- **`/remind-me`** - Create action points from text or Slack

🧠 **Memory System**
- Daily memory notes (`~/.claude/memory/`)
- Action points tracking
- User profile context
- Manual updates via skills

🔐 **Security-First**
- Credentials stored in OS-native keychain (macOS/Linux)
- OpenSSL AES-256 fallback encryption
- No secrets in version control
- Transparent permission disclosure
- **Never** performs actions on your behalf (except sending your own briefings to Slack DM)

### Advanced Features (Optional Setup)

📧 **Email Automation**
- Automatically check Gmail every 10 minutes
- Use Claude AI (via Claude Code) to process and summarize emails
- Extract action items and save to memory
- Populate memory files automatically (people, projects, dates)
- Organize notes by date and topic
- Auto-close action items when they're resolved
- Perfect for capturing email-based context for meetings

**Status:** Requires 15-minute additional setup with Gmail service account (no extra API keys needed!)

## Quick Start

### Prerequisites

**Required:**
- **Claude Code** - Installed at `~/.claude` (install from [anthropics/claude-code](https://github.com/anthropics/claude-code))
- **macOS** or **Linux** (Windows Git Bash supported)
- bash 4+
- curl
- python3 (3.8 or higher)
- jq (for JSON processing)
- openssl (for credential encryption fallback)

### Installation (One Command)

```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### Python Dependencies

The setup script automatically installs required Python packages:
- `google-auth` - Google authentication
- `google-auth-oauthlib` - OAuth flow
- `google-api-client` - Google APIs
- `anthropic` - Claude API (for email automation via Claude Code)
- `slack-sdk` - Slack integration

Or install manually:
```bash
pip3 install -r requirements.txt
```

### After Installation

1. **Fill your profile:**
   ```bash
   nano ~/.claude/memory/memoria_agente/perfil_usuario.md
   ```

2. **Test the skills:**
   ```bash
   /read-this https://docs.google.com/document/d/YOUR_DOC_ID/edit
   /pre-meeting
   /remind-me Check project deadline
   ```

3. **Verify everything works:**
   ```bash
   bash ~/.claude/scripts/validate.sh
   ```

## What Works Immediately After Setup

### ✅ Ready to Use Now
- **`/read-this`** - Read Google Docs, local files, and URLs; save summaries to memory
- **`/pre-meeting`** - Generate meeting briefings from your memory (note: limited context initially)
- **`/remind-me`** - Create action points from text or Slack messages
- **Google OAuth** - Access Google Drive/Calendar (configured during setup if you choose)
- **Slack Configuration** - Set up Slack integration (configured during setup if you choose)

### ⏳ Requires Additional Setup (15 minutes)
- **Email Automation** - Automatically process emails every 10 minutes
- **Memory Auto-Population** - Fill your memory files from email content
- **Full `/pre-meeting` Context** - Requires email automation to populate memory

**If you want email automation now:** Follow [GETTING_STARTED_EMAIL.md](./docs/GETTING_STARTED_EMAIL.md) (15-minute setup guide)

**If you want to set it up later:** Your core skills work great without it. You can add email automation anytime by following the setup guide.

## What Gets Installed

This setup adds the following to your existing Claude Code installation at `~/.claude`:

| Component | Location | Purpose |
|-----------|----------|---------|
| **Memory directories** | `~/.claude/memory/` | Daily notes, action points, context |
| **Scripts** | `~/.claude/scripts/` | Helper scripts for skills |
| **Skills** | `~/.claude/skills/` | read-this, pre-meeting, remind-me |
| **Credentials** | Keychain/Secret Service | Google OAuth + Slack tokens |
| **Configuration** | `~/.claude/claude.json` | Skill registration (updated with new skills) |

**Note:** Claude Code must be installed first. If `~/.claude` doesn't exist, setup will fail with a clear error message.

## Security & Permissions

This setup handles sensitive information securely. **Important:**

- ✅ Credentials stored in OS keychain (protected by your login password)
- ✅ No credentials sent to external services
- ✅ You can revoke access anytime
- ✅ Setup shows transparent permission disclosures
- ✅ **NEVER performs actions on your behalf** - Only reads data and stores locally

See [SETUP_GUIDE.md](./SETUP_GUIDE.md#security-disclosure) for detailed security information.

**[Read SAFETY_GUARANTEE.md](./SAFETY_GUARANTEE.md)** - Complete transparency on what the system can and cannot do.

## Documentation

**Getting Started:**
- **[QUICK_START.md](./QUICK_START.md)** - 5-minute setup and first usage
- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Complete setup walkthrough with 9 phases

**Using the Skills:**
- **[HOW_TO_USE.md](./docs/HOW_TO_USE.md)** - Complete guide to all three skills with examples
- **[CRONTAB_SETUP.md](./docs/CRONTAB_SETUP.md)** - Enable automatic briefings every 10 minutes

**Email Automation (NEW!):**
- **[GETTING_STARTED_EMAIL.md](./docs/GETTING_STARTED_EMAIL.md)** - Quick 15-minute setup for email automation (no extra API keys!)
- **[EMAIL_AUTOMATION.md](./docs/EMAIL_AUTOMATION.md)** - Complete email automation guide with Claude integration
- **[EMAIL_CONFIG_REFERENCE.md](./docs/EMAIL_CONFIG_REFERENCE.md)** - Full configuration reference with examples

**Credentials & Configuration:**
- **[docs/GOOGLE_OAUTH_SETUP.md](./docs/GOOGLE_OAUTH_SETUP.md)** - Getting Google OAuth credentials
- **[docs/SLACK_SETUP.md](./docs/SLACK_SETUP.md)** - Getting Slack user token

**Troubleshooting:**
- **[docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)** - Common issues, FAQs, and solutions

## Support

- 📖 See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for common issues
- 🐛 [Report bugs on GitHub](https://github.com/uli6/claude-meeting-memory/issues)
- 💬 Check existing issues for solutions

## How It Works

### The Setup Process (10 Phases)

**Automatic Setup - Takes ~5 minutes:**
1. **Dependencies Check** - Verify required system tools
2. **Python Packages** - Automatically install Python dependencies
3. **Directory Structure** - Create `~/.claude/` directories
4. **Google OAuth** - Authorize access to Drive/Calendar (optional, browser auto-opens)
5. **Slack Configuration** - Configure Slack user token + Member ID (optional)
6. **Security Review** - Review credential storage methods
7. **Skill Registration** - Register skills in `~/.claude/claude.json`
8. **Template Creation** - Initialize memory files
9. **Validation** - Test all components
10. **Summary** - Final checklist and next steps

**After setup, your three skills are immediately ready to use.**

### Optional: Email Automation Setup (15 minutes)

If you want emails to automatically populate your memory:
1. Create a Google Cloud Project and service account
2. Configure email_config.json with your settings
3. Add cron job to process emails every 10 minutes

**Important:** Claude API is accessed through Claude Code's built-in authentication - no extra API keys needed!

**See:** [GETTING_STARTED_EMAIL.md](./docs/GETTING_STARTED_EMAIL.md) for step-by-step guide

### Credential Storage

Credentials are stored securely using your OS:

- **macOS**: Apple Keychain
- **Linux**: GNOME/KDE Secret Service
- **Fallback**: AES-256 encrypted file (`~/.claude/.secrets.enc`)

You're in control:
- Revoke Google: https://myaccount.google.com/permissions
- Revoke Slack: https://api.slack.com/apps
- Delete local credentials: `bash ~/.claude/scripts/get_secret.sh --reset`

## Advanced: Automation

After setup, you can enable automatic features:

```bash
# Enable automatic meeting briefings (optional)
# Setup will guide you through cron configuration
```

## Contributing

Found a bug? Have a suggestion? [Open an issue](https://github.com/uli6/claude-meeting-memory/issues).

## License

MIT License - See LICENSE file for details

## Verification Status

✅ **All systems verified and working:**
- Three skills ready to use immediately after setup
- Memory system fully functional
- Claude Code integration complete (no extra API keys needed)
- Email automation optional and documented
- All Python dependencies available
- Complete documentation for all features

See [SETUP_VERIFICATION_REPORT.md](./SETUP_VERIFICATION_REPORT.md) for detailed testing results.

---

**Version:** 2.0.0 (Claude Code Integration)
**Last Updated:** March 3, 2026
**Status:** ✅ Production Ready
**Repository:** https://github.com/uli6/claude-meeting-memory
