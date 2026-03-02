# Claude Meeting Memory

Automated onboarding system for Claude Code with secure credential management, skill registration, and memory initialization.

## Features

✨ **Automatic Setup**
- One-command installation with interactive configuration
- Automatic directory structure creation
- Secure credential storage (Keychain/Secret Service)

🔐 **Security-First**
- Credentials stored in OS-native keychain (macOS/Linux)
- OpenSSL AES-256 fallback encryption
- No secrets in version control
- Transparent permission disclosure

📚 **Three Powerful Skills**
- **read-this** - Read Google Docs and add summaries to memory
- **pre-meeting** - Generate meeting briefings with context
- **remind-me** - Create action points from Slack messages

🧠 **Memory System**
- Daily memory notes (`~/.claude/memory/`)
- Action points tracking
- User profile context
- Automatic synchronization

## Quick Start

### Installation (One Command)

```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### Prerequisites

- **macOS** or **Linux** (Windows Git Bash supported)
- bash 4+
- curl
- python3
- jq (for JSON processing)
- openssl (for credential encryption fallback)

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

## What Gets Installed

| Component | Location | Purpose |
|-----------|----------|---------|
| **Memory directories** | `~/.claude/memory/` | Daily notes, action points, context |
| **Scripts** | `~/.claude/scripts/` | Helper scripts for skills |
| **Skills** | `~/.claude/skills/` | read-this, pre-meeting, remind-me |
| **Credentials** | Keychain/Secret Service | Google OAuth + Slack tokens |
| **Configuration** | `~/.claude/claude.json` | Skill registration |

## Security & Permissions

This setup handles sensitive information securely. **Important:**

- ✅ Credentials stored in OS keychain (protected by your login password)
- ✅ No credentials sent to external services
- ✅ You can revoke access anytime
- ✅ Setup shows transparent permission disclosures

See [SETUP_GUIDE.md](./SETUP_GUIDE.md#security-disclosure) for detailed security information.

## Documentation

**Getting Started:**
- **[QUICK_START.md](./QUICK_START.md)** - 5-minute setup and first usage
- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Complete setup walkthrough with 9 phases

**Using the Skills:**
- **[HOW_TO_USE.md](./docs/HOW_TO_USE.md)** - Complete guide to all three skills with examples
- **[CRONTAB_SETUP.md](./docs/CRONTAB_SETUP.md)** - Enable automatic briefings every 10 minutes

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

### The Setup Process (9 Phases)

1. **Dependencies Check** - Verify required tools
2. **Directory Structure** - Create `~/.claude/` directories
3. **Google OAuth** - Authorize access to Drive/Calendar (browser auto-opens)
4. **Slack Configuration** - Configure Slack user token + Member ID
5. **Security Review** - Review credential storage methods
6. **Skill Registration** - Register skills in `~/.claude/claude.json`
7. **Template Creation** - Initialize memory files
8. **Validation** - Test all components
9. **Summary** - Final checklist and next steps

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

---

**Version:** 1.0.0
**Last Updated:** March 2, 2026
**Repository:** https://github.com/uli6/claude-meeting-memory
