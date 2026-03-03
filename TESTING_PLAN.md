# Testing Plan - Claude Meeting Memory System

**Date:** March 3, 2026
**Status:** IN PROGRESS
**Objective:** Validate complete Himalaya/Plann migration with end-to-end testing

---

## Test Environment Setup

### Prerequisites
- macOS system with bash
- Himalaya CLI (will be installed during setup)
- Plann CLI (will be installed during setup)
- Email account (Gmail, ProtonMail, or other IMAP)
- Optional: CalDAV server (Nextcloud, Radicale, FastMail, etc.)

---

## Phase 1: Setup Script Validation

### Test 1.1: Fresh Installation (No Previous Config)
**Objective:** Verify setup.sh runs completely on fresh system

**Steps:**
1. [ ] Backup existing ~/.claude directory (if exists)
2. [ ] Remove ~/.claude directory completely
3. [ ] Run: `bash setup.sh`
4. [ ] Follow prompts for:
   - [ ] Phase 1: Environment checks
   - [ ] Phase 2: Directory creation
   - [ ] Phase 3: Himalaya setup with provider selection
   - [ ] Phase 3.5: Plann optional setup
   - [ ] Phase 4: Slack integration (optional)
   - [ ] Phase 5-9: Skills, templates, validation

**Expected Results:**
- [ ] All phases complete without errors
- [ ] ~/.claude directory structure created
- [ ] Himalaya configured and working
- [ ] Optional: Plann configured and working
- [ ] Skills registered
- [ ] Cron job installed (if Plann succeeded)
- [ ] Setup summary displayed with success message

---

### Test 1.2: Provider Selection (Himalaya)
**Objective:** Verify guided provider setup works correctly

**Provider Test Cases:**
- [ ] Gmail setup
  - [ ] Shows Gmail-specific instructions
  - [ ] Links to https://myaccount.google.com/apppasswords
  - [ ] Accepts Gmail address and app password
  - [ ] Himalaya validates successfully

- [ ] ProtonMail setup
  - [ ] Shows ProtonMail-specific instructions
  - [ ] Links to app password generation
  - [ ] Accepts credentials
  - [ ] Himalaya validates successfully

- [ ] Fastmail setup
  - [ ] Shows Fastmail-specific instructions
  - [ ] Accepts credentials
  - [ ] Himalaya validates successfully

- [ ] Outlook setup
  - [ ] Shows Outlook-specific instructions
  - [ ] Accepts credentials
  - [ ] Himalaya validates successfully

- [ ] Other IMAP server
  - [ ] Accepts custom server details
  - [ ] Accepts credentials
  - [ ] Himalaya validates successfully

**Expected Results:**
- [ ] Correct guidance shown for each provider
- [ ] Provider-specific URLs are accurate
- [ ] User can successfully configure email account
- [ ] Himalaya envelope list works post-setup

---

### Test 1.3: Provider Selection (Plann - Optional)
**Objective:** Verify optional Plann setup flow

**Scenarios:**
- [ ] User skips Plann setup ("n" response)
  - [ ] No cron job installed
  - [ ] System continues to Phase 4
  - [ ] Validation passes (Plann is optional)

- [ ] User enables Plann setup ("y" response)
  - [ ] Provider selection displayed
  - [ ] Provider-specific instructions shown

  **Provider Test Cases:**
  - [ ] Nextcloud setup
    - [ ] Shows CalDAV URL format guidance
    - [ ] Accepts credentials
    - [ ] Plann validates successfully

  - [ ] Radicale setup
    - [ ] Shows Radicale-specific instructions
    - [ ] Accepts credentials
    - [ ] Plann validates successfully

  - [ ] FastMail setup
    - [ ] Shows FastMail CalDAV URL
    - [ ] Accepts credentials
    - [ ] Plann validates successfully

  - [ ] Other CalDAV server
    - [ ] Accepts custom server details
    - [ ] Plann validates successfully

