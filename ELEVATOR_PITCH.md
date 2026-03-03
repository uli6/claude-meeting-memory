# Claude Meeting Memory - Elevator Pitch

## 30-Second Version

**Claude Meeting Memory** is an automated onboarding system that turns Claude Code into a productivity powerhouse in **one command**.

```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

**What you get:**
- ✅ Automatic setup (5 minutes)
- ✅ 3 productivity skills ready to use
- ✅ Meeting briefing automation
- ✅ Secure credential management
- ✅ Complete documentation

**Perfect for:** Anyone using Claude Code who wants to stay organized, prepared, and productive.

---

## 2-Minute Version

### Problem
Setting up Claude Code to work with Google Drive, Calendar, and Slack requires:
- Manual directory creation
- Google OAuth configuration
- Slack token setup
- Skill registration
- Memory system initialization

This takes 30+ minutes and is error-prone.

### Solution
**Claude Meeting Memory** automates everything with:

1. **One-Command Installation**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
   ```

2. **Three Ready-to-Use Skills**
   - **`/read-this`** - Read Google Docs and save summaries to memory
   - **`/pre-meeting`** - Generate meeting briefings with context
   - **`/remind-me`** - Create action points from Slack messages

3. **Secure Credential Management**
   - macOS: Apple Keychain
   - Linux: GNOME/KDE Secret Service
   - Fallback: OpenSSL AES-256 encryption
   - Transparent security disclosure

4. **Complete Documentation**
   - 5-minute quick start
   - Detailed setup guide
   - Troubleshooting and FAQs
   - How-to for every feature

### Results
- **5 minutes** from zero to fully configured
- **10 interactive phases** with clear guidance
- **Automatic validation** to confirm everything works
- **3 productive skills** immediately available
- **100% transparent** about security and permissions

---

## 5-Minute Version (Feature Overview)

### Who Is This For?

✅ **For you if:**
- You use Claude Code for work
- You want to integrate Google Drive, Calendar, and Slack
- You care about security and privacy
- You want to streamline your workflow

❌ **Not for you if:**
- You don't use Claude Code
- You prefer manual configuration
- You work offline without Google/Slack

### What You Get

#### Installation Phase (2 minutes)
1. System requirements check
2. Python package installation
3. Directory structure creation
4. Google OAuth (browser auto-opens)
5. Slack token configuration (optional)
6. Security review and approval
7. Skill registration
8. Template file creation
9. Comprehensive validation
10. Success summary

#### Three Production-Ready Skills

**1. `/read-this` - Document Reader**
```
/read-this https://docs.google.com/document/d/YOUR_DOC_ID/edit
```
- Reads Google Docs you have access to
- Extracts key information
- Saves summaries to your memory
- Useful for: Capturing context, avoiding re-reading

**2. `/pre-meeting` - Meeting Briefer**
```
/pre-meeting
```
- Reads your calendar
- Checks your action items
- Reviews your memory context
- Generates meeting briefing with:
  - Active pending items
  - Historical context
  - Relevant people/projects
- Useful for: Staying prepared, seeming attentive

**3. `/remind-me` - Action Tracker**
```
/remind-me Complete project report by Friday
/remind-me https://slack.com/archives/.../123
```
- Creates action items from text or Slack
- Tracks status
- Stores in memory for later review
- Useful for: Capturing commitments, following up

#### Memory System

