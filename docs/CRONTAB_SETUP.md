# Crontab Automation Setup

Complete guide to enabling automatic meeting briefings via crontab.

## Overview

After setup, you can enable automatic briefings that:
- ✓ Run every 10 minutes
- ✓ Check your Google Calendar
- ✓ Find meetings in the next 30 minutes
- ✓ Generate intelligent briefings
- ✓ Send to you via Slack DM

This keeps you prepared without manual checking.

## What You Need

Before setting up crontab, ensure:
1. ✓ `setup.sh` completed successfully
2. ✓ Google OAuth configured (Google Drive + Calendar access)
3. ✓ Slack credentials configured (user token + member ID)
4. ✓ `validate.sh` passes all checks

Verify:
```bash
bash ~/.claude/scripts/validate.sh
```

All checks should show ✓ (green).

## Step-by-Step Setup

### Step 1: Verify the Cron Script Exists

Check that the cron script is in place:

```bash
ls -la ~/.claude/scripts/pre_meeting_cron.sh
```

Should show:
```
-rwxr-xr-x  1  user  staff  XXXX  Mar  2 19:53 ~/.claude/scripts/pre_meeting_cron.sh
```

If not executable, fix permissions:
```bash
chmod +x ~/.claude/scripts/pre_meeting_cron.sh
```

### Step 2: Create Logs Directory

The cron script needs a place to write logs:

```bash
mkdir -p ~/.claude/logs
chmod 700 ~/.claude/logs
```

### Step 3: Test the Script Manually

Before adding to crontab, test it directly:

```bash
# Run the script manually
bash ~/.claude/scripts/pre_meeting_cron.sh

# Check logs
tail -20 ~/.claude/logs/pre_meeting_cron.log
```

Expected output in log:
```
[2026-03-02 14:30:45] ════════════════════════════════════════════════════════════════
[2026-03-02 14:30:45] Pre-meeting briefing check started
[2026-03-02 14:30:45] Checking calendar for meetings in next 30 minutes...
[2026-03-02 14:30:47] No meetings found in next 30 minutes
[2026-03-02 14:30:47] ✓ Check completed successfully
```

Or if there's a meeting:
```
[2026-03-02 14:55:00] Found meeting: Team Standup
[2026-03-02 14:55:00] Checking calendar for meetings in next 30 minutes...
[2026-03-02 14:55:02] Generating briefing...
[2026-03-02 14:55:03] Sending to Slack...
[2026-03-02 14:55:04] ✓ Briefing sent: Team Standup
[2026-03-02 14:55:04] ✓ Check completed successfully
```