**Expected Results:**
- [ ] User can skip Plann without issues
- [ ] User can configure Plann successfully
- [ ] Cron job installed ONLY if Plann validates
- [ ] Cron job points to correct script path
- [ ] Cron schedule is */10 * * * *

---

### Test 1.4: Cron Job Installation
**Objective:** Verify cron setup when Plann succeeds

**Steps:**
1. [ ] During setup, select a CalDAV provider and configure successfully
2. [ ] Setup completes
3. [ ] Check crontab: `crontab -l`

**Expected Results:**
- [ ] Crontab contains "Calendar Watcher" comment
- [ ] Crontab contains: `*/10 * * * * ~/.claude/scripts/calendar_watcher.sh >> /dev/null 2>&1`
- [ ] Script file exists and is executable: `ls -la ~/.claude/scripts/calendar_watcher.sh`
- [ ] Cron job did NOT install if Plann validation failed

---

### Test 1.5: Validation Phase
**Objective:** Verify setup validation checks

**Expected Checks:**
- [ ] Himalaya installation verified
- [ ] Himalaya configuration checked
- [ ] Optional: Plann installation verified (if configured)
- [ ] Optional: Plann configuration checked (if configured)
- [ ] ~/.claude directory structure validated
- [ ] Cron job validated (if Plann configured)
- [ ] Message shown: "Setup completed successfully!"

---

## Phase 2: Himalaya Integration Tests

### Test 2.1: Email Enumeration
**Objective:** Verify Himalaya can list emails correctly

**Steps:**
1. [ ] Run: `himalaya envelope list --limit 10`

**Expected Results:**
- [ ] List of recent emails displayed
- [ ] Email format shows: uid | subject | from | date
- [ ] At least some emails from configured account
- [ ] Command completes in < 5 seconds

---

### Test 2.2: Email Body Reading
**Objective:** Verify Himalaya can read email content

**Steps:**
1. [ ] Get a UID from `himalaya envelope list`
2. [ ] Run: `himalaya read <uid>`

**Expected Results:**
- [ ] Email body displayed
- [ ] Headers shown: From, To, Subject, Date
- [ ] Body preview readable
- [ ] Command completes in < 2 seconds

---

### Test 2.3: Email Search (by Subject)
**Objective:** Verify email filtering works for meeting prep

**Steps:**
1. [ ] Find an email with a clear subject (e.g., "Team Meeting", "Project Review")
2. [ ] Run: `himalaya envelope list --limit 50 | grep -i "meeting"`

**Expected Results:**
- [ ] Emails with "meeting" in subject shown
- [ ] Can filter by various keywords
- [ ] Useful for meeting briefing context

---

## Phase 3: Plann Integration Tests (If Configured)

### Test 3.1: Calendar Enumeration
**Objective:** Verify Plann can list calendars

**Steps:**
1. [ ] Run: `plann calendar list`

**Expected Results:**
- [ ] List of configured calendars shown
- [ ] At least one calendar visible
- [ ] Command completes in < 2 seconds

---

### Test 3.2: Meeting Enumeration
**Objective:** Verify Plann can fetch upcoming meetings

**Steps:**
1. [ ] Run: `plann list --from "2026-03-03T14:00:00Z" --to "2026-03-03T15:00:00Z"`

**Expected Results:**
- [ ] JSON output with meetings (or empty array if no meetings)
- [ ] Format includes: id, title, start, end, participants
- [ ] Command completes in < 3 seconds

---

### Test 3.3: Calendar Watcher Script Manual Test
**Objective:** Verify calendar_watcher.sh runs correctly

**Steps:**
1. [ ] Run: `bash ~/.claude/scripts/calendar_watcher.sh`
2. [ ] Check logs: `cat ~/.claude/logs/calendar_watcher.log | tail -20`

