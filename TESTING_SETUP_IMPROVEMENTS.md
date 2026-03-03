# Testing Guide: Setup.sh Improvements

## Quick Start

### Run Interactive Setup (Short Mode)
```bash
bash setup.sh
```

This will guide you through the full setup with all the new improvements.

### Test Specific Phases

#### Phase 1: System Check
```bash
bash setup.sh
# At "Continue with setup?" - Choose 'y'
# Should show: Phase 1 of 9, system requirements check
```

#### Phase 3: Email Setup
```bash
bash setup.sh
# Skip to Phase 3
# Select Gmail (option 1)
# You should see:
#   - Step-by-step guide with clear formatting
#   - Help text explaining "App Password"
#   - Simplified prompts
```

#### Phase 4: Calendar Setup
```bash
bash setup.sh
# Skip to Phase 3.5
# Select option 1 (Nextcloud)
# You should see:
#   - Calendar providers with descriptions
#   - Help text for Nextcloud
```

#### Phase 5: Slack Setup
```bash
bash setup.sh
# Skip to Phase 4 (Slack)
# When asked about token, select 'n' (don't have one)
# You should see:
#   - Condensed 2-minute guide
#   - Clear step numbering (STEP 1, STEP 2, etc.)
#   - Direct links to Slack API
```

## What to Look For

### Progress Indicators ✅

**In every phase header, you should see:**
```
┌─────────────────────────────────────────┐
│ Phase 3 of 9: Email Configuration       │
│ Time: ~3-5 minutes                      │
│                                         │
│ Progress: ████░░░░░░ 33%               │
└─────────────────────────────────────────┘
```

**Verification:**
- [ ] Phase numbers increment (1, 2, 3, ...)
- [ ] Progress bar fills as you advance
- [ ] Percentage updates correctly
- [ ] Time estimates are shown

### Help Text ✅

**When setting up Gmail, you should see:**
```
💡 What's App Password?
   A special password just for this app - safer than using your real password
```

**Check these help topics:**
- [ ] "App Password" (during Gmail setup)
- [ ] "Nextcloud" (during Nextcloud calendar setup)
- [ ] "User Token" (during Slack setup)
- [ ] "Member ID" (during Slack setup)

### Simplified Provider Selection ✅

**Email Providers should show:**
```
Which email service do you use?

  1) Gmail                (most popular)
  2) ProtonMail           (encrypted, privacy-focused)
  3) Fastmail             (privacy-friendly, supports IMAP)
  4) Outlook/Microsoft    (work email)
  5) Other email service  (any IMAP-compatible service)
```

**Verification:**
- [ ] Each provider has a brief description
- [ ] Descriptions are non-technical
- [ ] You can understand what each one is

### Calendar Providers ✅

**Should show:**
```
What calendar service do you use?

  1) Nextcloud            (personal cloud)
  2) Radicale             (self-hosted calendar)
  3) FastMail             (email with calendar)
  4) Other CalDAV service (any CalDAV-compatible)
```

### Step-by-Step Guides ✅

**For Gmail setup:**
```
Gmail: Create App Password
────────────────────────────────────────────
  1. Go to: https://myaccount.google.com/apppasswords
  2. Select 'Mail' and 'Windows Computer' (or your device)
  3. Click 'Generate'
  4. Copy the 16-character password shown (don't include spaces)
```

**Verification:**
- [ ] Steps are numbered clearly
- [ ] URLs are clickable (if terminal supports it)
- [ ] Instructions are straightforward
- [ ] No jargon without explanation

### Slack Setup Simplification ✅

**Old version:** 7+ detailed steps
**New version:** Should show ~2-minute condensed guide

```
STEP 1: Go to Slack API
STEP 2: Create New App
STEP 3: Add Permissions
...etc
```

**Verification:**
- [ ] Guide is noticeably shorter than before
- [ ] Steps are clearly numbered
- [ ] No unnecessary details
- [ ] Token format explanation is clear

### Requirement Clarity ✅

**At the start, you should see:**
```
┌──────────────────────────────────────────┐
│ What's Required vs Optional              │
├──────────────────────────────────────────┤
│ ✓ REQUIRED (for meeting briefings):      │
│   • Email access (Himalaya)              │
│   • Calendar access (Plann)              │
│                                          │
│ ◆ RECOMMENDED (for Slack notifications): │
│   • Slack integration                    │
│                                          │
│ ◇ OPTIONAL (personalization):            │
│   • Your profile information             │
└──────────────────────────────────────────┘
```