Automatic memory files:
- **action_points.md** - Your current action items
- **MEMORY.md** - Daily notes and context
- **memoria_agente/** - Detailed context files
  - perfil_usuario.md - Your profile
  - Project files, team context, etc.

#### Security

✅ **What it does:**
- Read from Google Drive, Calendar, Slack (read-only)
- Write to your local memory files
- Store credentials securely
- Encrypt sensitive data

❌ **What it NEVER does:**
- Send credentials to external services
- Perform actions without permission
- Delete or modify your documents
- Send messages on your behalf (except briefing to you)

**Storage:**
- macOS: Apple Keychain (encrypted by OS)
- Linux: GNOME/KDE Secret Service
- Fallback: AES-256 encrypted local file

---

## Quick Comparison

### Before Claude Meeting Memory
```
Manual Setup Checklist:
□ Create ~/.claude/memory directories
□ Create ~/.claude/scripts directory
□ Create ~/.claude/skills directory
□ Get Google OAuth credentials (Google Cloud Console)
□ Authorize Google OAuth (browser flow)
□ Get Slack user token (Slack API)
□ Configure secrets storage
□ Copy skill files
□ Register skills in claude.json
□ Create template memory files
□ Test everything works

Time: 30-45 minutes
Error rate: High
```

### After Claude Meeting Memory
```
$ curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash

Time: 5 minutes
Error rate: Minimal (automatic validation)
Everything tested and working ✓
```

---

## Success Metrics

After setup, you'll be able to:

✅ Read and summarize documents in 10 seconds
✅ Get briefed for any meeting in 30 seconds
✅ Create action items from Slack messages in 5 seconds
✅ Search your memory for context anytime
✅ Automate briefings every 10 minutes (optional)
✅ Build a searchable knowledge base of your work

---

## Real-World Examples

### Example 1: Preparing for a Team Meeting
```
You: /pre-meeting
System:
  ✓ Checking calendar for Team Sync (in 10 min)
  ✓ Reading pending action items (3 items)
  ✓ Gathering context about recent projects

Briefing:
  🔥 PENDING (Active Items):
  - [ ] John: Complete API design review
  - [ ] Sarah: Finalize database schema
  - [ ] You: Prepare project timeline

  📚 CONTEXT:
  - Project Alpha is in design phase
  - Team velocity: 8 points/sprint
  - Next deadline: March 15

You: "Perfect, I'm ready!"
```

### Example 2: Capturing an Idea
```
You: /remind-me Check the new dashboard metrics for performance issues

System: Added to action_points.md
  - [ ] Check the new dashboard metrics for performance issues

Later, when reviewing:
You: cat ~/.claude/memory/action_points.md
  - [ ] Check the new dashboard metrics for performance issues
```

### Example 3: Building Context
```
You: /read-this https://docs.google.com/document/d/ABC123/edit

System:
  ✓ Reading document: "Q1 2026 Strategy"
  ✓ Extracting key points
  ✓ Saving to memory/memoria_agente/strategy_q1_2026.md

Next meeting, briefing includes:
  "Based on Q1 Strategy document (read on March 3):
   - Focus on customer retention
   - Launch 3 new features
   - Reduce support costs by 20%"
```

---

## Getting Started

### Step 1: Install (1 command)
```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### Step 2: Fill Your Profile (2 minutes)
```bash
nano ~/.claude/memory/memoria_agente/perfil_usuario.md
```

### Step 3: Test (3 minutes)
```bash
/read-this [your google doc]
/pre-meeting
/remind-me [your action item]
```

### Step 4: Use Daily (30 seconds each)
```bash
# Morning: Get briefed
/pre-meeting

# During meetings: Track action items
/remind-me [important commitment]

# Anytime: Save documents
/read-this [google doc link]
```

---

## Why Choose Claude Meeting Memory?

### 🚀 Speed
- 5-minute setup (vs 45 minutes manual)
- Automatic validation
- Immediate productivity

### 🔒 Security
- Credentials in OS keychain
- No cloud storage
- Transparent privacy
- User full control

### 📚 Documentation
- Quick start guide
- Detailed troubleshooting
- Complete API guide
- Real-world examples

### 🎯 Purpose-Built
- Designed for Claude Code
- Integrates Google/Slack/Calendar
- Meeting-focused features
- Memory system included

### 💰 Free
- Open source (MIT)
- No subscriptions
- No API costs (uses Claude Code auth)

---

## FAQ

**Q: Do I need a Google account?**
A: Yes, for using `/read-this` and briefing context.

**Q: Is Slack required?**
A: No, it's optional. You can use the skills without it.

**Q: Will it break my existing setup?**
A: No, it only adds files. Your existing Claude Code setup stays intact.

**Q: How much does it cost?**
A: It's free. You only need your Google and Slack accounts.

**Q: Is it safe?**
A: Yes. See [SAFETY_GUARANTEE.md](./SAFETY_GUARANTEE.md) for complete details.

**Q: Can I uninstall it?**
A: Yes, just delete the files and credentials (instructions in docs).

---

## Next Steps

### 🚀 Ready to Try?

**Install now:**
```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### 📖 Want to Learn More?

**Quick Start (5 min):**
→ [QUICK_START.md](./QUICK_START.md)

**Full Guide (15 min):**
→ [SETUP_GUIDE.md](./SETUP_GUIDE.md)

**Security Details:**
→ [SAFETY_GUARANTEE.md](./SAFETY_GUARANTEE.md)

### 💬 Have Questions?

**GitHub Issues:** https://github.com/uli6/claude-meeting-memory/issues
**GitHub Discussions:** https://github.com/uli6/claude-meeting-memory/discussions

---

## Share This

**Tell a friend:**
```
Check out Claude Meeting Memory - it automates Claude Code setup with Google/Slack integration:
https://github.com/uli6/claude-meeting-memory
```

**Tweet:**
```
Just discovered Claude Meeting Memory - one-command setup for Claude Code with Google Drive, Calendar, and Slack integration.

5-minute install. 3 productivity skills. Secure credential management.

https://github.com/uli6/claude-meeting-memory
```

---

**Version:** 2.0 (Claude Code Integration)
**Last Updated:** March 3, 2026
**Repository:** https://github.com/uli6/claude-meeting-memory