**Expected Results:**
- [ ] Script completes without errors (exit code 0)
- [ ] Log entries show:
  - [ ] "Calendar watcher started"
  - [ ] "Checking for meetings between [time1] and [time2]"
  - [ ] "Calendar cache updated: ~/.claude/memory/.cache/upcoming_meetings.json"
  - [ ] "Calendar watcher completed successfully"
- [ ] Cache file created: `cat ~/.claude/memory/.cache/upcoming_meetings.json | python -m json.tool`
- [ ] Cache contains valid JSON (even if empty array)

---

### Test 3.4: Cron Job Execution
**Objective:** Verify cron runs calendar_watcher.sh automatically

**Steps:**
1. [ ] Wait 10 minutes OR manually trigger cron entry: `bash ~/.claude/scripts/calendar_watcher.sh`
2. [ ] Check logs: `tail -f ~/.claude/logs/calendar_watcher.log`
3. [ ] Verify cache updated: `ls -la ~/.claude/memory/.cache/upcoming_meetings.json`

**Expected Results:**
- [ ] New log entries appear every 10 minutes
- [ ] Cache file timestamp updates
- [ ] No error messages in logs
- [ ] Cron job runs without user intervention

---

### Test 3.5: Deduplication Logic
**Objective:** Verify meeting deduplication works

**Steps:**
1. [ ] Create a meeting in calendar (e.g., "Test Meeting - Do Not Delete")
2. [ ] Wait for it to appear in next 30-minute window
3. [ ] Run: `bash ~/.claude/scripts/calendar_watcher.sh` twice within 10 minutes
4. [ ] Check: `cat ~/.claude/memory/.cache/processed_meetings.txt`

**Expected Results:**
- [ ] Meeting title appears in processed_meetings.txt only once
- [ ] Second run doesn't create duplicate entry
- [ ] Log shows "New meeting detected" only once

---

## Phase 4: Pre-Meeting Skill Tests

### Test 4.1: Skill Invocation
**Objective:** Verify /pre-meeting skill works

**Steps:**
1. [ ] In Claude Code, type: `/pre-meeting "Team Standup"`
2. [ ] Skill should ask for participants if not provided
3. [ ] Skill should gather context

**Expected Results:**
- [ ] Skill invokes successfully
- [ ] Asks for meeting title (if not provided)
- [ ] Asks for participants (optional)
- [ ] Processing message shown

---

### Test 4.2: Email Context Integration
**Objective:** Verify emails are included in briefing

**Steps:**
1. [ ] Ensure Himalaya is configured with some emails
2. [ ] Create a meeting or use an existing one with relevant emails
3. [ ] Run: `/pre-meeting "Sales Review"`
4. [ ] In Claude context (or check scripts), verify emails were fetched

**Expected Results:**
- [ ] Briefing includes "📧 EMAIL CONTEXT" section
- [ ] Relevant emails shown (if found)
- [ ] Email subject, sender, date visible
- [ ] If no emails found: "No related emails found" shown gracefully

---

### Test 4.3: Memory File Integration
**Objective:** Verify memory files are read correctly

**Steps:**
1. [ ] Ensure action_points.md has some pending items
2. [ ] Run: `/pre-meeting "Team Meeting"`

**Expected Results:**
- [ ] Briefing includes "🔥 ACTIVE PENDING ITEMS" section
- [ ] Pending items relevant to meeting shown
- [ ] If no relevant items: "No active pending items" shown
- [ ] Briefing includes "📚 HISTORICAL CONTEXT" section

---

### Test 4.4: Full Briefing Format
**Objective:** Verify complete briefing output

**Steps:**
1. [ ] Run `/pre-meeting` with a meeting title

**Expected Results:**
- [ ] Briefing contains all three sections:
  ```
  🔥 ACTIVE PENDING ITEMS:
  [items or "No active pending items"]

  📚 HISTORICAL CONTEXT:
  [context from memory]

  📧 EMAIL CONTEXT:
  [emails or "No related emails found"]
  ```