### Time Estimates ✅

**Each phase should show estimated time:**
- Phase 1: ~1 minute
- Phase 2: ~1 minute
- Phase 3 (Email): ~3-5 minutes
- Phase 4 (Calendar): ~3-5 minutes
- Phase 5 (Slack): ~5-7 minutes
- Phase 6 (Security): ~1 minute
- Phase 7 (Skills): ~2 minutes
- Phase 8 (Templates): ~1 minute
- Phase 9 (Validation): ~1 minute

**Total should be:** ~20-25 minutes

## Non-Technical User Test

### Scenario: First-Time User with Gmail

**Setup:**
1. User has Gmail account
2. User has never used terminal apps before
3. User wants to complete setup without getting lost

**Steps to Test:**
1. Run `bash setup.sh`
2. User should understand:
   - What each phase does
   - Why it's needed
   - How long it will take
   - What information to provide
3. At each prompt, user should:
   - See clear instructions
   - Know exactly what to do
   - Not feel overwhelmed by jargon

**Success Criteria:**
- [ ] User completes setup without asking for clarification
- [ ] User doesn't get confused by technical terms
- [ ] User understands Email and Calendar are required
- [ ] User knows Slack is optional
- [ ] Setup takes roughly 20-25 minutes as promised

## Known Issues to Watch For

### 1. Helper Functions Not Loading
**Symptom:** `show_phase_header: command not found`
**Cause:** `setup_helpers.sh` not in scripts directory
**Fix:** Ensure `scripts/setup_helpers.sh` exists

### 2. Progress Bar Display Issues
**Symptom:** Progress bar shows strange characters
**Cause:** Terminal doesn't support Unicode
**Workaround:** Should still be readable, fallback to ASCII

### 3. Colors Not Showing
**Symptom:** No colored output
**Cause:** Terminal doesn't support ANSI colors
**Workaround:** Script still works, just no colors

## Regression Testing

### Essential Functionality to Verify

- [ ] Himalaya email setup still works
- [ ] Plann calendar setup still works
- [ ] Slack token validation still works
- [ ] Credentials are stored securely (Keychain/Secret Service)
- [ ] Skills are registered in claude.json
- [ ] Directory structure is created correctly
- [ ] Template files are generated
- [ ] reinstall flag removes old files

### Before/After Comparison

**Should work the same:**
- Credential management
- Installation paths
- Error handling
- Recovery mechanisms

**Should be improved:**
- User experience
- Clarity of instructions
- Time to complete
- User understanding

## Quick Verification Checklist

Run through this before considering setup complete:

```
PHASE HEADERS:
✓ Phase numbers show (1 of 9, 2 of 9, etc.)
✓ Time estimates shown
✓ Progress bar visible and updating

SIMPLIFIED MESSAGING:
✓ Email phase says "connect your email"
✓ Calendar phase says "automatic meeting detection"
✓ Slack phase says "meeting reminders"

HELP TEXT:
✓ Help prompts show for technical terms
✓ Explanations are non-technical
✓ Users understand what's needed

SLACK IMPROVEMENTS:
✓ Setup guide is concise (~2 minutes)
✓ Steps are clearly numbered
✓ Member ID section simplified
✓ Token format clearly explained

REQUIREMENTS CLARITY:
✓ Welcome shows Required vs Optional
✓ Email + Calendar marked as REQUIRED
✓ Slack marked as RECOMMENDED
✓ Profile marked as OPTIONAL

FUNCTIONALITY:
✓ All features still work
✓ Credentials stored securely
✓ No errors during setup
```

## Performance Notes

Setup should take approximately:
- Non-technical user: 25-30 minutes (may pause to follow URLs)
- Technical user: 15-20 minutes (knows how to get credentials quickly)
- Power user: 10-15 minutes (has credentials ready)

## Questions to Ask Test Users

After completing setup:

1. "Did you understand what each phase was doing?"
2. "Did you know which steps were required vs. optional?"
3. "Were the instructions clear enough to follow?"
4. "Did the time estimates match what you experienced?"
5. "Were there any technical terms that confused you?"
6. "Would you recommend this setup to a non-technical friend?"
7. "What could be improved?"

## Files Modified

- `setup.sh` - Main setup script (phase headers, messaging)
- `scripts/setup_helpers.sh` - New helper functions file

## Notes

- All changes are backward compatible
- Helper functions gracefully degrade if not found
- No changes to core functionality
- Original behavior preserved
