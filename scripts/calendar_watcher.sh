#!/bin/bash
################################################################################
# Calendar Watcher - Monitor Plann calendar for upcoming meetings
#
# Runs every 10 minutes to:
# 1. Check for meetings in the next 30 minutes
# 2. Extract meeting details (title, participants, time)
# 3. Store in a cache file for pre-meeting skill to use
# 4. Optionally notify user via Slack
#
# Requires: Plann CLI configured
# Schedule: */10 * * * * ~/.claude/scripts/calendar_watcher.sh
################################################################################

set -euo pipefail

# Configuration
CLAUDE_HOME="${HOME}/.claude"
MEMORY_DIR="${CLAUDE_HOME}/memory"
CACHE_DIR="${MEMORY_DIR}/.cache"
CALENDAR_CACHE="${CACHE_DIR}/upcoming_meetings.json"
PROCESSED_FILE="${CACHE_DIR}/processed_meetings.txt"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Logging
LOG_FILE="${CLAUDE_HOME}/logs/calendar_watcher.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

################################################################################
# Main Logic
################################################################################

main() {
    log_message "INFO" "Calendar watcher started"

    # Check if Plann is configured
    if ! command -v plann &> /dev/null; then
        log_message "WARN" "Plann CLI not found. Skipping calendar check."
        return 0
    fi

    # Get calendar list to check if configured
    if ! plann calendar list &> /dev/null; then
        log_message "WARN" "Plann not properly configured. No calendars available."
        return 0
    fi

    # Fetch upcoming meetings for next 30 minutes
    local now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local thirty_min_later=$(date -u -d '+30 minutes' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v+30M '+%Y-%m-%dT%H:%M:%SZ')

    log_message "INFO" "Checking for meetings between $now and $thirty_min_later"

    # Try to fetch upcoming events
    # Note: plann CLI output format may vary, adjust as needed
    local meetings_json=$(plann list --from "$now" --to "$thirty_min_later" 2>/dev/null || echo "[]")

    # Save to cache
    echo "$meetings_json" > "$CALENDAR_CACHE"
    log_message "INFO" "Calendar cache updated: $CALENDAR_CACHE"

    # Extract meeting titles from JSON and check if new
    if command -v jq &> /dev/null; then
        local new_meetings=$(echo "$meetings_json" | jq -r '.[] | .title' 2>/dev/null | sort -u || echo "")

        if [ -n "$new_meetings" ]; then
            while IFS= read -r meeting_title; do
                if [ -z "$meeting_title" ]; then
                    continue
                fi

                # Check if already processed
                if ! grep -q "^$meeting_title$" "$PROCESSED_FILE" 2>/dev/null; then
                    log_message "INFO" "New meeting detected: $meeting_title"

                    # Add to processed file
                    echo "$meeting_title" >> "$PROCESSED_FILE"

                    # Optional: Send Slack notification if configured
                    if [ -n "${SLACK_BOT_TOKEN:-}" ]; then
                        notify_slack_upcoming_meeting "$meeting_title"
                    fi
                fi
            done <<< "$new_meetings"
        fi
    fi

    log_message "INFO" "Calendar watcher completed successfully"
    return 0
}

################################################################################
# Slack Notification
################################################################################

notify_slack_upcoming_meeting() {
    local meeting_title="$1"
    local slack_user_id="${SLACK_DM_USER_ID:-U01DHE5U6MA}"

    # Get Slack token from settings
    local slack_token="${SLACK_BOT_TOKEN:-}"
    if [ -z "$slack_token" ]; then
        log_message "WARN" "SLACK_BOT_TOKEN not set. Skipping Slack notification."
        return 0
    fi

    # Prepare message
    local message="📅 Upcoming meeting in 30 minutes: *$meeting_title*"

    # Open DM channel and send message
    local channel_response=$(curl -s -X POST https://slack.com/api/conversations.open \
        -H "Authorization: Bearer $slack_token" \
        -H "Content-Type: application/json" \
        -d "{\"users\": \"$slack_user_id\"}")

    local channel_id=$(echo "$channel_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$channel_id" ]; then
        curl -s -X POST https://slack.com/api/chat.postMessage \
            -H "Authorization: Bearer $slack_token" \
            -H "Content-Type: application/json" \
            -d "{\"channel\": \"$channel_id\", \"text\": \"$message\"}" > /dev/null

        log_message "INFO" "Slack notification sent for meeting: $meeting_title"
    else
        log_message "WARN" "Could not open Slack DM channel"
    fi
}

################################################################################
# Cleanup old cache entries
################################################################################

cleanup_old_entries() {
    # Keep only last 100 processed meetings
    if [ -f "$PROCESSED_FILE" ]; then
        tail -100 "$PROCESSED_FILE" > "${PROCESSED_FILE}.tmp"
        mv "${PROCESSED_FILE}.tmp" "$PROCESSED_FILE"
    fi
}

# Cleanup
cleanup_old_entries

# Run main
main
exit 0
