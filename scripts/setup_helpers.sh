#!/bin/bash

################################################################################
# Claude Meeting Memory - Setup Helper Functions
#
# Utility functions for improved setup.sh UX
# - Progress bars and visual indicators
# - Contextual help for technical terms
# - Step-by-step guided setup
#
# Source this file in setup.sh: source "$(dirname "$0")/setup_helpers.sh"
#
################################################################################

# Color codes (inherit from caller or define here)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

################################################################################
# Progress Indicators
################################################################################

# Display a progress bar (filled/empty style)
# Usage: show_progress_bar 3 9  (shows 3/9 progress)
show_progress_bar() {
    local current=$1
    local total=$2
    local width=10

    if [[ -z "$current" ]] || [[ -z "$total" ]] || [[ "$total" -eq 0 ]]; then
        return 1
    fi

    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "Progress: "
    printf "%.0s█" $(seq 1 "$filled")
    printf "%.0s░" $(seq 1 "$empty")
    printf " %d%%\n" "$percent"
}

# Display phase header with progress
# Usage: show_phase_header 3 9 "Email Configuration" "~3 minutes"
show_phase_header() {
    local phase_num=$1
    local total_phases=$2
    local phase_name=$3
    local time_estimate="${4:-}"

    echo ""
    echo -e "${BOLD}${BLUE}┌────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${BLUE}│ Phase $phase_num of $total_phases: $phase_name${NC}"

    if [[ -n "$time_estimate" ]]; then
        echo -e "${BOLD}${BLUE}│ Time: $time_estimate${NC}"
    fi

    echo -e "${BOLD}${BLUE}│${NC}"
    echo -n -e "${BOLD}${BLUE}│ "
    show_progress_bar "$phase_num" "$total_phases" | sed 's/Progress: //'
    printf "%s" "│"
    echo ""
    echo -e "${BOLD}${BLUE}└────────────────────────────────────────────┘${NC}"
    echo ""
}

################################################################################
# Help System
################################################################################

