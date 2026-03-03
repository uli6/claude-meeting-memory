# Project Scope - Claude Meeting Memory

## What IS Included

### Core Features
- ✅ **Automated Setup** - One-command installation of Claude Code integration
- ✅ **Google Integration** - Read-only access to Google Drive and Calendar
- ✅ **Slack Integration** - Read and create action points from Slack
- ✅ **Memory System** - Local files for tracking context and action items
- ✅ **Three Skills**
  - `/read-this` - Read documents and summarize
  - `/pre-meeting` - Generate meeting briefings
  - `/remind-me` - Track action items
- ✅ **Secure Credential Management** - Keychain/Secret Service storage
- ✅ **Validation and Testing** - Automatic post-setup validation
- ✅ **Complete Documentation** - Guides, FAQs, troubleshooting
- ✅ **Crontab Automation** - Optional automatic briefing scheduling

### Supported Platforms
- ✅ **macOS** - Native support with Apple Keychain
- ✅ **Linux** - Native support with GNOME/KDE Secret Service
- ✅ **Git Bash on Windows** - Community support (not officially tested)

---

## What IS NOT Included

### Explicitly Out of Scope

#### 1. **Notion Integration**
- ❌ **NOT included:** Syncing memory to Notion
- ❌ **NOT included:** Reading from Notion databases
- ❌ **NOT included:** sync-notion-memory.sh script
- **Reason:** Out of scope. Use Claude Code's `/read-this` to manually read Notion docs.

#### 2. **1Password / Secret Management Systems**
- ❌ **NOT included:** 1Password integration
- ❌ **NOT included:** OpenClaw orchestration
- ❌ **NOT included:** Service account authentication
- **Reason:** This project uses native OS keychains instead.

#### 3. **Alternative Cloud Storage**
- ❌ **NOT included:** Dropbox sync
- ❌ **NOT included:** OneDrive sync
- ❌ **NOT included:** iCloud sync
- **Reason:** Memory is local-only by design.

#### 4. **Advanced Email Processing**
- ❌ **NOT included:** Smart email categorization
- ❌ **NOT included:** Automated email responses
- ❌ **NOT included:** Email forwarding
- **Reason:** Out of scope (read-only Gmail access only).

#### 5. **Multiple Workspace Support**
- ❌ **NOT included:** Multi-Google account support
- ❌ **NOT included:** Multi-Slack workspace support
- **Reason:** Single-user, single-workspace design.

#### 6. **Advanced Analytics**
- ❌ **NOT included:** Meeting statistics
- ❌ **NOT included:** Productivity metrics
- ❌ **NOT included:** Time tracking
- **Reason:** Memory and briefing generation only.

#### 7. **Real-Time Synchronization**
- ❌ **NOT included:** Cloud sync of memory files
- ❌ **NOT included:** Real-time collaboration
- ❌ **NOT included:** Device sync
- **Reason:** Local-only by design.

#### 8. **Custom Integrations**
- ❌ **NOT included:** Zapier/IFTTT integration
- ❌ **NOT included:** API for external apps
- ❌ **NOT included:** Webhook support
- **Reason:** Beyond project scope.

#### 9. **AI-Powered Features**
- ❌ **NOT included:** Automatic action detection
- ❌ **NOT included:** Smart suggestion engine
- ❌ **NOT included:** Sentiment analysis
- ❌ **NOT included:** Custom AI models
- **Reason:** Uses Claude API through Claude Code only.

#### 10. **GUI / Web Interface**
- ❌ **NOT included:** Web dashboard
- ❌ **NOT included:** Desktop application
- ❌ **NOT included:** Mobile app
- **Reason:** CLI-based design using Claude Code.

---

## Design Principles

### 1. **Local First**
- All data stored locally in `~/.claude/memory/`
- No cloud storage or backup
- User has full control

### 2. **Simple & Focused**
- Three core skills only
- No bloat or feature creep
- Easy to understand and use

### 3. **Privacy by Default**
- Credentials stored in OS keychain
- No external services involved
- Transparent about what's shared

### 4. **Security Over Convenience**
- Manual setup for integrations
- Explicit permission disclosure
- User can revoke anytime

### 5. **No Autonomous Actions**
- System never acts without permission
- Read-only from external services
- Only writes to local memory

---

## Future Possibilities (Not Planned)

These are NOT currently planned, but could be considered in future versions if there's user demand:

- **Cloud Sync** - Optional encrypted backup to cloud storage
- **Team Features** - Shared briefings or memory (new version)
- **Mobile App** - Access memory from phone
- **Custom Triggers** - Beyond /read-this, /pre-meeting, /remind-me
- **Plugin System** - Allow third-party extensions

---

## How to Request Features

If you want features outside this scope, please:

1. **Check GitHub Issues** - Maybe someone already asked
2. **Open a Discussion** - Ask if it's planned
3. **Create a Feature Request** - Describe your use case
4. **Be Specific** - Explain why you need it

We evaluate requests based on:
- Alignment with project philosophy (local, simple, secure)
- User demand
- Complexity to implement
- Maintenance burden

---

## What to Use Instead

### For Notion Sync
- Use `/read-this` to manually read Notion docs
- Copy important context to memory files
- Or: Use official Notion + Claude integration

### For Cloud Sync
- Use `iCloud Drive` or `Dropbox` to sync `~/.claude/memory/` directory
- Or: Keep memory local, export manually as needed

### For Advanced AI
- Use Claude Code's built-in capabilities
- Or: Build custom scripts using Claude API

### For Multiple Workspaces
- Create separate Claude Code installations
- Or: Use different GitHub accounts

### For Real-Time Collaboration
- Use Notion, Google Docs, or Slack directly
- Or: Export memory and share manually

---

## Contributing

We welcome contributions that:
- ✅ Improve existing features
- ✅ Fix bugs
- ✅ Enhance documentation
- ✅ Improve security
- ✅ Optimize performance

We ask for discussion first if you want to:
- ❌ Add new skills (should extend existing ones)
- ❌ Integrate new services (should be optional)
- ❌ Change memory storage (should remain local)
- ❌ Add cloud features (against project philosophy)

---

## License

MIT License - Use, modify, and distribute freely, but acknowledge the original.

See [LICENSE](./LICENSE) for details.

---

## Questions?

- **README.md** - Project overview
- **QUICK_START.md** - Getting started
- **docs/TROUBLESHOOTING.md** - Common issues
- **GitHub Issues** - Report problems
- **GitHub Discussions** - Ask questions

---

**Last Updated:** March 3, 2026
**Version:** 1.0
**Repository:** https://github.com/uli6/claude-meeting-memory
