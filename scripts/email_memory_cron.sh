#!/bin/bash

################################################################################
# email_memory_cron.sh - Email Memory Automation via Crontab
#
# Runs every 10 minutes to:
#   1. Fetch new emails from Gmail
#   2. Process with Gemini AI
#   3. Extract key information
#   4. Save to memory system
#   5. Update action points
#
# Installation:
#   crontab -e
#   # Add: */10 * * * * ~/.claude/scripts/email_memory_cron.sh >> ~/.claude/logs/email_memory.log 2>&1
#
# Requirements:
#   - Gmail API credentials
#   - Gemini API key
#   - email_config.json in ~/.claude/config/
#   - email_memory_processor.py in ~/.claude/scripts/
################################################################################

set -euo pipefail

# Configuration
CLAUDE_HOME="${HOME}/.claude"
SCRIPTS_DIR="${CLAUDE_HOME}/scripts"
LOGS_DIR="${CLAUDE_HOME}/logs"
CONFIG_FILE="${CLAUDE_HOME}/config/email_config.json"

# Create logs directory if needed
mkdir -p "$LOGS_DIR"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGS_DIR/email_memory.log"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >> "$LOGS_DIR/email_memory.log"
}

# Main function
main() {
    log "════════════════════════════════════════════════════════════════"
    log "Email Memory Automation started"

    # Check if config exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file not found: $CONFIG_FILE"
        log "Email Memory Automation failed"
        exit 1
    fi

    # Check if Python script exists
    if [[ ! -f "${SCRIPTS_DIR}/email_memory_processor.py" ]]; then
        log_error "Python script not found: ${SCRIPTS_DIR}/email_memory_processor.py"
        log "Email Memory Automation failed"
        exit 1
    fi

    # Check if enabled in config
    local email_enabled=$(grep -o '"enabled": true' "$CONFIG_FILE" | head -1 || echo "")
    if [[ -z "$email_enabled" ]]; then
        log "Email automation is disabled in config"
        exit 0
    fi

    # Run Python processor
    if python3 "${SCRIPTS_DIR}/email_memory_processor.py" 2>&1 | while read -r line; do
        log "$line"
    done; then
        log "Email Memory Automation completed successfully"
    else
        log_error "Email Memory Automation failed"
        exit 1
    fi
}

# Run main
main "$@"