**If you see errors**, check [Troubleshooting](#troubleshooting) below.

### Step 4: Add to Crontab

Open the crontab editor:

```bash
crontab -e
```

This opens your default editor (nano, vim, etc.).

**Add this line** at the end of the file:

```bash
*/10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

**Explanation:**
- `*/10` = Every 10 minutes
- `* * * * *` = Every hour, every day, every month, every day of week
- `~/.claude/scripts/pre_meeting_cron.sh` = The script to run
- `>> ~/.claude/logs/pre_meeting_cron.log 2>&1` = Log output (append)

**Save and exit:**
- **nano**: Press `Ctrl+O`, Enter, `Ctrl+X`
- **vim**: Press `Esc`, type `:wq`, press Enter

### Step 5: Verify Crontab is Set

Check that your cron job was added:

```bash
crontab -l
```

You should see:
```
*/10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

### Step 6: Monitor the First Few Runs

Watch the logs to verify it's working:

```bash
# Follow logs in real-time (Ctrl+C to exit)
tail -f ~/.claude/logs/pre_meeting_cron.log
```

Wait for the next 10-minute mark. You should see:
```
[HH:MM:SS] Pre-meeting briefing check started
[HH:MM:SS] Checking calendar for meetings in next 30 minutes...
[HH:MM:SS] No meetings found (or: Found meeting: XXX)
[HH:MM:SS] ✓ Check completed successfully
```

### Step 7: Check for Slack Messages

If there's a meeting in the next 30 minutes, you'll receive a Slack DM:

1. Open Slack
2. Check Direct Messages
3. Look for DM from yourself (or the Claude Code app)
4. Should show briefing with meeting details

**Example Slack message:**
```
📅 UPCOMING MEETING (in 15 minutes)

Team Standup
Time: 09:30
Attendees: 5 people

🔥 ACTION ITEMS (relevant to this meeting)
See full briefing in Claude Code with: /pre-meeting "Team Standup"

_Sent automatically by Claude Meeting Memory - Use /pre-meeting for full briefing_
```

## Configuration Options

### Change Frequency

The script runs every 10 minutes by default. To change:

**Every 5 minutes:**
```bash
*/5 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

**Every 15 minutes:**
```bash
*/15 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

**Every 30 minutes:**
```bash
*/30 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

### Business Hours Only

Only run during work hours (9am-6pm, weekdays):

```bash
*/10 9-17 * * 1-5 ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

### Specific Days

Only weekdays:
```bash
*/10 * * * 1-5 ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

Only Monday-Friday, 8am-8pm:
```bash
*/10 8-20 * * 1-5 ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

To update: `crontab -e` and modify the line.

## How It Works

### Every 10 Minutes

1. Cron runs the script
2. Script checks credentials are configured
3. Script queries Google Calendar API for events
4. Looks for meetings in next 30 minutes
5. If found, generates briefing with:
   - Meeting title, time, participants
   - Relevant action items from memory
   - Context from previous documents
6. Sends briefing via Slack DM
7. Logs the activity

### Cooldown (No Duplicates)

To avoid spam, the script has a 15-minute cooldown:
- If briefing for "Team Standup" was sent
- Won't send another "Team Standup" briefing for 15 minutes
- Different meetings are not affected

You can modify cooldown in the script:
```bash
BRIEFING_COOLDOWN_MINUTES=15  # Change to 5, 30, etc.
```

## Monitoring

### View Recent Activity

```bash
# Last 20 entries
tail -20 ~/.claude/logs/pre_meeting_cron.log

# Last 100 entries
tail -100 ~/.claude/logs/pre_meeting_cron.log

# Search for errors
grep ERROR ~/.claude/logs/pre_meeting_cron.log

# Follow in real-time
tail -f ~/.claude/logs/pre_meeting_cron.log
```

### Check System Cron Logs

**macOS:**
```bash
# View system log for cron
log stream --predicate 'process == "cron"' --level debug

# Or check old logs
cat /var/log/system.log | grep cron
```

**Linux:**
```bash
# View syslog
sudo tail -20 /var/log/syslog | grep CRON

# Or journalctl
sudo journalctl -u cron -n 20
```

### Log Rotation

The log file grows over time. Consider rotating it:

```bash
# Rotate logs weekly (add to crontab)
0 0 * * 0 gzip ~/.claude/logs/pre_meeting_cron.log && touch ~/.claude/logs/pre_meeting_cron.log
```

This compresses old logs every Sunday.

## Troubleshooting

### Cron Job Not Running

**Check crontab is set:**
```bash
crontab -l | grep pre_meeting
```

Should show the cron line.

**Check cron daemon is running:**
```bash
# macOS
launchctl list | grep cron

# Linux
systemctl is-active cron
```

**Check file permissions:**
```bash
ls -la ~/.claude/scripts/pre_meeting_cron.sh
```

Should be `-rwxr-xr-x` (executable).

### No Logs Being Created

**Check logs directory exists:**
```bash
ls -la ~/.claude/logs/
```

Create if missing:
```bash
mkdir -p ~/.claude/logs
chmod 700 ~/.claude/logs
```

**Check write permissions:**
```bash
touch ~/.claude/logs/test.txt && rm ~/.claude/logs/test.txt
```

If fails, fix permissions:
```bash
chmod 700 ~/.claude/logs
```

### Logs Show Errors

**"Google credentials not configured"**
- Run setup again: `bash ~/setup.sh`
- Or manually set credentials in Keychain

**"Slack credentials not configured"**
- Run setup again: `bash ~/setup.sh`
- Verify token is valid in Slack settings

**"Google API libraries not installed"**
```bash
pip3 install google-auth google-api-client google-auth-oauthlib
```

**"Failed to send Slack message"**
- Check Slack token is still valid
- Verify Member ID is correct
- Check Slack workspace status

### Slack Messages Not Arriving

**Check DM channel:**
- Open Slack
- Check Direct Messages section
- Messages might be in a separate DM with yourself

**Check message went out:**
```bash
grep "✓ Briefing sent" ~/.claude/logs/pre_meeting_cron.log
```

**Verify Slack credentials:**
```bash
# Test Slack token manually
curl -s https://slack.com/api/auth.test \
  -H "Authorization: Bearer XTOKEN" | grep -o '"ok":[a-z]*'
```

Should return: `"ok":true`

### Too Many Slack Messages

If you're receiving too many briefings:

**Increase check frequency:**
```bash
# Change from 10 min to 15 min
crontab -e
# Edit */10 to */15
```

**Increase cooldown:**
Edit the script:
```bash
nano ~/.claude/scripts/pre_meeting_cron.sh
# Change BRIEFING_COOLDOWN_MINUTES=15 to 30
```

**Only run during business hours:**
```bash
*/10 9-17 * * 1-5 ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

### Disable Temporarily

To pause briefings without removing crontab:

```bash
crontab -e
# Add # at start of line:
# */10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

To re-enable, remove the `#`.

## Disable Automation

To completely remove crontab job:

```bash
crontab -e
# Delete the line with pre_meeting_cron.sh
```

Or remove all cron jobs:
```bash
crontab -r
```

Verify it's removed:
```bash
crontab -l
# Should show: "no crontab for user" or be empty
```

## Best Practices

1. **Test manually first** - Run script before adding to crontab
2. **Monitor logs** - Check logs periodically, especially first week
3. **Use business hours** - Set frequency for when you actually work
4. **Keep credentials updated** - If tokens expire, update them
5. **Review briefings** - Use `/pre-meeting` for full context
6. **Rotate logs** - Compress old logs to save space

## Advanced Configuration

### Custom Pre-meeting Script

You can modify the script to:
- Change meeting detection logic
- Filter by calendar type
- Add custom Slack formatting
- Integrate with other tools

See `~/.claude/scripts/pre_meeting_cron.sh` for implementation details.

### Environment Variables

Set defaults in your shell profile:

```bash
# Add to ~/.bashrc or ~/.zshrc
export CLAUDE_HOME="$HOME/.claude"
export BRIEFING_COOLDOWN_MINUTES=15
```

## Getting Help

**Crontab issues:**
- See [Troubleshooting](#troubleshooting) above
- Check system cron logs

**Script issues:**
- Run `bash ~/.claude/scripts/pre_meeting_cron.sh` manually
- Check `~/.claude/logs/pre_meeting_cron.log`

**Google Calendar issues:**
- Verify OAuth is working: `bash ~/.claude/scripts/validate.sh`
- Check events exist in Google Calendar

**Slack issues:**
- Verify token in Slack: https://api.slack.com/apps
- Check Member ID is correct

## Summary

Automatic briefings are easy to set up:

1. ✓ Verify setup completed
2. ✓ Test script manually
3. ✓ Add to crontab
4. ✓ Monitor logs
5. ✓ Adjust as needed

Once running, you'll receive Slack briefings automatically before meetings!

---

**Version:** 1.0.0
**Last Updated:** March 2, 2026
