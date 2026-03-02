#!/bin/bash

################################################################################
# pre_meeting_cron.sh - Automatic Meeting Briefing via Crontab
#
# Runs every 10 minutes (via crontab) to check for meetings in next 30 minutes
# and sends Slack briefings automatically
#
# Installation:
#   crontab -e
#   # Add: */10 * * * * ~/.claude/scripts/pre_meeting_cron.sh >> ~/.claude/logs/pre_meeting_cron.log 2>&1
#
# Note: Ensure this runs after setup.sh completes (Google OAuth + Slack config)
################################################################################

set -euo pipefail

# Configuration
CLAUDE_HOME="${HOME}/.claude"
MEMORY_DIR="${CLAUDE_HOME}/memory"
SCRIPTS_DIR="${CLAUDE_HOME}/scripts"
LOGS_DIR="${CLAUDE_HOME}/logs"
LAST_CHECK_FILE="${CLAUDE_HOME}/.last_meeting_check"
BRIEFING_COOLDOWN_MINUTES=15  # Don't send same briefing twice within this window

# Create logs directory if needed
mkdir -p "$LOGS_DIR"

# Logging helper
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGS_DIR/pre_meeting_cron.log"
}

# Error logging
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >> "$LOGS_DIR/pre_meeting_cron.log"
}

log "════════════════════════════════════════════════════════════════"
log "Pre-meeting briefing check started"

################################################################################
# Helper Functions
################################################################################

# Get secret from keychain/encrypted storage
get_secret() {
    local key="$1"

    # Try to get from bash script helper
    if [[ -f "$SCRIPTS_DIR/get_secret.sh" ]]; then
        "$SCRIPTS_DIR/get_secret.sh" "$key" 2>/dev/null || true
    fi
}

# Check if we should skip this check (cooldown)
should_send_briefing() {
    local meeting_id="$1"

    if [[ ! -f "$LAST_CHECK_FILE" ]]; then
        return 0  # No last check, send
    fi

    local last_send_time=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "0")
    local now=$(date +%s)
    local time_diff=$((now - last_send_time))

    # Don't send if less than cooldown minutes passed
    if [[ $time_diff -lt $((BRIEFING_COOLDOWN_MINUTES * 60)) ]]; then
        log "Skipping (cooldown active: ${time_diff}s / $((BRIEFING_COOLDOWN_MINUTES * 60))s)"
        return 1
    fi

    return 0
}

# Mark when briefing was sent
mark_briefing_sent() {
    echo "$(date +%s)" > "$LAST_CHECK_FILE"
}

################################################################################
# Get Next Meeting from Google Calendar
################################################################################

get_next_meeting() {
    # This function queries Google Calendar API for the next event
    # within 30 minutes from now

    python3 << 'PYTHON_SCRIPT'
import os
import sys
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, os.path.expanduser("~/.claude/scripts"))

try:
    from secrets_helper import get_secret
except ImportError:
    print("ERROR: secrets_helper.py not found", file=sys.stderr)
    sys.exit(1)

try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from googleapiclient.discovery import build
except ImportError:
    print("ERROR: Google API libraries not installed", file=sys.stderr)
    print("Install with: pip3 install google-auth-oauthlib google-api-client", file=sys.stderr)
    sys.exit(1)

def get_google_calendar_service():
    """Create and return Google Calendar service with refresh token"""

    try:
        # Get stored refresh token
        refresh_token = get_secret("google-refresh-token")
        client_id = get_secret("google-client-id")
        client_secret = get_secret("google-client-secret")

        if not all([refresh_token, client_id, client_secret]):
            print("ERROR: Missing Google credentials", file=sys.stderr)
            return None

        # Create credentials from refresh token
        creds = Credentials(
            token=None,
            refresh_token=refresh_token,
            token_uri="https://oauth2.googleapis.com/token",
            client_id=client_id,
            client_secret=client_secret
        )

        # Refresh to get valid access token
        creds.refresh(Request())

        # Build service
        service = build('calendar', 'v3', credentials=creds)
        return service

    except Exception as e:
        print(f"ERROR: Failed to create Google service: {e}", file=sys.stderr)
        return None

def find_next_meeting():
    """Find next calendar event within 30 minutes"""

    service = get_google_calendar_service()
    if not service:
        sys.exit(1)

    try:
        # Time range: now to 30 minutes from now
        now = datetime.now(timezone.utc)
        thirty_min_later = now + timedelta(minutes=30)

        # Query calendar
        events_result = service.events().list(
            calendarId='primary',
            timeMin=now.isoformat(),
            timeMax=thirty_min_later.isoformat(),
            singleEvents=True,
            orderBy='startTime',
            maxResults=1
        ).execute()

        events = events_result.get('items', [])

        if events:
            event = events[0]

            # Parse event time
            start_str = event.get('start', {}).get('dateTime', '')
            if start_str:
                # Calculate minutes until event
                start_time = datetime.fromisoformat(start_str.replace('Z', '+00:00'))
                minutes_until = int((start_time - now).total_seconds() / 60)

                return {
                    'title': event.get('summary', 'Unnamed Event'),
                    'start': start_str,
                    'minutes_until': minutes_until,
                    'attendees': event.get('attendees', []),
                    'description': event.get('description', ''),
                    'id': event.get('id', '')
                }

        return None

    except Exception as e:
        print(f"ERROR: Calendar query failed: {e}", file=sys.stderr)
        return None

