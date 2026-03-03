# Stdin/TTY Fix - Interactive Input in Piped Scripts

## Problem

When `setup.sh` was executed via pipe command:

```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

The script would skip all interactive configuration phases (Google OAuth, Slack, user profile) and immediately display "Setup Completed Successfully".

### Root Cause

When a bash script is piped from `curl`, stdin is consumed by the pipe itself. The script's `read` commands (used in `ask_yes_no()` and `read_input()`) would:

1. Attempt to read from stdin
2. Find no data (stdin is empty after script is loaded)
3. Return immediately with empty input
4. Use default values (all "yes" for prompts like "Configure Google OAuth?")

This caused the script to execute all phases with default behavior, skipping the interactive configuration steps.

## Solution

Modified `ask_yes_no()` and `read_input()` functions to read from `/dev/tty` (the terminal) when available, instead of stdin.

### How It Works

```bash
ask_yes_no() {
    # ... prompt code ...

    # Read from /dev/tty if available (allows input even when piped)
    # Fall back to stdin if /dev/tty not available
    if [[ -t 0 ]] || [[ -c /dev/tty ]]; then
        read -r response </dev/tty || response=""
    else
        read -r response || response=""
    fi

    # ... rest of function ...
}
```

**Key mechanisms:**

1. **`[[ -t 0 ]]`** - Tests if stdin (file descriptor 0) is connected to a terminal
2. **`[[ -c /dev/tty ]]`** - Tests if `/dev/tty` exists and is a character device
3. **`read -r response </dev/tty`** - Explicitly reads from the terminal device
4. **`|| response=""`** - Fallback: sets empty string if read fails

### Benefits

- ✅ Interactive prompts work when script is piped: `curl | bash`
- ✅ Interactive prompts work when script is run directly: `bash setup.sh`
- ✅ Works in non-interactive environments (CI/CD) - uses defaults
- ✅ Maintains backward compatibility
- ✅ Better user experience across all execution methods

## Affected Functions

### 1. `ask_yes_no()`
- **Purpose**: Yes/no prompts throughout setup
- **Prompts**: "Continue with setup?", "Configure Google OAuth?", etc.
- **Impact**: Now works correctly when piped

### 2. `read_input()`
- **Purpose**: Read user input (with optional masking for passwords)
- **Prompts**: Google credentials, Slack token, etc.
- **Impact**: Now works correctly when piped

## Testing

### Test Scenario 1: Piped Execution
```bash
# This should now prompt for input (not skip to summary)
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

### Test Scenario 2: Direct Execution
```bash
# This should still work as before
bash setup.sh
```

### Test Scenario 3: Non-Interactive (CI/CD)
```bash
# Should use defaults, no hanging on prompts
echo "n" | bash setup.sh  # Skip Google OAuth
```

## Technical Details

### `/dev/tty` Behavior

- **Available**: When running in an interactive terminal
  - `curl | bash` → **Has /dev/tty** (terminal is still available)
  - `bash setup.sh` → **Has /dev/tty**
  - SSH session → **Has /dev/tty**

- **Not Available**: Non-interactive environments
  - Cron jobs
  - GitHub Actions / CI pipelines
  - Piped without terminal: `setup.sh < /dev/null`
  - Background processes

### Fallback Behavior

When `/dev/tty` is not available:
- `read` command falls back to stdin
- Empty input triggers default value
- Script continues without hanging

## Implementation Details

The fix adds TTY-aware input reading to two core functions:

```bash
# Pattern used in both functions
if [[ -t 0 ]] || [[ -c /dev/tty ]]; then
    read -r response </dev/tty || response=""
else
    read -r response || response=""
fi
```

This pattern:
1. Checks if stdin is a terminal (`-t 0`)
2. Checks if `/dev/tty` device exists (`-c /dev/tty`)
3. Reads from `/dev/tty` if available
4. Falls back to stdin if not available
5. Sets empty string if read fails (prevents hanging)

## Related Issues

- **GitHub Issue**: User reported "Setup Completed Successfully without prompting for configuration"
- **Affected Version**: 1.0.0 with interactive guided setup
- **Fixed In**: Commit `3c4578f`

## Files Modified

- `setup.sh` - Lines 208-262 (ask_yes_no and read_input functions)

## Validation

After this fix, users should see:

```
╔══════════════════════════════════════════════════════════════╗
║          Claude Meeting Memory - Onboarding Setup           ║
╚══════════════════════════════════════════════════════════════╝

[Phase 1: Initial Checks...]
[Phase 1.5: Python Dependencies...]
[Phase 2: Creating Directory Structure...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONFIGURATION PHASE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configure Google OAuth? (Y/n): ← Interactive prompt appears here
```

**Before the fix**: This prompt would not appear.
**After the fix**: This prompt appears correctly, regardless of how the script is executed.

## Resources

- [Bash read command documentation](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#index-read)
- [File descriptors in Bash](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)
- [/dev/tty special file](https://man7.org/linux/man-pages/man4/tty.4.html)

---

**Version**: 1.0.0
**Fix Date**: March 3, 2026
**Status**: ✅ Implemented and Deployed
**Testing**: Ready for user validation
