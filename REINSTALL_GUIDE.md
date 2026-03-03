# Reinstall Guide - --reinstall Option

## When to Use --reinstall

Use the `--reinstall` option when you want to **completely reconfigure** your Claude Meeting Memory installation without manually deleting files.

### Common Use Cases

1. **Broken Installation** - Something went wrong and you want to start fresh
2. **Reconfigure Credentials** - Want to use different Google/Slack accounts
3. **Fix Missing Configuration** - Credentials got corrupted or lost
4. **Switch Workspaces** - Move to a different Slack workspace
5. **Clean Slate** - Remove everything and start over
6. **Update from Old Version** - Major version upgrade with new structure

## How to Reinstall

### Simple One-Command Reinstall

```bash
bash setup.sh --reinstall
```

Or if you just cloned the repo:

```bash
cd claude-meeting-memory
bash setup.sh --reinstall
```

### Step-by-Step

1. **Run the reinstall command**
   ```bash
   bash setup.sh --reinstall
   ```

2. **Review what will be deleted**
   ```
   ⚠️  This will remove:
     • ~/.claude/memory/ (except memoria_agente/perfil_usuario.md)
     • ~/.claude/skills/read-this
     • ~/.claude/skills/pre-meeting
     • ~/.claude/skills/remind-me
     • ~/.claude/scripts/ (helper scripts only)
     • ~/.claude/logs/
     • ~/.claude/claude.json (skills section only)
     • Keychain/Secret Service credentials
     • Crontab entry for pre_meeting_cron.sh
   ```

3. **Confirm with "y" when prompted**
   ```
   Continue with reinstall? (Y/n):
   ```

4. **Wait for cleanup to complete**
   ```
   ✓ Cleaned up memory files
   ✓ Removed old skills
   ✓ Removed old scripts
   ✓ Removed old logs
   ✓ Removed credentials from Keychain
   ✓ Removed crontab entry
   ```

5. **Setup begins automatically**
   ```
   Phase 1: Initial Checks & Welcome
   Phase 1.5: Installing Python Dependencies
   ...
   ```

6. **Follow normal setup flow**
   - Answer questions when prompted
   - Configure Google OAuth
   - Configure Slack (optional)
   - Done!

## What Gets Preserved

### Your User Profile ✅
```
~/.claude/memory/memoria_agente/perfil_usuario.md
```
Your profile (name, role, team, etc.) is **always preserved**.

### Other Local Files ✅
Any other files you created in `~/.claude/memory/` are preserved.

### External Services ✅
- Google account (unaffected)
- Slack workspace (unaffected)
- Cloud data (unaffected)

## What Gets Removed

### Memory Files ❌
- `action_points.md` (your action items)
- `MEMORY.md` (your daily notes)
- Daily memory files (memory_YYYY-MM-DD.md)

**Recovery:** You can restore from backups if you have them.

### Configuration ❌
- Keychain credentials (macOS)
- Secret Service credentials (Linux)
- Slack credentials
- Google OAuth tokens
- Crontab entry
- Logs

**Recovery:** Reconfigure during setup.

### Installation Files ❌
- Skills (read-this, pre-meeting, remind-me)
- Helper scripts
- Logs directory

**Recovery:** Reinstalled during setup.

## After Reinstall

### Immediate Next Steps

1. **Check your profile**
   ```bash
   cat ~/.claude/memory/memoria_agente/perfil_usuario.md
   ```
   Update if needed.

2. **Test the skills**
   ```bash
   /read-this https://docs.google.com/document/d/YOUR_DOC_ID/edit
   /pre-meeting
   /remind-me Test action point
   ```

3. **Check automation**
   ```bash
   crontab -l | grep pre_meeting_cron.sh
   ```
   Should show the crontab entry.

### Restore Your Memory

If you had important action points or notes:

1. **Check if you have backups**
   ```bash
   ls -la ~/.claude/memory/
   ```

2. **Restore from backups**
   ```bash
   cp ~/backup/action_points.md ~/.claude/memory/action_points.md
   ```

3. **Or manually recreate**
   ```bash
   nano ~/.claude/memory/action_points.md
   # Add your action points back
   ```

## Troubleshooting

### "Permission denied when removing credentials"

**Cause:** macOS Keychain permission issue

**Solution:**
```bash
# Try with sudo
sudo bash setup.sh --reinstall

# Or ignore the error and continue
# (credentials will just not be removed, old setup will overwrite them)
```

### "crontab -e: not found"

**Cause:** Your system doesn't have crontab

**Solution:**
- The reinstall will still work
- Automation won't be set up (manual setup needed)
- Rest of installation proceeds normally

### "Old files still exist after reinstall"

**Cause:** Permission or disk issue