- [ ] Briefing is formatted clearly
- [ ] Metadata shown: meeting title, participants, timestamp

---

### Test 4.5: Graceful Degradation
**Objective:** Verify skill works even if components missing

**Scenarios:**
- [ ] Himalaya not configured
  - [ ] Briefing still works with memory files only
  - [ ] Warning logged
  - [ ] No error shown to user

- [ ] No emails found
  - [ ] Briefing still works with memory files
  - [ ] "No related emails found" shown
  - [ ] No error

- [ ] Memory files missing
  - [ ] Briefing still works with emails
  - [ ] "Not found" or empty sections shown gracefully
  - [ ] No error

- [ ] No Himalaya, no Plann, only memory
  - [ ] Briefing works perfectly with just memory
  - [ ] All sections shown (emails empty, context from memory)

**Expected Results:**
- [ ] System ALWAYS produces a briefing
- [ ] No errors in any scenario
- [ ] Degradation is transparent to user

---

## Phase 5: Integration Tests

### Test 5.1: Complete Workflow
**Objective:** Test full user journey from setup to briefing

**Steps:**
1. [ ] Run setup.sh
   - [ ] Configure Himalaya with real email account
   - [ ] Configure Plann with real calendar (or skip)
   - [ ] Complete all phases
2. [ ] Verify cron job (if Plann configured)
   - [ ] `crontab -l` shows calendar watcher
3. [ ] Run calendar watcher manually
   - [ ] `bash ~/.claude/scripts/calendar_watcher.sh`
   - [ ] Check logs
4. [ ] Request meeting briefing
   - [ ] `/pre-meeting "Your actual upcoming meeting"`
   - [ ] Review briefing output

**Expected Results:**
- [ ] All phases complete successfully
- [ ] Emails displayed in briefing
- [ ] Calendar integration works (if Plann configured)
- [ ] No errors throughout
- [ ] User has useful context for meeting

---

### Test 5.2: Multi-Provider Workflow
**Objective:** Test with different email/calendar combinations

**Test Cases:**
- [ ] Gmail + Nextcloud
- [ ] ProtonMail + Radicale
- [ ] Fastmail (email + calendar)
- [ ] Outlook + no calendar

**Expected Results:**
- [ ] All combinations work without issues
- [ ] No provider-specific errors
- [ ] Graceful fallback if components unavailable

---

## Phase 6: Edge Cases & Error Handling

### Test 6.1: Network Failures
**Steps:**
1. [ ] Temporarily disconnect from internet
2. [ ] Run: `bash ~/.claude/scripts/calendar_watcher.sh`
3. [ ] Reconnect and check logs

**Expected Results:**
- [ ] Script completes with return code 0 (success)
- [ ] Log shows warning about network/connection
- [ ] No error exit code
- [ ] System recovers on next run

---

### Test 6.2: Invalid Credentials
**Steps:**
1. [ ] Edit ~/.config/himalaya/config.toml with wrong password
2. [ ] Run: `himalaya envelope list`
3. [ ] Run: `/pre-meeting` skill

**Expected Results:**
- [ ] Himalaya returns error
- [ ] Skill handles gracefully
- [ ] Briefing shown without emails (memory only)
- [ ] Clear error message about Himalaya

---

### Test 6.3: Missing CLI Tools
**Steps:**
1. [ ] Uninstall Himalaya: `brew uninstall himalaya`
2. [ ] Run: `/pre-meeting` skill
3. [ ] Run calendar watcher: `bash ~/.claude/scripts/calendar_watcher.sh`

**Expected Results:**
- [ ] Skill works with memory only
- [ ] Calendar watcher logs warning and exits with 0
- [ ] No system failure
- [ ] User can reinstall and continue

---

