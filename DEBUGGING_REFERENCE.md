# Debugging Reference - Setup Script

Quick reference guide for diagnosing setup.sh issues.

## Issue: Setup shows completion without prompting

### Symptom
```
$ bash setup.sh
[... phases run quickly ...]
Setup Completed Successfully!
```
User is **not prompted** for Google OAuth or Slack configuration.

### Diagnosis Steps

1. **Check if script is being piped:**
   ```bash
   # ❌ This has the issue (before fix)
   curl -fsSL https://...setup.sh | bash

   # ✅ This works fine
   bash setup.sh
   ```

2. **Test stdin availability:**
   ```bash
   # Check if stdin is connected to terminal
   if [[ -t 0 ]]; then
       echo "stdin is a terminal"
   else
       echo "stdin is NOT a terminal (piped)"
   fi
   ```

3. **Test /dev/tty availability:**
   ```bash
   # Check if /dev/tty device exists
   ls -la /dev/tty
   # Output: crw-rw-rw- 1 root tty ...  (should exist)
   ```

4. **Trace execution with debug flag:**
   ```bash
   # Run setup with debug output
   bash -x setup.sh 2>&1 | grep -A 2 -B 2 "ask_yes_no\|read_input"
   ```

### Related Issues (Fixed)

| Commit | Issue | Fix |
|--------|-------|-----|
| `3c4578f` | stdin consumed by pipe | Use /dev/tty for terminal input |
| `a45d97f` | Documentation missing | Added STDIN_TTY_FIX.md |
| `453ec60` | No validation report | Added FIX_SUMMARY.md |

## Issue: Script hangs waiting for input

### Symptom
```
$ bash setup.sh
Configure Google OAuth? (Y/n): █
# ... script hangs, won't accept input ...
```

### Diagnosis Steps

1. **Check terminal device:**
   ```bash
   # Verify /dev/tty is accessible
   test -c /dev/tty && echo "✓ /dev/tty exists" || echo "✗ /dev/tty missing"
   ```

2. **Check if stdin is readable:**
   ```bash
   # Test stdin directly
   echo "test" | bash -c 'read line; echo "Got: $line"'
   ```

3. **Test read command directly:**
   ```bash
   # Direct test of read from /dev/tty
   bash -c 'if [[ -c /dev/tty ]]; then read -r x </dev/tty; echo "You entered: $x"; fi'
   ```

4. **Check shell permissions:**
   ```bash
   # Verify bash can be executed
   which bash
   bash --version
   ```

### Common Causes

- **SSH without TTY allocation**: `ssh -T` or `ssh -f` closes TTY
  - **Fix**: Use `ssh -t` to allocate PTY

- **Tmux/Screen session**: TTY handling differs
  - **Fix**: Standard stdin/tty should still work

- **Cron job**: No TTY in cron
  - **Fix**: Script handles this with fallback to stdin

- **Background process**: `&` detaches from terminal
  - **Fix**: Run in foreground: `bash setup.sh` (not `bash setup.sh &`)

## Issue: Configuration not saved

### Symptom
```
$ bash setup.sh
Configure Google OAuth? (Y/n): y
[... Google setup runs ...]
$ echo $GOOGLE_REFRESH_TOKEN
# Empty - credentials not saved
```

### Diagnosis Steps

1. **Check if keychain exists (macOS):**
   ```bash
   security find-generic-password -a $USER -s "claude-code-google-client-id" 2>&1
   # Should show: "keychain found"
   # Or: "The specified item could not be found"
   ```

2. **Check if secret-tool works (Linux):**
   ```bash
   secret-tool search google-client-id 2>&1
   # Should show credentials or empty result
   ```

3. **Check fallback encryption file:**
   ```bash
   ls -la ~/.claude/.secrets.enc
   # Should exist if credentials were saved
   ```

4. **Test get_secret.sh script:**
   ```bash
   bash ~/.claude/scripts/get_secret.sh google-client-id
   # Should return the stored credential
   ```

5. **Check environment variables:**
   ```bash
   env | grep GOOGLE_
   env | grep SLACK_
   # Should show credentials if loaded
   ```

## Issue: Python dependencies not installing

### Symptom
```
Phase 1.5: Python Dependencies
✗ Failed to install: google-api-client
```

### Diagnosis Steps

1. **Check Python version:**
   ```bash
   python3 --version
   # Should be 3.8 or higher
   ```

2. **Check pip:**
   ```bash
   python3 -m pip --version
   # Should show pip version and Python
   ```

3. **Check if package imports work:**
   ```bash
   python3 -c "import google.auth; print('✓ google-auth works')"
   python3 -c "import google_auth_httplib2; print('✓ google-auth-httplib2 works')"
   ```

4. **Try manual installation:**
   ```bash
   pip3 install --upgrade pip
   pip3 install google-auth google-auth-oauthlib google-auth-httplib2 google-api-client slack-sdk
   ```

5. **Check pip cache:**
   ```bash
   pip3 cache purge
   pip3 install google-api-client  # Try again
   ```

## Issue: Google OAuth browser doesn't open