**Solution:**
```bash
# Manual cleanup
rm -rf ~/.claude/memory/action_points.md
rm -rf ~/.claude/scripts/*.py
rm -rf ~/.claude/skills/read-this

# Then run setup again
bash setup.sh
```

### "Lost my action points!"

**Cause:** You didn't back them up before reinstall

**Solution:**
```bash
# Check if you have a backup
ls -la ~/Documents/claude-backup/

# If no backup, manually recreate from memory
# Or check your git history (if you committed to git)
```

## Advanced Options

### Reinstall Without User Confirmation

⚠️ **WARNING:** This will not prompt for confirmation!

```bash
# Not recommended - always confirm what will be deleted
# (This feature is not implemented - always use interactive mode)
bash setup.sh --reinstall --force  # NOT SUPPORTED
```

**Better approach:** Just run `bash setup.sh --reinstall` and answer "y" to confirm.

### Partial Reinstall

⚠️ **Not currently supported**

If you only want to reconfigure Google OAuth without removing Slack:

```bash
# Edit setup.sh and comment out Slack phase
nano setup.sh
# Comment out: phase_4_slack

# Then run normal setup (not --reinstall)
bash setup.sh
```

### Backup Before Reinstall

**Recommended:** Always back up before reinstalling

```bash
# Backup your memory
cp -r ~/.claude/memory ~/claude-memory-backup-$(date +%Y%m%d)

# Backup action points specifically
cp ~/.claude/memory/action_points.md ~/action-points-backup.md

# Then reinstall safely
bash setup.sh --reinstall
```

## FAQ

### Q: Will --reinstall delete my Google account?
**A:** No. Your Google account is unaffected. Only local credentials are removed.

### Q: Will it delete my Slack workspace?
**A:** No. Slack workspace is unaffected. Only local token is removed.

### Q: Can I undo --reinstall?
**A:** No, but you can restore from backups if you have them. Create backups before reinstalling!

### Q: How long does --reinstall take?
**A:** About 1 minute for cleanup + 5-10 minutes for full setup.

### Q: Does --reinstall preserve my profile?
**A:** Yes! Your profile (`perfil_usuario.md`) is always preserved.

### Q: What if I interrupt --reinstall?
**A:** Cleanup will stop. Some files might be partially deleted. You can:
1. Run again: `bash setup.sh --reinstall` to complete
2. Or manually clean up and run: `bash setup.sh`

### Q: Can I reinstall multiple times?
**A:** Yes! Each reinstall starts from scratch.

### Q: Is --reinstall safe?
**A:** Yes! It's safe because:
- Asks for confirmation first
- Shows what will be deleted
- Preserves your profile
- Only removes Claude Meeting Memory files
- Doesn't touch OS or other applications

## Examples

### Example 1: Fix Broken Installation

```bash
# Something broke and briefings aren't working
# Solution: Fresh start

bash setup.sh --reinstall

# Answer the prompts:
# > Continue with reinstall? (Y/n): y
# > Removing old installation...
# > Phase 1: Initial Checks...
# [Follow normal setup]

# Now briefings work again!
```

### Example 2: Switch Slack Workspace

```bash
# Currently using Workspace A, want to switch to Workspace B

bash setup.sh --reinstall

# When prompted for Slack:
# > Enter your Slack User Token: xoxp-...  (from Workspace B)
# > Enter your Slack Member ID: U...       (from Workspace B)

# Done! Now using Workspace B
```

### Example 3: Switch Google Account

```bash
# Currently using account@gmail.com, want to use newaccount@gmail.com

bash setup.sh --reinstall

# When prompted for Google OAuth:
# > Browser opens
# > Sign in with newaccount@gmail.com
# > Authorize
# > Refresh token saved

# Done! Now using newaccount@gmail.com
```

### Example 4: Backup and Reinstall

```bash
# Safe approach: always back up first

# 1. Backup everything
cp -r ~/.claude/memory ~/claude-backup-$(date +%Y%m%d-%H%M%S)

# 2. Reinstall
bash setup.sh --reinstall

# 3. If something goes wrong, restore
cp -r ~/claude-backup-20260303-120000/* ~/.claude/memory/
```

## Getting Help

If --reinstall doesn't work:

1. **Check logs**
   ```bash
   tail -100 ~/.claude/logs/pre_meeting_cron.log
   ```

2. **Run with verbose output**
   ```bash
   bash -x setup.sh --reinstall
   ```

3. **Open an issue**
   - https://github.com/uli6/claude-meeting-memory/issues
   - Include error messages and OS info

4. **Check documentation**
   - [SETUP_GUIDE.md](./SETUP_GUIDE.md)
   - [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)

---

**Last Updated:** March 3, 2026
**Version:** 1.0
**Repository:** https://github.com/uli6/claude-meeting-memory
