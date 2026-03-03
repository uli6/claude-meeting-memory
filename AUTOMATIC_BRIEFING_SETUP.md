# Automatic Briefing Setup - The Smart Feature

## What's New

When you successfully configure Google OAuth during setup, Claude Meeting Memory **automatically** enables automatic meeting briefing checks. No manual crontab configuration needed!

---

## How It Works

### 1. During Setup
```
Phase 4: Google OAuth Configuration
✓ Google credentials saved successfully

Phase 4.5: Automatic Meeting Briefing Automation
✓ Automatic briefing automation enabled!

Meeting briefings will be sent to Slack every 10 minutes if:
  • There's a meeting in the next 30 minutes
  • You have Slack Member ID configured
```

### 2. After Setup
- Crontab entry automatically added (if successful)
- Logs automatically created at `~/.claude/logs/`
- Meeting checks run every 10 minutes
- Briefings sent to your Slack 30 minutes before meetings

### 3. What Actually Happens
```bash
# This is automatically added to your crontab:
*/10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

Every 10 minutes:
1. Script checks your Google Calendar for next 30 minutes
2. If there's a meeting coming up, reads your memory files
3. Generates briefing with:
   - Active pending items relevant to that meeting
   - Historical context from your memory
4. Sends briefing to your Slack DM (if Slack Member ID configured)

---

## Behavior

### When Briefings Are Sent

**Briefing sent to Slack if all these are true:**
- ✅ Google OAuth is configured
- ✅ There's a meeting in the next 30 minutes
- ✅ The meeting has participants (not a solo block)
- ✅ The meeting isn't marked "Unavailable"
- ✅ Slack Member ID is configured
- ✅ This briefing wasn't sent in the last 15 minutes (prevents duplicates)

**Briefing NOT sent if:**
- ❌ No meeting in next 30 minutes
- ❌ Meeting marked "Unavailable"
- ❌ No Slack Member ID configured
- ❌ Google Calendar access fails
- ❌ Slack token invalid

### What's In the Briefing

```
🔥 PENDING (Active Items):
- [ ] Complete API design review
- [ ] Finalize database schema

📚 CONTEXT:
- Project Alpha is in design phase
- Team velocity: 8 points/sprint
- Next deadline: March 15

✅ Great! You're prepared for this meeting.
```

---

## Monitoring

### View Briefing Logs

```bash
# See latest briefing attempts
tail -f ~/.claude/logs/pre_meeting_cron.log

# See specific briefing (replace with your filename)
cat ~/.claude/logs/pre_meeting_cron.log | grep "Meeting: Team Sync"

# Count how many briefings were sent today
grep "Briefing sent" ~/.claude/logs/pre_meeting_cron.log | wc -l
```

### Example Log Output

```
[2026-03-03 09:00:00] ════════════════════════════════════════════════════
[2026-03-03 09:00:00] Pre-meeting briefing check started
[2026-03-03 09:00:05] Found meeting: Team Sync (in 25 minutes)
[2026-03-03 09:00:07] Generating briefing...
[2026-03-03 09:00:10] Sending briefing to Slack DM...
[2026-03-03 09:00:12] Briefing sent via Slack.
[2026-03-03 09:00:12] Check completed successfully
```

---

## Control

### Disable Briefing Automation

**If you don't want automatic briefings:**

```bash
# Edit your crontab
crontab -e

# Find this line and delete it:
*/10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1

# Save and exit
```

### Re-enable Briefing Automation

**To turn it back on:**

```bash
# Edit your crontab
crontab -e

# Add this line:
*/10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1

# Save and exit
```

Or just re-run setup and configure Google OAuth again.

### Modify Check Frequency

**Want briefings every 5 minutes instead of 10?**

```bash
crontab -e

# Change from:
*/10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1

# To:
*/5 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

---

## Troubleshooting

### "Briefing never arrives"

**Check these in order:**

1. **Is automation running?**
   ```bash
   crontab -l | grep pre_meeting_cron.sh
   ```
   If no output, crontab wasn't set up. Re-run setup or add manually.

2. **Check logs for errors**
   ```bash
   tail -20 ~/.claude/logs/pre_meeting_cron.log
   ```
   Look for ERROR messages.

3. **Is Google configured?**
   ```bash
   ~/.claude/scripts/get_secret.sh google-refresh-token
   ```
   Should output a token. If empty, Google isn't configured.

4. **Is Slack Member ID set?**
   ```bash
   ~/.claude/scripts/get_secret.sh slack-member-id
   ```
   Should output `U...` format. If empty, Slack ID missing.

5. **Do you have meetings?**
   Check your Google Calendar - is there a meeting in the next 30 minutes?

### "Too many briefings (spam)"

**Cause:** Crontab entry duplicated
**Solution:**
```bash
crontab -e
# Remove duplicate lines
```

### "Crontab setup failed during setup.sh"

**Common causes:**
- Your system doesn't support crontab (unusual)
- Permission issues

**Solution:** Add manually
```bash
crontab -e
# Add: */10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
```

---

## Advanced Customization

### Change Briefing Time Window

**Currently:** Briefing sent for meetings in next 30 minutes
**To change:** Edit `pre_meeting_cron.sh`

```bash
nano ~/.claude/scripts/pre_meeting_cron.sh

# Find: MEETING_WINDOW_MINUTES=30
# Change to: MEETING_WINDOW_MINUTES=60  (for 60-minute window)
```

### Add Custom Message to Briefings

Edit `pre_meeting_cron.sh` and customize the Slack message format.

### Send Briefings to a Channel Instead

**Currently:** Briefings sent to your personal Slack DM
**To change:** Would require modifying `pre_meeting_cron.sh`

Ask for help on GitHub Discussions.

---

## Why Automatic?

### Benefits

1. **Zero Setup** - Just say "yes" to Google OAuth
2. **Immediate** - Briefings working the moment setup finishes
3. **Seamless** - No additional configuration needed
4. **Discoverable** - User sees what happened during setup
5. **Easy to Disable** - One `crontab -e` away from off

### Safety

- ✅ Only reads from Google/Slack (no modifications)
- ✅ Only writes to local `~/.claude/logs/`
- ✅ Can be easily disabled
- ✅ Respects "Unavailable" day blocks
- ✅ Prevents duplicate briefings

---

## Questions?

- **How do I see all briefings?** `tail -f ~/.claude/logs/pre_meeting_cron.log`
- **Can I turn it off?** Yes, `crontab -e` and delete the line
- **Can I change the frequency?** Yes, edit the `*/10` to `*/5` or whatever
- **What if cron fails?** Check logs and re-run setup
- **How much does this cost?** Nothing - uses your Google/Slack accounts

---

**Last Updated:** March 3, 2026
**Version:** 1.0 (Automatic Setup Feature)
**Repository:** https://github.com/uli6/claude-meeting-memory
