# Slack Handle Requirement in Phase 7.5

**Date:** March 3, 2026
**Status:** ✅ IMPLEMENTED

---

## Overview

If a user configures Slack integration during Phase 4 of the setup, the **Slack Handle becomes REQUIRED** in Phase 7.5 (User Profile Setup).

This ensures that:
1. Users who enable Slack can receive meeting briefings via direct message
2. The system has the necessary information to send DMs (`/pre-meeting` skill)
3. Setup fails gracefully if critical information is missing

---

## Logic Flow

```
Phase 4: Slack Configuration
    ↓
    Is Slack token saved? (checks Keychain/Secret Service)
    ├─ YES → Slack is configured
    │
    └─ NO → Slack is not configured
         ↓
Phase 7.5: User Profile Setup
    ↓
    Does Slack token exist in Keychain?
    ├─ YES → Slack Handle is REQUIRED
    │         User will be re-prompted if empty
    │
    └─ NO → Slack Handle is OPTIONAL
            User can skip or leave empty
```

---

## User Experience Examples

### Scenario 1: User Configured Slack (Slack Handle is REQUIRED)

```
Phase 7.5: User Profile Setup
════════════════════════════════════════════════════════════

ℹ  Your profile helps generate better meeting briefings.
You can:
  • Fill it now (2-3 minutes)
  • Skip and fill it later with: nano ~/.claude/memory/memoria_agente/perfil_usuario.md

Do you want to fill your profile now? (Y/n): y

ℹ  Let's gather some basic information about you.

👤 Full name (or nickname): João Silva
💼 Your job title/role: Product Manager
👥 Your team/department: Product Team
📧 Your email (optional): joao.silva@company.com

ℹ  Slack integration is configured.
ℹ  Your Slack handle is required to send meeting briefings via direct message.

💬 Slack handle (e.g., @seu.username): @joao.silva

✓ Profile saved!
ℹ  Your profile has been created with the information you provided.
```

### Scenario 2: User Did NOT Configure Slack (Slack Handle is OPTIONAL)

```
Phase 7.5: User Profile Setup
════════════════════════════════════════════════════════════

ℹ  Your profile helps generate better meeting briefings.
You can:
  • Fill it now (2-3 minutes)
  • Skip and fill it later with: nano ~/.claude/memory/memoria_agente/perfil_usuario.md

Do you want to fill your profile now? (Y/n): y

ℹ  Let's gather some basic information about you.

👤 Full name (or nickname): Maria Santos
💼 Your job title/role: Software Engineer
👥 Your team/department: Backend Team
📧 Your email (optional):
💬 Slack handle (e.g., @seu.username) (optional):

✓ Profile saved!
ℹ  Your profile has been created with the information you provided.
```

### Scenario 3: User Configured Slack but Doesn't Provide Handle (Re-prompt)

```
Phase 7.5: User Profile Setup
════════════════════════════════════════════════════════════

[... filling profile fields ...]

ℹ  Slack integration is configured.
ℹ  Your Slack handle is required to send meeting briefings via direct message.

💬 Slack handle (e.g., @seu.username): [user leaves empty and presses Enter]

⚠  Slack handle is required for meeting briefings
💬 Slack handle (e.g., @seu.username): @user.handle

✓ Profile saved!
```

---

## Technical Implementation

### How Phase 7.5 Detects Slack Configuration

The code checks both macOS and Linux keychain locations:

```bash
# Check if Slack token exists (was configured in Phase 4)
local slack_token_exists=false
if command -v security &> /dev/null; then
    if security find-generic-password -a "$USER" -s "claude-code-slack-user-token" &>/dev/null; then
        slack_token_exists=true
    fi
elif command -v secret-tool &> /dev/null; then
    if secret-tool lookup slack-user-token &>/dev/null; then
        slack_token_exists=true
    fi
fi
```

### Conditional Requirement Logic

