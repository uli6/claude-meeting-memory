# Setup Guide - Claude Meeting Memory

Complete step-by-step guide to setting up Claude Meeting Memory on your machine.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Setup Process (9 Phases)](#setup-process-9-phases)
4. [Security Disclosure](#security-disclosure)
5. [Verification](#verification)
6. [Next Steps](#next-steps)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting, ensure you have:

- **Operating System**: macOS or Linux (Windows with Git Bash may work)
- **Shell**: bash 4.0 or later
- **Internet**: Connection required for OAuth flows
- **Tools**:
  - `curl` - Download and execute setup
  - `python3` - Run Python helper scripts
  - `openssl` - Encrypt credentials (fallback)
  - `jq` - Parse JSON configuration
  - `git` (optional) - Clone repository

### Check Your System

```bash
# Verify bash version (4.0+)
bash --version

# Verify required tools
command -v curl && echo "✓ curl"
command -v python3 && echo "✓ python3"
command -v openssl && echo "✓ openssl"
command -v jq && echo "✓ jq"
```

## Installation

### Option 1: Pipe Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### Option 2: Download and Run Locally

```bash
# Download
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh -o setup.sh

# Review the script
cat setup.sh

# Run
bash setup.sh
```

### Option 3: Clone and Run

```bash
git clone https://github.com/uli6/claude-meeting-memory.git
cd claude-meeting-memory
bash setup.sh
```

### Option 4: Reinstall (Reconfigure from Scratch)

If you want to reset your installation and start over:

```bash
# Download the latest setup script
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh -o setup.sh

# Run with --reinstall flag
bash setup.sh --reinstall
```

**What --reinstall does:**
- Removes old credentials (Keychain/Secret Service)
- Removes old memory files (except your user profile)
- Removes old scripts and skills
- Removes crontab entry
- Preserves your user profile
- Continues with fresh setup

**Use cases:**
- Reconfigure credentials from scratch
- Fix broken installation
- Switch between workspaces
- Reset all settings

### Option 5: Help

```bash
bash setup.sh --help
```

## Setup Process (11 Phases)

The setup script will guide you through 11 phases (including two automated phases):

### Phase 1: Initial Checks & Welcome

```
╔══════════════════════════════════════════════════════════════╗
║          Claude Meeting Memory - Onboarding Setup           ║
║                  Version 1.0.0                              ║
╚══════════════════════════════════════════════════════════════╝

Checking system requirements...
✓ bash 5.2.21
✓ curl 8.1.2
✓ python3 3.11.8
✓ openssl 3.0.8
✓ jq 1.7.1

All dependencies found! ✓
```

**What it does:**
- Detects your operating system
- Verifies all required tools are installed
- Shows what will be installed (checklist)

**If something fails:**
- See [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for solutions
- Install missing tools with your package manager

### Phase 2: Directory Structure

```
Creating directory structure...
✓ ~/.claude/
✓ ~/.claude/memory/
✓ ~/.claude/memory/memoria_agente/
✓ ~/.claude/scripts/
✓ ~/.claude/skills/

Directories created successfully!
```

**What it does:**
- Creates `~/.claude/` if it doesn't exist
- Creates memory subdirectories for storing notes
- Creates scripts and skills directories
- Sets proper permissions (mode 700)

**Locations created:**
- `~/.claude/memory/` - Your daily notes and memory
- `~/.claude/scripts/` - Helper scripts (Python + bash)
- `~/.claude/skills/` - Three skills: read-this, pre-meeting, remind-me

### Phase 3: Google OAuth Configuration

This phase opens your browser automatically to authorize Google access.

```
Setting up Google OAuth...

1. Checking for existing Google credentials...
   (If you have a Google account configured, we'll refresh the token)

2. Opening browser for authorization...
   (Your browser will open - if it doesn't, visit the link below)

   https://accounts.google.com/o/oauth2/v2/auth?...

3. Authorize the application
   - Click "Allow" to grant access to:
     ✓ Read Google Drive documents
     ✓ Read Google Calendar events

4. Authorization successful! ✓
   Token stored securely in Keychain.
```

**Prerequisites:**
- Have a Google account ready
- Be able to authorize applications
- See [docs/GOOGLE_OAUTH_SETUP.md](./docs/GOOGLE_OAUTH_SETUP.md) for detailed instructions

**What happens:**
- Browser opens automatically (or provide URL)
- You authorize Claude Code to access Drive and Calendar
- Setup stores the refresh token securely
- No password is stored, only refresh token

**If browser doesn't open:**
- Copy the URL from terminal
- Paste in your browser manually
- Return to terminal after authorizing

### Phase 4: Slack Configuration

```
Setting up Slack credentials...

Your Slack user token grants read-only access to:
✓ Messages in channels you're member of
✓ Direct messages
✓ User information

1. Enter your Slack user token:
   Paste your token (format: xoxp-...)
   [Input masked - your password is hidden]

2. Enter your Slack Member ID:
   This is your unique Slack user ID (format: U01DHE5U6MA)
   [Find instructions below]

   How to get your Member ID:
   1. Open Slack in browser or app
   2. Click your profile (bottom-left corner)
   3. Click "Copy user ID"
   4. Paste here

3. Validating Slack token...
   ✓ Token is valid
   ✓ Member ID confirmed
```

**Prerequisites:**
- Have a Slack workspace you can access
- Ability to create/manage Slack apps
- See [docs/SLACK_SETUP.md](./docs/SLACK_SETUP.md) for detailed instructions

**What happens:**
- Your Slack user token is stored securely
- Slack Member ID enables direct messaging
- No other Slack data is accessed

### Phase 4.5: Automatic Meeting Briefing Setup ✨ NEW

**Only if Google OAuth succeeded**

If you successfully configured Google OAuth, setup automatically enables meeting briefing checks:

```
════════════════════════════════════════════════════════════════
  Phase 4.5: Automatic Meeting Briefing Automation
════════════════════════════════════════════════════════════════

Google Calendar access is configured!
Setting up automatic meeting briefing checks every 10 minutes...

✓ Automatic briefing automation enabled!

Meeting briefings will be sent to Slack every 10 minutes if:
  • There's a meeting in the next 30 minutes
  • You have Slack Member ID configured

View briefing logs with:
  tail -f ~/.claude/logs/pre_meeting_cron.log

To disable this automation, edit your crontab:
  crontab -e
  (find and delete the pre_meeting_cron.sh line)
```

**What it does:**
- Automatically adds crontab entry (only once, avoids duplicates)
- Creates `~/.claude/logs/` directory for logs
- Runs `pre_meeting_cron.sh` every 10 minutes
- Sends meeting briefings to your Slack 30 minutes before meetings
- Gracefully skips if Slack Member ID not configured

**Why automatic?**
- Zero additional setup required
- Meeting briefings ready immediately after setup
- User can easily disable if not wanted

### Phase 5: Security Review

Before storing credentials, setup displays a comprehensive security disclosure:

```
🔐 SECURITY INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

We're about to store your credentials securely using:

macOS:  Apple Keychain (encrypted by OS)
Linux:  GNOME/KDE Secret Service (encrypted by OS)
Other:  AES-256 OpenSSL encryption

WHAT WILL BE STORED:
  • Google Client ID + Secret
  • Google Refresh Token (permanent)
  • Slack User Token (permanent)
  • Slack Member ID (public in your workspace)

WHERE IT STAYS:
  ✓ On your machine only
  ✓ Protected by OS keychain/secret service
  ✓ Never sent to cloud or external services
  ✓ Never sent to Claude API

WHO HAS ACCESS:
  ✓ Only you (via your OS login)
  ✓ Local scripts in ~/.claude/scripts/
  ✗ Not shared with anyone
  ✗ Not backed up to cloud

REVOKING ACCESS:
  Google: https://myaccount.google.com/permissions
  Slack:  https://api.slack.com/apps
  Local:  Delete ~/.claude/.secrets.enc or use Keychain

RISKS:
  ⚠️ If someone gains access to your computer, they can
     access these credentials (same as any login)
  ⚠️ Google/Slack can revoke tokens at any time
  ⚠️ Malicious software could read credentials

Do you understand and accept these terms? (y/n): [y]
```

**Important points:**
- You can revoke access at any time
- Credentials are protected by your OS login password
- No secrets leave your computer
- Setup asks for explicit confirmation

**If you have concerns:**
- Review [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md#security)
- You can manually manage credentials later
- Skipping setup is safe - you lose functionality but not security

### Phase 6: Skill Registration

```
Registering skills in ~/.claude/claude.json...

Merging skills (avoiding duplicates):
✓ read-this   - Read Google Docs and add to memory
✓ pre-meeting - Generate meeting briefings
✓ remind-me   - Create action points from Slack

All skills registered successfully!
```

**What it does:**
- Reads your existing `~/.claude/claude.json` (or creates new)
- Adds 3 skills if not already present
- Preserves any existing skills you have
- Validates JSON syntax

**Result:**
- Skills available as `/read-this`, `/pre-meeting`, `/remind-me` in Claude Code

### Phase 7: Create Template Files

```
Creating template memory files...

✓ ~/.claude/memory/action_points.md
  └─ Track your action items and TODOs

✓ ~/.claude/memory/MEMORY.md
  └─ Daily notes structure

✓ ~/.claude/memory/memoria_agente/perfil_usuario.md
  └─ Your user profile (fill this out!)

✓ ~/.claude/CLAUDE.md
  └─ Local instructions and documentation

All templates created!
```

**Files created:**
- `action_points.md` - Empty template, ready for your action items
- `MEMORY.md` - Structure for daily notes (Daily Notes, Projects, Context, Action Items)
- `perfil_usuario.md` - Your profile (role, team, goals, etc.)
- `CLAUDE.md` - Complete documentation for using these tools

**Next:** Fill in `perfil_usuario.md` with your information

### Phase 8: Validation

```
Validating setup...

✓ Directory structure is correct
✓ Google credentials are valid (obtained access token)
✓ Slack token is valid (auth.test passed)
✓ Skills registered in claude.json
✓ Python dependencies installed:
  - google-auth
  - google-api-client
  - slack-sdk

All validations passed! ✓
```

**What gets tested:**
- All directories exist with correct permissions
- Google OAuth token refresh works
- Slack API access is authorized
- Skills are properly registered
- Python libraries are available

**If validation fails:**
- Setup shows which component failed
- Provides remediation steps
- See [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)

### Phase 9: Summary & Next Steps

```
╔══════════════════════════════════════════════════════════════╗
║                 Setup Completed Successfully!               ║
╚══════════════════════════════════════════════════════════════╝

WHAT'S INSTALLED:
  ✓ Memory system: ~/.claude/memory/
  ✓ Scripts: ~/.claude/scripts/
  ✓ Skills: read-this, pre-meeting, remind-me
  ✓ Google OAuth: Drive + Calendar access
  ✓ Slack: Read access + direct messaging

NEXT STEPS:
  1. Fill your profile:
     nano ~/.claude/memory/memoria_agente/perfil_usuario.md

  2. Test the skills:
     /read-this https://docs.google.com/document/d/YOUR_DOC/edit
     /pre-meeting
     /remind-me Check the deadline

  3. Check documentation:
     See ~/.claude/CLAUDE.md for usage examples

  4. Verify everything works:
     bash ~/.claude/scripts/validate.sh

IMPORTANT LINKS:
  📖 Usage: See ~/.claude/CLAUDE.md
  🔐 Security: See docs/TROUBLESHOOTING.md#security
  🆘 Issues: https://github.com/uli6/claude-meeting-memory/issues
  📚 Docs: https://github.com/uli6/claude-meeting-memory/tree/main/docs

You're all set! Start using your Claude Meeting Memory system. 🚀
```

## Security Disclosure

See the [Security Disclosure](#phase-5-security-review) section in Phase 5 for complete information about:

- How credentials are stored
- Where credentials are kept
- Who can access credentials
- How to revoke access
- Potential risks

**Key point:** All credentials stay on your machine and are protected by your OS login.

## Verification

After setup completes, verify everything works:

```bash
# Run validation script
bash ~/.claude/scripts/validate.sh

# Expected output:
# ✓ Structure: OK
# ✓ Google OAuth: OK
# ✓ Slack: OK
# ✓ Skills: OK
# ✓ Dependencies: OK
```

## Next Steps

### 1. Fill Your Profile

Edit `~/.claude/memory/memoria_agente/perfil_usuario.md` with:
- Your role/title
- Team members
- Regular meetings
- Key goals/projects
- Contact information

```bash
nano ~/.claude/memory/memoria_agente/perfil_usuario.md
```

### 2. Test Each Skill

**Test read-this:**
```bash
# In Claude Code, use:
/read-this https://docs.google.com/document/d/YOUR_DOC_ID/edit
```

**Test pre-meeting:**
```bash
# Generate briefing for upcoming meetings
/pre-meeting
```

**Test remind-me:**
```bash
# Create an action point
/remind-me Review the quarterly OKRs
```

### 3. (Optional) Enable Automation

Setup can optionally configure automatic briefings via Slack. You'll be prompted during setup.

### 4. Review Documentation

- `~/.claude/CLAUDE.md` - Local usage documentation
- `./docs/TROUBLESHOOTING.md` - Common issues
- GitHub repository README

## Troubleshooting

### Common Issues

**"Command not found: curl/python3/jq"**
- See [docs/TROUBLESHOOTING.md#missing-dependencies](./docs/TROUBLESHOOTING.md)

**"Browser didn't open for Google OAuth"**
- Copy the URL from terminal and paste in browser manually
- See [docs/GOOGLE_OAUTH_SETUP.md](./docs/GOOGLE_OAUTH_SETUP.md)

**"Slack token is invalid"**
- Verify you're using a user token (xoxp-...), not bot token (xoxb-...)
- See [docs/SLACK_SETUP.md](./docs/SLACK_SETUP.md)

**"Validation failed"**
- Run validation to see which component failed
- See remediation steps for that component
- Consult [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)

For complete troubleshooting, see [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md).

---

**Next:** Run the installation command above and follow the prompts!