# Get help text for a term
# Usage: get_help_text "IMAP"
get_help_text() {
    local term="$1"
    case "$term" in
        "IMAP")
            echo "A protocol to access your emails from anywhere (like how you check email on your phone)"
            ;;
        "CalDAV")
            echo "A standard way to access your calendar from multiple devices and services"
            ;;
        "App Password")
            echo "A special password just for this app - safer than using your real password"
            ;;
        "OAuth Token")
            echo "A secure code that lets Claude Memory access your account without needing your password"
            ;;
        "User Token")
            echo "A Slack token for your personal account (starts with xoxp-)"
            ;;
        "Bot Token")
            echo "A Slack token for a bot/app (starts with xoxb-) - NOT what we need"
            ;;
        "Member ID")
            echo "Your unique ID in Slack (looks like U01DHE5U6MA)"
            ;;
        "Nextcloud")
            echo "A personal cloud storage service you can host yourself"
            ;;
        "Radicale")
            echo "A lightweight calendar/contact server you can host yourself"
            ;;
        "FastMail")
            echo "An email service that also provides calendar storage"
            ;;
        "ProtonMail")
            echo "An encrypted email service focused on privacy"
            ;;
        "Himalaya")
            echo "A command-line email client that reads your emails"
            ;;
        "Plann")
            echo "A command-line calendar client that reads your calendar events"
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# Show help for a term
# Usage: show_help "IMAP"
show_help() {
    local term="$1"
    local help_text

    if [[ -z "$term" ]]; then
        echo "Available help topics:"
        echo "  IMAP, CalDAV, App Password, OAuth Token"
        echo "  User Token, Bot Token, Member ID"
        echo "  Nextcloud, Radicale, FastMail, ProtonMail"
        echo "  Himalaya, Plann"
        return 0
    fi

    help_text=$(get_help_text "$term" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo -e "${BLUE}ℹ${NC}  $help_text"
    else
        echo -e "${YELLOW}⚠${NC}  No help available for: $term"
    fi
}

# Show help prompt during setup
# Usage: show_help_prompt "IMAP"
show_help_prompt() {
    local term="$1"
    echo ""
    echo -e "${YELLOW}💡 What's $term?${NC}"
    show_help "$term"
    echo ""
}

################################################################################
# Step-by-Step Guides
################################################################################

# Show a formatted step guide
# Usage: show_step_guide "Gmail Setup" \
#          "1. Go to: https://myaccount.google.com/apppasswords" \
#          "2. Select Mail and Other" \
#          "3. Copy the 16-character password"
show_step_guide() {
    local title="$1"
    shift

    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}$title${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    while [[ $# -gt 0 ]]; do
        echo "  $1"
        shift
    done

    echo ""
}

# Show provider with context
# Usage: show_provider 1 "Gmail" "Most popular email service"
show_provider() {
    local number="$1"
    local name="$2"
    local description="$3"

    printf "  %d) %-20s %s\n" "$number" "$name" "$description"
}

################################################################################
# Simplified Provider Selection
################################################################################

# Show email providers with descriptions
show_email_providers() {
    echo "Which email service do you use?"
    echo ""
    show_provider 1 "Gmail" "(most popular)"
    show_provider 2 "ProtonMail" "(encrypted, privacy-focused)"
    show_provider 3 "Fastmail" "(privacy-friendly, supports IMAP)"
    show_provider 4 "Outlook/Microsoft" "(work email)"
    show_provider 5 "Other email service" "(any IMAP-compatible service)"
    echo ""
}

# Show calendar providers with descriptions
show_calendar_providers() {
    echo "What calendar service do you use?"
    echo ""
    show_provider 1 "Nextcloud" "(personal cloud)"
    show_provider 2 "Radicale" "(self-hosted calendar)"
    show_provider 3 "FastMail" "(email with calendar)"
    show_provider 4 "Other CalDAV service" "(any CalDAV-compatible)"
    echo ""
}

################################################################################
# Requirement Messaging
################################################################################

# Show what's required vs optional
show_requirement_summary() {
    echo ""
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  What's Required vs Optional${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${GREEN}✓ REQUIRED (for meeting briefings):${NC}"
    echo "  • Email access (Himalaya)"
    echo "  • Calendar access (Plann)"
    echo ""

    echo -e "${YELLOW}◆ RECOMMENDED (for Slack notifications):${NC}"
    echo "  • Slack integration"
    echo ""

    echo -e "${BLUE}◇ OPTIONAL (personalization):${NC}"
    echo "  • Your profile information"
    echo ""
}

# Show what's being stored
show_security_summary() {
    echo ""
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  Security Summary${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════${NC}"
    echo ""

    echo "Your credentials are encrypted and stored locally:"
    echo ""
    echo -e "${GREEN}✓ On your machine only${NC}"
    echo -e "${GREEN}✓ Protected by OS keychain/secret service${NC}"
    echo -e "${GREEN}✓ Never sent to cloud or external services${NC}"
    echo -e "${GREEN}✓ Never sent to Claude API${NC}"
    echo ""

    echo "To revoke access anytime:"
    echo "  • Google: https://myaccount.google.com/permissions"
    echo "  • Slack: https://api.slack.com/apps"
    echo ""
}

################################################################################
# Time Estimate Messages
################################################################################

# Show time estimate for a phase
# Usage: show_time_estimate "Email Setup" "Gmail" "2 minutes"
show_time_estimate() {
    local phase="$1"
    local provider="$2"
    local minutes="$3"

    echo -e "${BLUE}⏱  Estimated time for $phase ($provider): $minutes${NC}"
}

################################################################################
# Validation Messages
################################################################################

# Show validation status
show_validation_status() {
    local component="$1"
    local status="$2"  # "ok", "configured", "not_configured", "missing", "optional"

    case "$status" in
        ok)
            echo -e "${GREEN}✓${NC} $component: Installed and working"
            ;;
        configured)
            echo -e "${GREEN}✓${NC} $component: Configured"
            ;;
        not_configured)
            echo -e "${YELLOW}⚠${NC}  $component: Installed but not configured"
            ;;
        missing)
            echo -e "${RED}✗${NC} $component: Not found"
            ;;
        optional)
            echo -e "${BLUE}◇${NC} $component: Optional (not installed)"
            ;;
    esac
}

################################################################################
# Visual Separators
################################################################################

# Show a section divider
show_divider() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Show a section title
show_section() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${BLUE}$title${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}