# Main
meeting = find_next_meeting()
if meeting:
    print(json.dumps(meeting))
else:
    print("{}")  # Empty JSON means no meeting
PYTHON_SCRIPT
}

################################################################################
# Get Action Items Relevant to Meeting
################################################################################

get_meeting_action_items() {
    local meeting_title="$1"

    if [[ ! -f "${MEMORY_DIR}/action_points.md" ]]; then
        echo ""
        return
    fi

    # Extract active items from action_points.md
    # This is simplified - extract lines between "## Active Items" and next ##
    sed -n '/^## Active Items/,/^## /p' "${MEMORY_DIR}/action_points.md" | \
        grep "^- \[ \]" | \
        head -5
}

################################################################################
# Get Relevant Memory Context
################################################################################

get_meeting_context() {
    local meeting_title="$1"

    if [[ ! -d "${MEMORY_DIR}/memoria_agente" ]]; then
        echo ""
        return
    fi

    # Search recent files for meeting keywords
    grep -l "$(echo "$meeting_title" | cut -d' ' -f1)" \
        "${MEMORY_DIR}/memoria_agente"/*.md 2>/dev/null | \
        head -3 || true
}

################################################################################
# Generate Briefing Text
################################################################################

generate_briefing() {
    local meeting_json="$1"

    if [[ "$meeting_json" == "{}" ]] || [[ -z "$meeting_json" ]]; then
        return 1
    fi

    # Parse JSON (bash doesn't have native JSON, so we'll use Python)
    python3 << PYTHON_BRIEFING
import json
import sys
from datetime import datetime

meeting = json.loads('$meeting_json')

title = meeting.get('title', 'Unnamed Meeting')
minutes = meeting.get('minutes_until', 0)
start = meeting.get('start', '')
attendees = meeting.get('attendees', [])
description = meeting.get('description', '')

# Format start time
if start:
    dt = datetime.fromisoformat(start.replace('Z', '+00:00'))
    time_str = dt.strftime('%H:%M')
else:
    time_str = 'Unknown time'

# Build briefing
briefing = f"""📅 UPCOMING MEETING (in {minutes} minutes)

**{title}**
Time: {time_str}
Attendees: {len(attendees)} people
"""

if description:
    briefing += f"Details: {description}\n"

briefing += """
🔥 ACTION ITEMS (relevant to this meeting)
See full briefing in Claude Code with: /pre-meeting "{title}"
"""

print(briefing)
PYTHON_BRIEFING
}

################################################################################
# Send Slack Message
################################################################################

send_slack_briefing() {
    local briefing="$1"
    local meeting_title="$2"

    # Get Slack credentials
    local slack_token=$(get_secret "slack-user-token")
    local member_id=$(get_secret "slack-member-id")

    if [[ -z "$slack_token" ]] || [[ -z "$member_id" ]]; then
        log_error "Slack credentials not found"
        return 1
    fi

    # Send message via Slack API
    local response=$(curl -s -X POST \
        "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer $slack_token" \
        -H "Content-Type: application/json" \
        -d "{
            \"channel\": \"$member_id\",
            \"blocks\": [
                {
                    \"type\": \"section\",
                    \"text\": {
                        \"type\": \"mrkdwn\",
                        \"text\": \"$briefing\"
                    }
                },
                {
                    \"type\": \"context\",
                    \"elements\": [
                        {
                            \"type\": \"mrkdwn\",
                            \"text\": \"_Sent automatically by Claude Meeting Memory - Use /pre-meeting for full briefing_\"
                        }
                    ]
                }
            ]
        }")

    # Check response
    if echo "$response" | grep -q '"ok":true'; then
        log "✓ Briefing sent: $meeting_title"
        return 0
    else
        log_error "Failed to send Slack message: $response"
        return 1
    fi
}

################################################################################
# Main Logic
################################################################################

# Check if credentials are configured
if ! get_secret "google-refresh-token" &>/dev/null; then
    log "Skipping: Google credentials not configured"
    exit 0
fi

if ! get_secret "slack-user-token" &>/dev/null; then
    log "Skipping: Slack credentials not configured"
    exit 0
fi

# Get next meeting
log "Checking calendar for meetings in next 30 minutes..."
meeting_json=$(get_next_meeting)

if [[ -z "$meeting_json" ]] || [[ "$meeting_json" == "{}" ]]; then
    log "No meetings found in next 30 minutes"
    exit 0
fi

# Parse meeting title for cooldown check
meeting_title=$(echo "$meeting_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('title', 'Unknown'))")
log "Found meeting: $meeting_title"

# Check if we should send (avoid duplicate briefings)
if ! should_send_briefing "$meeting_title"; then
    log "Skipping: Cooldown active for this meeting"
    exit 0
fi

# Generate briefing
log "Generating briefing..."
briefing=$(generate_briefing "$meeting_json")

if [[ -z "$briefing" ]]; then
    log_error "Failed to generate briefing"
    exit 1
fi

# Send via Slack
log "Sending to Slack..."
if send_slack_briefing "$briefing" "$meeting_title"; then
    mark_briefing_sent
    log "✓ Check completed successfully"
else
    log_error "Failed to send briefing"
    exit 1
fi

exit 0