### Test 6.4: Large Cache Files
**Steps:**
1. [ ] Manually add 200+ entries to ~/.claude/memory/.cache/processed_meetings.txt
2. [ ] Run: `bash ~/.claude/scripts/calendar_watcher.sh`
3. [ ] Check file size: `wc -l ~/.claude/memory/.cache/processed_meetings.txt`

**Expected Results:**
- [ ] File trimmed to 100 entries
- [ ] Cleanup completed successfully
- [ ] No performance issues
- [ ] Log shows cleanup

---

## Phase 7: Performance & Resource Tests

### Test 7.1: Response Time
**Objective:** Verify system meets performance requirements

**Measurements:**
- [ ] `himalaya envelope list --limit 50` completes in < 5 seconds
- [ ] Email search filters < 2 seconds
- [ ] Memory file reading < 2 seconds
- [ ] Full briefing generation < 10 seconds
- [ ] Calendar watcher script < 2 seconds

**Expected Results:**
- [ ] All operations meet targets
- [ ] System feels responsive to user

---

### Test 7.2: Resource Usage
**Objective:** Verify reasonable CPU/memory usage

**Checks:**
- [ ] Calendar watcher uses < 5% CPU per run
- [ ] Memory peak < 50 MB
- [ ] Cache files < 10 KB
- [ ] Processed meetings file < 2 KB

**Expected Results:**
- [ ] No resource waste
- [ ] Suitable for regular cron execution

---

## Test Results Summary

### Himalaya Tests
- [ ] Test 2.1: Email enumeration - **PASS/FAIL**
- [ ] Test 2.2: Email body reading - **PASS/FAIL**
- [ ] Test 2.3: Email search - **PASS/FAIL**

### Plann Tests (If Applicable)
- [ ] Test 3.1: Calendar enumeration - **PASS/FAIL**
- [ ] Test 3.2: Meeting enumeration - **PASS/FAIL**
- [ ] Test 3.3: Calendar watcher manual - **PASS/FAIL**
- [ ] Test 3.4: Cron job execution - **PASS/FAIL**
- [ ] Test 3.5: Deduplication logic - **PASS/FAIL**

### Setup Tests
- [ ] Test 1.1: Fresh installation - **PASS/FAIL**
- [ ] Test 1.2: Provider selection (Himalaya) - **PASS/FAIL**
- [ ] Test 1.3: Provider selection (Plann) - **PASS/FAIL**
- [ ] Test 1.4: Cron job installation - **PASS/FAIL**
- [ ] Test 1.5: Validation phase - **PASS/FAIL**

### Skill Tests
- [ ] Test 4.1: Skill invocation - **PASS/FAIL**
- [ ] Test 4.2: Email context - **PASS/FAIL**
- [ ] Test 4.3: Memory integration - **PASS/FAIL**
- [ ] Test 4.4: Full briefing format - **PASS/FAIL**
- [ ] Test 4.5: Graceful degradation - **PASS/FAIL**

### Integration Tests
- [ ] Test 5.1: Complete workflow - **PASS/FAIL**
- [ ] Test 5.2: Multi-provider - **PASS/FAIL**

### Edge Cases
- [ ] Test 6.1: Network failures - **PASS/FAIL**
- [ ] Test 6.2: Invalid credentials - **PASS/FAIL**
- [ ] Test 6.3: Missing CLI tools - **PASS/FAIL**
- [ ] Test 6.4: Large cache files - **PASS/FAIL**

### Performance Tests
- [ ] Test 7.1: Response times - **PASS/FAIL**
- [ ] Test 7.2: Resource usage - **PASS/FAIL**

---

## Issues Found & Fixes

### Critical Issues
*(None found yet - to be filled during testing)*

### Warnings
*(None found yet - to be filled during testing)*

### Enhancements
*(None found yet - to be filled during testing)*

---

## Sign-Off

**Testing Started:** 2026-03-03
**Testing Completed:** [TBD]
**Tester:** Claude Code
**Result:** [TBD - PASS/FAIL]
**Notes:** [TBD]
