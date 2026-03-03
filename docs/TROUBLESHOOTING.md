# Troubleshooting Guide

Common issues and solutions for Claude Meeting Memory setup and usage.

## Table of Contents

1. [Setup Issues](#setup-issues)
2. [Python Dependencies](#python-dependencies)
3. [Credential Issues](#credential-issues)
4. [Skill Issues](#skill-issues)
5. [Security & Permissions](#security--permissions)
6. [Platform-Specific Issues](#platform-specific-issues)
7. [Advanced Diagnostics](#advanced-diagnostics)

## Setup Issues

### "Claude Code not found at ~/.claude"

**Problem:** Claude Code is not installed or not at the expected location.

**Solution:**

This project requires Claude Code to be installed first. Install it from:
```bash
# Visit: https://github.com/anthropics/claude-code
# Or install via your package manager

# After installation, verify Claude Code is at ~/.claude:
ls -la ~/.claude/
```

**Why it matters:** The project adds skills and configuration to your existing Claude Code installation.

### "Command not found: curl/python3/jq"

**Problem:** Required dependencies are missing.

**Solution:**

```bash
# macOS - Install via Homebrew
brew install curl python3 jq openssl

# Ubuntu/Debian
sudo apt-get install curl python3 jq openssl

# CentOS/RHEL
sudo yum install curl python3 jq openssl

# Then verify
curl --version && python3 --version && jq --version
```

**Why it matters:** These tools are required for setup to run.

### "Bad interpreter: No such file or directory"

**Problem:** The setup script has incorrect line endings (Windows CRLF instead of Unix LF).

**Solution:**

```bash
# If you downloaded on Windows, convert line endings:
dos2unix setup.sh

# Or:
sed -i 's/\r$//' setup.sh

# Then run:
bash setup.sh
```

### "Permission denied" when running setup.sh

**Problem:** The script isn't executable, or you don't have write permissions.

**Solution:**

```bash
# Make script executable
chmod +x setup.sh

# Run it
bash setup.sh
```

Or download fresh:
```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### "curl: command not found" when piping installation

**Problem:** curl isn't installed.

**Solution:**

```bash
# Install curl first
# (see "Command not found" section above)

# Then try again:
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### Setup hangs or times out

**Problem:** Network issue or stuck process.

**Solution:**

1. Check internet connection:
   ```bash
   ping google.com
   ```

2. Wait 30 seconds (initial setup can be slow)

3. If still hanging, press `Ctrl+C` to cancel

4. Check for specific phase:
   ```bash
   # Run with verbose output
   bash -x setup.sh
   ```

5. See [Advanced Diagnostics](#advanced-diagnostics) for more help

### "jq: command not found"

**Problem:** jq (JSON parser) isn't installed.

**Solution:**

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq  # Ubuntu/Debian
sudo yum install jq      # CentOS/RHEL

# Verify
jq --version
```

## Python Dependencies

### "ModuleNotFoundError: No module named 'google'"

**Problem:** Python packages are not installed.

**Solution:**

The setup script automatically installs Python dependencies. If you skip this phase or encounter errors:

```bash
# Install all required packages
pip3 install -r requirements.txt

# Or install individually
pip3 install google-auth google-auth-oauthlib google-api-client anthropic slack-sdk
```

**Why it matters:** Email automation and credential management require these packages.

### "pip3: command not found"

**Problem:** pip3 is not installed with your Python installation.

**Solution:**

```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt-get install python3-pip

# CentOS/RHEL
sudo yum install python3-pip

# Then verify
pip3 --version
```

### "Permission denied when installing packages"

**Problem:** You don't have permission to install system-wide.

**Solution:**

```bash
# Install for current user only
pip3 install --user google-auth google-auth-oauthlib google-api-client google-generativeai slack-sdk

# Or use a virtual environment (recommended)
python3 -m venv ~/claude-venv
source ~/claude-venv/bin/activate
pip3 install -r requirements.txt
```

### Email automation shows "ModuleNotFoundError: No module named 'anthropic'"

**Problem:** Anthropic package is not installed.

**Solution:**

```bash
pip3 install anthropic
```

This package is specifically required for email automation with Claude AI.

## Credential Issues

### Google OAuth: Browser doesn't open

**Problem:** Automatic browser opening failed.

**Solution:**

1. Check output - you'll see a URL like:
   ```
   https://accounts.google.com/o/oauth2/v2/auth?...
   ```

2. Copy and paste into your browser manually

3. Authorize Claude Code

4. Return to terminal - setup continues automatically

**Why it happens:**
- Browser might not be installed
- macOS/Linux permissions issue
- Network connectivity problem

### Google OAuth: "Invalid client"

**Problem:** Client ID or Client Secret is wrong.

**Solution:**

1. Double-check in Google Cloud Console:
   - Go to https://console.cloud.google.com/
   - **APIs & Services** > **Credentials**
   - Find your "Desktop application" OAuth credentials
   - Click to view

2. Verify exact values:
   - No typos
   - No extra spaces
   - Copy-paste (don't type)

3. If still wrong:
   - Create new credentials
   - Use new values in setup

See [docs/GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md) for detailed instructions.

### Google OAuth: "Access denied"

**Problem:** You don't have permission to use this OAuth app.

**Solution:**

1. Make sure you're using the same Google account that created the Google Cloud Project:
   - Sign out of Google if needed
   - Sign in with account that owns the project
   - Try setup again

2. If using workspace (not personal) Google account:
   - Workspace admin might need to approve the app
   - Check **Security & Privacy** settings in Google Cloud Console

### Google OAuth: Token keeps expiring

**Problem:** Refresh token is no longer valid.

**Causes:**
- Google revoked the token (rare)
- 6+ months of inactivity (Google's default)
- Manual revocation in security settings

**Solution:**

```bash
# Delete the stored token
# macOS:
security delete-generic-password -a $USER -s "claude-code-google-refresh-token"

# Linux:
secret-tool delete google-refresh-token

# Then re-authorize
bash ~/.claude/scripts/google_oauth_refresh_token.py
```

### Slack: "Invalid token" or "authentication failed"

**Problem:** Slack token is wrong or revoked.

**Solution:**

1. Verify token format:
   - Must start with `xoxp-`
   - If starts with `xoxb-`, it's a bot token (wrong type)

2. Get new token:
   - Go to https://api.slack.com/apps
   - Click your app
   - **OAuth & Permissions**
   - Copy "User OAuth Token" again
   - Make sure scopes include: `chat:write`, `messages:read`, `im:write`

3. Update Claude Code:
   ```bash
   # Delete old token
   security delete-generic-password -a $USER -s "claude-code-slack-user-token"

   # Run setup again and enter new token
   bash setup.sh
   ```

See [docs/SLACK_SETUP.md](./SLACK_SETUP.md) for detailed instructions.

### Slack: "Invalid Member ID"

**Problem:** Slack Member ID is wrong.

**Solution:**

1. Get correct Member ID:
   - Open Slack
   - Click your profile (bottom-left)
   - Click "Copy user ID"
   - Should look like: `U01ABC123` (starts with U)

2. If you see different format:
   - `C01ABC...` = Channel ID (wrong)
   - `U01ABC...` = User ID (correct)

3. Update Claude Code:
   ```bash
   bash setup.sh
   ```
   And re-enter when prompted

### "credentials not found" or "secret not found"

**Problem:** Credentials stored in keychain are missing or corrupted.

**Solution:**

```bash
# Check what's stored
# macOS:
security dump-keychain | grep claude

# Linux (GNOME):
secret-tool search label "Claude Code"

# If nothing found, re-run setup
bash setup.sh
```

## Skill Issues

### /read-this: "Document not found" or "Access denied"

**Problem:** Google Doc isn't accessible or URL is wrong.

**Solutions:**

1. Verify the URL:
   - Should be: `https://docs.google.com/document/d/DOC_ID/edit`
   - Make sure you have access to the document

2. Share the document with your Google account:
   - Open doc in browser
   - Click "Share"
   - Add the account used in Google OAuth setup
   - Make sure it has at least "View" permission

3. Test the skill:
   ```bash
   /read-this https://docs.google.com/document/d/YOUR_DOC_ID/edit
   ```

### /read-this: "Connection timeout"

**Problem:** Google API is slow or unreachable.

**Solutions:**

1. Check internet connection
2. Wait a few seconds and try again
3. Verify Google is accessible:
   ```bash
   curl -I https://www.google.com
   ```
4. Check Google status: https://status.cloud.google.com/

### /pre-meeting: No meetings found

**Problem:** Calendar is empty or not synced.

**Solutions:**

1. Verify Google Calendar is accessible:
   - Sign in to Google Calendar
   - Check that events appear

2. Verify OAuth has calendar access:
   - Google Cloud Console > APIs & Services > Credentials
   - Check that Google Calendar API is enabled

3. Try again - calendars can be slow to sync:
   ```bash
   /pre-meeting
   ```

### /remind-me: "Slack message not found"

**Problem:** Message link is invalid or inaccessible.

**Solutions:**

1. Verify message link format:
   - Should be: `https://slack.com/archives/CHANNEL/pTIMESTAMP`
   - Can't access private channels you're not in

2. Make sure you have access to that channel:
   - Check that you're a member of the Slack channel

3. Copy the link correctly:
   - Right-click message in Slack
   - Click "Copy link"
   - Paste in `/remind-me`

### /remind-me: Not creating action points

**Problem:** Slack token might be invalid or lacking permissions.

**Solutions:**

1. Verify token has correct scopes:
   - https://api.slack.com/apps
   - Click your app
   - **OAuth & Permissions**
   - Check scopes include:
     - `chat:write`
     - `messages:read`
     - `im:write`

2. Reinstall to workspace:
   - Click "Reinstall to Workspace"
   - Authorize again

3. Test the token:
   ```bash
   curl -X POST https://slack.com/api/auth.test \
     -H "Authorization: Bearer $(security find-generic-password -w -a $USER -s 'claude-code-slack-user-token')"
   ```

## Security & Permissions

### "I need to revoke credentials"

**Google:**
1. Go to https://myaccount.google.com/permissions
2. Find "Claude Code"
3. Click it
4. Click "REMOVE ACCESS"

**Slack:**
1. Go to https://api.slack.com/apps
2. Click your app
3. Click "REVOKE"

**Local files:**
```bash
# Delete local credentials
security delete-generic-password -a $USER -s "claude-code-google-*"
security delete-generic-password -a $USER -s "claude-code-slack-*"

# Or fallback encryption file
rm ~/.claude/.secrets.enc
```

### "My keychain/secret service isn't working"

**Problem:** OS credential storage not accessible.

**Solutions:**

1. **macOS - Keychain Issues:**
   ```bash
   # Test Keychain access
   security find-generic-password -a $USER -s "test" 2>&1

   # If fails, you may need to unlock Keychain:
   # System Preferences > Security & Privacy > unlock your Mac
   ```

2. **Linux - Secret Service Issues:**
   ```bash
   # Verify Secret Service is running
   systemctl --user status secret-service

   # Or check if GNOME Keyring is available
   which gnome-keyring
   ```

3. **If Keychain/Secret Service is unavailable:**
   - Setup falls back to OpenSSL encryption
   - You'll be prompted for a password
   - Password is used to encrypt credentials in `~/.claude/.secrets.enc`

### "Everyone can see my credentials if they have my computer"

**This is expected.** Keychain is protected by your OS login:
- If someone logs in as you, they can access credentials
- This is same as any stored password
- To prevent: Use strong OS login password + encryption
- Don't leave computer unlocked in untrusted places

### "I want to rotate/update credentials"

**Google:**
```bash
# 1. Get new credentials from Google Cloud Console
# 2. Delete old ones:
security delete-generic-password -a $USER -s "claude-code-google-*"

# 3. Re-run setup
bash setup.sh

# 4. Enter new Google credentials
```

**Slack:**
```bash
# 1. Get new token from https://api.slack.com/apps
# 2. Delete old ones:
security delete-generic-password -a $USER -s "claude-code-slack-*"

# 3. Re-run setup
bash setup.sh

# 4. Enter new Slack token and Member ID
```

## Platform-Specific Issues

### macOS Issues

#### "SecurityFramework error"

**Problem:** Can't access Keychain.

**Solution:**
```bash
# Unlock Keychain manually:
# 1. Open Keychain Access (Applications > Utilities)
# 2. Unlock the "login" keychain
# 3. Try setup again

# Or, check if Keychain service is running:
launchctl list | grep keychain
```

#### "Permission denied" on ~/.claude/

**Problem:** Directory permissions are wrong.

**Solution:**
```bash
# Fix permissions
chmod 700 ~/.claude
chmod 700 ~/.claude/memory
chmod 700 ~/.claude/scripts
chmod 700 ~/.claude/skills
```

### Linux Issues

#### "secret-tool: command not found"

**Problem:** GNOME Secret Service isn't installed.

**Solution:**

```bash
# Ubuntu/Debian:
sudo apt-get install gnome-keyring

# CentOS/RHEL:
sudo yum install gnome-keyring

# Setup will fallback to OpenSSL encryption if unavailable
```

#### "No D-Bus session bus"

**Problem:** Secret Service daemon not running.

**Solution:**
```bash
# Start Secret Service
eval "$(dbus-launch --sh-syntax)"

# Or just use OpenSSL fallback (setup will prompt)
```

### SSH/Remote Machine Issues

**Problem:** Keychain/Secret Service not accessible over SSH.

**Solution:**

Setup automatically falls back to OpenSSL encryption when:
- Keychain/Secret Service isn't available
- Running over SSH
- X11 forwarding is disabled

You'll be prompted for a password to encrypt credentials locally.

## Advanced Diagnostics

### Enable Verbose Output

Run setup with debug output:

```bash
# Verbose bash execution
bash -x setup.sh 2>&1 | tee setup-debug.log

# Share this log for debugging (remove sensitive info first)
```

### Check Installed Components

```bash
# Verify all directories exist
ls -la ~/.claude/

# Check skills registered
cat ~/.claude/claude.json

# Verify Python dependencies
python3 -c "import google.auth; import slack_sdk; print('✓ Dependencies OK')"

# Run validation
bash ~/.claude/scripts/validate.sh
```

### Test Credentials Directly

```bash
# Test Google
python3 ~/.claude/scripts/read_google_doc.py --test

# Test Slack
curl -X POST https://slack.com/api/auth.test \
  -H "Authorization: Bearer $(~/.claude/scripts/get_secret.sh slack-user-token)"

# Test file permissions
touch ~/.claude/memory/test.txt && rm ~/.claude/memory/test.txt && echo "✓ Write OK"
```

### Get System Information

When reporting issues, include:

```bash
# System info
uname -a

# Shell version
bash --version

# Python version
python3 --version

# Key tool versions
curl --version | head -1
jq --version
openssl version

# Check if running in container/VM
systemd-detect-virt || echo "Not in container"
```

## Getting Help

### Before Asking for Help

1. Run validation:
   ```bash
   bash ~/.claude/scripts/validate.sh
   ```

2. Check logs:
   ```bash
   bash -x setup.sh 2>&1 | tee setup-debug.log
   ```

3. Search issues:
   https://github.com/uli6/claude-meeting-memory/issues

### Report a Bug

Include:
1. Error message (full)
2. Output of system information (above)
3. Steps to reproduce
4. What you expected vs. what happened
5. Your OS and version

Open issue: https://github.com/uli6/claude-meeting-memory/issues

---

**Can't find your issue?** Check:
- [SETUP_GUIDE.md](../SETUP_GUIDE.md)
- [docs/GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md)
- [docs/SLACK_SETUP.md](./SLACK_SETUP.md)
- GitHub issues: https://github.com/uli6/claude-meeting-memory/issues