### Symptom
```
Opening browser for authorization...
(No browser window opens)
```

### Diagnosis Steps

1. **Check if xdg-open works (Linux):**
   ```bash
   which xdg-open
   xdg-open https://www.google.com  # Should open browser
   ```

2. **Check if open works (macOS):**
   ```bash
   which open
   open https://www.google.com  # Should open browser
   ```

3. **Manual setup (if browser doesn't open):**
   - Look for URL in setup output: `https://accounts.google.com/o/oauth2/v2/auth?...`
   - Copy the URL
   - Paste in your browser manually
   - Complete authorization
   - Return to terminal and press Enter

4. **Check $DISPLAY (Linux GUI):**
   ```bash
   echo $DISPLAY
   # Should show something like :0 if X11 available
   ```

## Issue: Slack token validation fails

### Symptom
```
Phase 4: Slack Integration
Enter your Slack user token: xoxp-...
✗ Slack token is invalid
```

### Diagnosis Steps

1. **Check token format:**
   ```bash
   # Slack user tokens start with xoxp-
   # Slack bot tokens start with xoxb- (NOT supported)
   echo $SLACK_BOT_TOKEN | grep -E "^xoxp-"
   ```

2. **Test Slack API directly:**
   ```bash
   curl -X POST https://slack.com/api/auth.test \
     -H "Authorization: Bearer $SLACK_BOT_TOKEN"
   # Should return: {"ok":true,"url":"...","team":"...","user":"...","team_id":"...","user_id":"..."}
   ```

3. **Verify Slack workspace:**
   - Go to https://api.slack.com/apps
   - Click on your app
   - Check "Bot Token Scopes"
   - Ensure you have `chat:write` permission

4. **Get new token if needed:**
   - Go to https://api.slack.com/apps
   - Click "Install App" or "Reinstall App"
   - Copy the new Bot Token
   - Re-run setup: `bash setup.sh --reinstall`

## Debugging Commands

### Enable script debugging
```bash
# Run with debugging output
bash -x setup.sh

# Run specific phase with debugging
bash -x setup.sh 2>&1 | grep -A 10 "phase_3_google_oauth"
```

### Check file permissions
```bash
# Verify directories exist and are readable
ls -la ~/.claude/
ls -la ~/.claude/scripts/
ls -la ~/.claude/skills/
```

### Validate JSON files
```bash
# Check if claude.json is valid
python3 -m json.tool ~/.claude/claude.json

# Check if config files are valid
python3 -m json.tool ~/.claude/email_config.json 2>/dev/null || echo "File missing (OK)"
```

### Check crontab entry
```bash
# View crontab entries
crontab -l | grep -E "pre_meeting|reminder"

# Edit crontab
crontab -e
```

### View setup logs
```bash
# If logging is enabled
tail -100 ~/.claude/logs/setup.log
tail -f ~/.claude/logs/pre_meeting_cron.log
```

## Quick Fix Commands

### Reset credentials
```bash
# macOS: Remove from Keychain
security delete-generic-password -a $USER -s "claude-code-google-client-id"

# Linux: Remove from Secret Service
secret-tool clear google-client-id

# Fallback: Remove encrypted file
rm ~/.claude/.secrets.enc
```

### Reinstall cleanly
```bash
# This removes old config but preserves your profile
bash setup.sh --reinstall
```

### Validate setup
```bash
# Run validation script
bash ~/.claude/scripts/validate.sh
```

### Get help
```bash
# Show setup help
bash setup.sh --help
```

## Reference: Function Locations

| Function | Line | Purpose |
|----------|------|---------|
| `ask_yes_no()` | 208 | Prompt user for yes/no with /dev/tty support |
| `read_input()` | 237 | Read user input with optional masking and /dev/tty support |
| `print_header()` | 83 | Print colored header |
| `print_success()` | 89 | Print success message |
| `print_error()` | 93 | Print error message |
| `phase_1_checks()` | 288 | Initial dependency checks |
| `phase_1_5_python_deps()` | 348 | Install Python packages |
| `phase_2_directories()` | 426 | Create directory structure |
| `phase_3_google_oauth()` | 476 | Google OAuth setup |
| `phase_4_slack()` | 702 | Slack integration |
| `phase_4_5_crontab_automation()` | 887 | Setup automatic briefing |
| `phase_5_security()` | 951 | Security disclosure |
| `phase_6_skills()` | 1010 | Register skills |
| `phase_7_templates()` | 1082 | Create template files |
| `phase_7_5_profile_setup()` | 1163 | Setup user profile |
| `phase_8_validation()` | 1256 | Validate installation |
| `phase_9_summary()` | 1469 | Show completion summary |
| `main()` | 1527 | Main setup flow |

## Related Documentation

- **STDIN_TTY_FIX.md** - Technical details of the stdin/tty fix
- **FIX_SUMMARY.md** - Complete summary of the issue and fix
- **SETUP_GUIDE.md** - Complete setup documentation
- **TROUBLESHOOTING.md** - User-facing troubleshooting guide

---

**Last Updated**: March 3, 2026
**Version**: 1.0.0
**Status**: Production Ready