```bash
if [[ "$slack_token_exists" == true ]]; then
    # Slack is configured - Slack Handle is REQUIRED
    print_info "Slack integration is configured."
    print_info "Your Slack handle is required to send meeting briefings via direct message."

    slack_handle=$(read_input "💬 Slack handle (e.g., @seu.username)")

    # Re-prompt if empty
    while [[ -z "$slack_handle" ]]; do
        print_warning "Slack handle is required for meeting briefings"
        slack_handle=$(read_input "💬 Slack handle (e.g., @seu.username)")
    done
else
    # Slack not configured - Slack Handle is optional
    slack_handle=$(read_input "💬 Slack handle (e.g., @seu.username) (optional)")
fi
```

---

## Why This Matters

### For Users Who Use Slack
- ✅ They **must** provide their Slack handle
- ✅ Meeting briefings can be delivered via DM
- ✅ No surprises during later usage

### For Users Who Don't Use Slack
- ✅ They can skip Slack Handle entirely
- ✅ No unnecessary required fields
- ✅ Profile remains flexible and optional

### For Users Who Skip Profile Setup
- ✅ They can skip Phase 7.5 entirely
- ✅ Fill it later manually with `nano`
- ✅ Or reconfigure if they add Slack later

---

## What Happens After Setup

### User Profile is Created: `~/.claude/memory/memoria_agente/perfil_usuario.md`

**If Slack configured and handle provided:**
```markdown
# Seu Perfil - Memória do Agente

## 👤 Informações Pessoais

**Nome Completo:** João Silva

**Cargo/Título:** Product Manager

**Time/Departamento:** Product Team

**Email:** joao.silva@company.com

**Slack Handle:** @joao.silva
```

**If Slack not configured:**
```markdown
# Seu Perfil - Memória do Agente

## 👤 Informações Pessoais

**Nome Completo:** Maria Santos

**Cargo/Título:** Software Engineer

**Team/Departamento:** Backend Team

**Email:** [Seu email profissional]

**Slack Handle:** @seu.username
```

---

## User Can Update Anytime

If the user made a mistake or needs to update their profile later:

```bash
nano ~/.claude/memory/memoria_agente/perfil_usuario.md
```

They can manually edit:
- Slack handle
- Any other profile information
- Add or remove information as needed

---

## Integration with Skills

### Pre-Meeting Skill Uses Slack Handle

When the `/pre-meeting` skill runs and tries to send a meeting briefing:

1. Reads the Slack token from Keychain
2. Reads the Slack handle from `perfil_usuario.md`
3. Sends briefing via DM to that Slack handle

If Slack handle is missing/invalid:
- Skill will fail with clear error message
- User can fix in profile and retry

---

## Error Handling During Setup

If user tries to skip Phase 7.5 after Slack is configured:

```
Phase 7.5: User Profile Setup
════════════════════════════════════════════════════════════

Do you want to fill your profile now? (Y/n): n

⚠  Skipping profile setup
You can fill it later with:
  nano ~/.claude/memory/memoria_agente/perfil_usuario.md

[User skips]

[Later, when trying to use /pre-meeting with Slack]

⚠  Error: Slack handle not found in profile
  To enable meeting briefings via Slack DM:
    nano ~/.claude/memory/memoria_agente/perfil_usuario.md
    Add your Slack handle: @seu.username
```

---

## Summary

| Scenario | Slack Handle | Status |
|----------|--------------|--------|
| Slack configured, user fills profile | Provided | ✅ Ready to send briefings |
| Slack configured, user skips profile | Missing | ⚠️  Will fail when sending |
| Slack not configured, user fills profile | Optional | ✅ Can add later |
| Slack not configured, user skips profile | Missing | ✅ Not needed |

---

## Commit History

- **80085a5** - "Enforce Slack handle requirement if Slack token is configured"
  - Phase 7.5 now checks if Slack token exists
  - Slack handle becomes required if Slack is configured
  - Re-prompt if user leaves it empty

---

**Status:** ✅ IMPLEMENTED AND TESTED
**Repository:** https://github.com/uli6/claude-meeting-memory
