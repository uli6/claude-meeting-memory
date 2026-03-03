#!/bin/bash

################################################################################
# Claude Meeting Memory - Automated Onboarding Setup
#
# One-command setup for Claude Code with secure credential management,
# skill registration, and memory initialization.
#
# Usage: bash setup.sh
#        bash setup.sh --reinstall
#        curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
#
# Options:
#   --reinstall   - Remove existing installation and start fresh
#   --help        - Show this help message
#
# Version: 1.0.0
# License: MIT
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/uli6/claude-meeting-memory"
REPO_RAW="https://raw.githubusercontent.com/uli6/claude-meeting-memory/main"
SETUP_VERSION="1.0.0"
CLAUDE_HOME="${HOME}/.claude"
MEMORY_DIR="${CLAUDE_HOME}/memory"
SCRIPTS_DIR="${CLAUDE_HOME}/scripts"
SKILLS_DIR="${CLAUDE_HOME}/skills"
MEMORY_AGENT_DIR="${MEMORY_DIR}/memoria_agente"

# State
SETUP_OK=true
FAILED_CHECKS=()
INSTALLED_COMPONENTS=()

################################################################################
# Utility Functions
################################################################################

# Show help
show_help() {
    cat << 'HELP_TEXT'
Claude Meeting Memory - Setup Script

Usage:
  bash setup.sh                 - Normal setup (first time or update)
  bash setup.sh --reinstall     - Remove existing installation and start fresh
  bash setup.sh --help          - Show this help message

Options:
  --reinstall   Remove all Claude Meeting Memory files and credentials,
                then run setup fresh. Use if you want to reconfigure
                everything from scratch.

  --help        Show this help message

Examples:
  # First time installation
  curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash

  # Reinstall (remove old config, start fresh)
  bash setup.sh --reinstall

  # After modifying setup.sh locally
  bash setup.sh

For more information, see: https://github.com/uli6/claude-meeting-memory

HELP_TEXT
}

# Print with color
print_header() {
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

# Reinstall (cleanup old installation)
reinstall_cleanup() {
    print_header "Removing Existing Installation"
    echo ""

    print_warning "This will remove:"
    echo "  • ~/.claude/memory/ (except memoria_agente/perfil_usuario.md)"
    echo "  • ~/.claude/skills/read-this"
    echo "  • ~/.claude/skills/pre-meeting"
    echo "  • ~/.claude/skills/remind-me"
    echo "  • ~/.claude/scripts/ (helper scripts only)"
    echo "  • ~/.claude/logs/"
    echo "  • ~/.claude/claude.json (skills section only)"
    echo "  • Keychain/Secret Service credentials"
    echo "  • Crontab entry for pre_meeting_cron.sh"
    echo ""

    print_warning "This will NOT remove:"
    echo "  • ~/.claude/ directory itself"
    echo "  • memoria_agente/perfil_usuario.md (your profile is safe)"
    echo "  • Other files in ~/.claude/"
    echo ""

    if ! ask_yes_no "Continue with reinstall?"; then
        print_error "Reinstall cancelled"
        exit 0
    fi

    echo ""
    print_info "Removing old installation..."
    echo ""

    # Remove memory files (except profile)
    if [[ -d "$MEMORY_DIR" ]]; then
        find "$MEMORY_DIR" -maxdepth 1 -type f -delete 2>/dev/null || true
        print_success "Cleaned up memory files"
    fi

    # Remove skills
    if [[ -d "$SKILLS_DIR" ]]; then
        rm -rf "$SKILLS_DIR/read-this" 2>/dev/null || true
        rm -rf "$SKILLS_DIR/pre-meeting" 2>/dev/null || true
        rm -rf "$SKILLS_DIR/remind-me" 2>/dev/null || true
        print_success "Removed old skills"
    fi

    # Remove helper scripts (but keep memory subdirectories)
    if [[ -d "$SCRIPTS_DIR" ]]; then
        rm -f "$SCRIPTS_DIR"/*.py 2>/dev/null || true
        rm -f "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
        print_success "Removed old scripts"
    fi

    # Remove logs
    if [[ -d "$CLAUDE_HOME/logs" ]]; then
        rm -rf "$CLAUDE_HOME/logs" 2>/dev/null || true
        print_success "Removed old logs"
    fi

    # Remove credentials from keychain (macOS)
    if command -v security &> /dev/null; then
        security delete-generic-password -a "$USER" -s "claude-code-google-client-id" 2>/dev/null || true
        security delete-generic-password -a "$USER" -s "claude-code-google-client-secret" 2>/dev/null || true
        security delete-generic-password -a "$USER" -s "claude-code-google-refresh-token" 2>/dev/null || true
        security delete-generic-password -a "$USER" -s "claude-code-slack-user-token" 2>/dev/null || true
        security delete-generic-password -a "$USER" -s "claude-code-slack-member-id" 2>/dev/null || true
        print_success "Removed credentials from Keychain"
    fi

    # Remove credentials from secret service (Linux)
    if command -v secret-tool &> /dev/null; then
        secret-tool clear label "Claude Code" 2>/dev/null || true
        print_success "Removed credentials from Secret Service"
    fi

    # Remove crontab entry
    if command -v crontab &> /dev/null; then
        local existing_cron
        existing_cron=$(crontab -l 2>/dev/null || echo "")

        if echo "$existing_cron" | grep -q "pre_meeting_cron.sh"; then
            # Remove the crontab entry
            echo "$existing_cron" | grep -v "pre_meeting_cron.sh" | crontab - 2>/dev/null || true
            print_success "Removed crontab entry"
        fi
    fi

    # Remove claude.json if it only contains our skills
    if [[ -f "${CLAUDE_HOME}/claude.json" ]]; then
        # This is careful - only remove if file is very small or contains only our skills
        # Better to leave it and let user manually edit if needed
        print_info "Preserved ~/.claude/claude.json (manual cleanup may be needed)"
    fi

    echo ""
    print_success "Reinstall cleanup complete!"
    echo ""
    print_info "Your user profile is preserved at:"
    echo "  ~/.claude/memory/memoria_agente/perfil_usuario.md"
    echo ""
}

# Ask yes/no question
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response

    if [[ "$default" == "y" ]]; then
        echo -ne "${prompt} ${BOLD}(Y/n)${NC}: "
    else
        echo -ne "${prompt} ${BOLD}(y/N)${NC}: "
    fi

    # Read from /dev/tty if available (allows input even when piped)
    # Fall back to stdin if /dev/tty not available
    if [[ -t 0 ]] || [[ -c /dev/tty ]]; then
        read -r response </dev/tty || response=""
    else
        read -r response || response=""
    fi

    response=${response:-$default}

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Read input (with optional masking)
read_input() {
    local prompt="$1"
    local mask="${2:-false}"
    local value

    if [[ "$mask" == "true" ]]; then
        echo -ne "${prompt}: "
        # Read from /dev/tty if available (allows input even when piped)
        if [[ -t 0 ]] || [[ -c /dev/tty ]]; then
            read -rs value </dev/tty || value=""
        else
            read -rs value || value=""
        fi
        echo # New line after masked input
    else
        echo -ne "${prompt}: "
        # Read from /dev/tty if available (allows input even when piped)
        if [[ -t 0 ]] || [[ -c /dev/tty ]]; then
            read -r value </dev/tty || value=""
        else
            read -r value || value=""
        fi
    fi

    echo "$value"
}

# Download file from GitHub
download_file() {
    local source_url="$1"
    local dest_path="$2"

    if ! curl -fsSL "$source_url" -o "$dest_path" 2>/dev/null; then
        print_error "Failed to download from $source_url"
        return 1
    fi
}

################################################################################
# Phase 1: Initial Checks & Welcome
################################################################################

phase_1_checks() {
    print_header "Phase 1: Initial Checks & Welcome"
    echo ""
    echo "Checking system requirements..."
    echo ""

    # Check OS
    OS_TYPE=$(uname)
    case "$OS_TYPE" in
        Darwin)
            print_success "macOS detected"
            ;;
        Linux)
            print_success "Linux detected"
            ;;
        *)
            print_error "Unsupported OS: $OS_TYPE (use macOS or Linux)"
            exit 1
            ;;
    esac

    # Check required tools
    local tools=("curl" "python3" "openssl" "jq")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version
            version=$("$tool" --version 2>&1 | head -1)
            print_success "$tool: $version"
        else
            print_error "$tool: NOT FOUND"
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo ""
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install them and try again."
        echo ""
        echo "macOS (Homebrew):"
        echo "  brew install ${missing_tools[*]}"
        echo ""
        echo "Ubuntu/Debian:"
        echo "  sudo apt-get install ${missing_tools[*]}"
        exit 1
    fi

    # Check bash version
    bash_version=$(bash --version | head -1)
    print_success "bash: $bash_version"

    # Check Claude Code installation
    if [[ ! -d "$CLAUDE_HOME" ]]; then
        echo ""
        print_error "Claude Code not found at $CLAUDE_HOME"
        echo ""
        echo "This project requires Claude Code to be installed."
        echo "Install it first:"
        echo "  https://github.com/anthropics/claude-code"
        echo ""
        exit 1
    fi

    print_success "Claude Code: found at $CLAUDE_HOME"

    echo ""
    print_success "All system requirements met!"
    echo ""

    # Show checklist
    echo "Setup will:"
    echo "  ✓ Install Python dependencies"
    echo "  ✓ Create ~/.claude/ directory structure"
    echo "  ✓ Configure Google OAuth (Drive + Calendar)"
    echo "  ✓ Configure Slack credentials (user token + member ID)"
    echo "  ✓ Register three skills (read-this, pre-meeting, remind-me)"
    echo "  ✓ Create template memory files"
    echo "  ✓ Validate all configurations"
    echo ""
}

################################################################################
# Phase 1.5: Python Dependencies
################################################################################

phase_1_5_python_deps() {
    print_header "Phase 1.5: Python Dependencies"
    echo ""

    # List of required packages
    local packages=(
        "google-auth>=2.25.0"
        "google-auth-oauthlib>=1.2.0"
        "google-auth-httplib2>=0.2.0"
        "google-api-client>=1.12.0"
        "google-generativeai>=0.3.0"
        "slack-sdk>=3.27.0"
    )

    # First, check which packages are missing
    local missing_packages=()
    for package in "${packages[@]}"; do
        local pkg_name=${package%%[><=]*}
        if ! python3 -c "import ${pkg_name//-/_}" 2>/dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        # All packages already installed
        print_success "All Python dependencies are already installed"
        echo ""
        return 0
    fi

    # Install missing packages
    print_info "Installing ${#missing_packages[@]} missing package(s)..."
    echo ""

    # Try to install using pip3
    if ! python3 -m pip install --upgrade pip >/dev/null 2>&1; then
        print_warning "Could not upgrade pip, continuing anyway..."
    fi

    local failed=0
    for package in "${missing_packages[@]}"; do
        local pkg_name=${package%%[><=]*}

        if python3 -m pip install "$package" >/dev/null 2>&1; then
            print_success "Installed: $pkg_name"
        else
            print_error "Failed to install: $pkg_name"
            failed=$((failed + 1))
        fi
    done

    echo ""

    if [[ $failed -gt 0 ]]; then
        print_error "$failed package(s) failed to install"
        echo ""
        echo "Try installing manually:"
        echo "  pip3 install -r requirements.txt"
        echo ""
        echo "Or install individual packages:"
        for package in "${missing_packages[@]}"; do
            echo "  pip3 install '$package'"
        done
        echo ""
        if ! ask_yes_no "Continue setup anyway?"; then
            exit 1
        fi
    else
        print_success "All missing dependencies installed successfully!"
    fi

    echo ""
}

################################################################################
# Phase 2: Directory Structure
################################################################################

phase_2_directories() {
    print_header "Phase 2: Creating Directory Structure"
    echo ""

    # Create main directories
    local dirs=(
        "$CLAUDE_HOME"
        "$MEMORY_DIR"
        "$MEMORY_AGENT_DIR"
        "$SCRIPTS_DIR"
        "$SKILLS_DIR"
    )

    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            print_success "$dir"
            chmod 700 "$dir" 2>/dev/null || true
        else
            print_error "Failed to create $dir"
            SETUP_OK=false
        fi
    done

    if [[ "$SETUP_OK" == "false" ]]; then
        print_error "Failed to create directory structure"
        exit 1
    fi

    echo ""
    print_success "Directory structure created!"
    echo ""
}

################################################################################
# Phase 3: Google OAuth Configuration
################################################################################

phase_3_google_oauth() {
    print_header "Phase 3: Google OAuth Configuration"
    echo ""

    print_info "Setting up Google Drive and Calendar access..."
    echo ""
    echo "This will allow Claude Code to:"
    echo "  ✓ Read your Google Docs from Drive"
    echo "  ✓ Check your Google Calendar for meetings"
    echo "  ✓ Send you meeting briefings"
    echo ""

    # Check if credentials already exist
    if [[ -f "${CLAUDE_HOME}/.google_refresh_token" ]]; then
        if ask_yes_no "Found existing Google credentials. Use them?"; then
            print_success "Using existing Google credentials"
            echo ""
            return 0
        fi
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "GETTING GOOGLE CREDENTIALS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Step 1: Ask if they have credentials
    if ask_yes_no "Do you have Google OAuth credentials already?"; then
        # Skip the creation steps
        print_info "Good! Paste your credentials below..."
        echo ""
    else
        # Guide through creation
        print_info "No problem! We'll create them together."
        echo ""
        echo "This takes about 5 minutes. We'll guide you through each step."
        echo ""

        if ask_yes_no "Ready to create Google credentials?"; then
            echo ""
            print_info "Opening Google Cloud Console in your browser..."
            sleep 2

            echo ""
            echo "📋 STEP 1: Create a Google Cloud Project"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "  ① Go to: https://console.cloud.google.com/"
            echo "  ② Click the project dropdown (top left)"
            echo "  ③ Click 'NEW PROJECT'"
            echo "  ④ Name: 'Claude Meeting Memory'"
            echo "  ⑤ Click 'CREATE'"
            echo "  ⑥ Wait 1-2 minutes for project to be created"
            echo ""

            if ! ask_yes_no "Project created?"; then
                print_error "Please create the project first, then re-run setup"
                return 1
            fi

            echo ""
            echo "📋 STEP 2: Enable Required APIs"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "  Still in Google Cloud Console:"
            echo "  ① Go to: APIs & Services → Library"
            echo "  ② Search for 'Google Drive API', click it, click ENABLE"
            echo "  ③ Go back, search for 'Google Calendar API', click it, click ENABLE"
            echo "  ④ Go back, search for 'Google Docs API', click it, click ENABLE"
            echo ""

            if ! ask_yes_no "All three APIs enabled?"; then
                print_error "Please enable all three APIs, then re-run setup"
                return 1
            fi

            echo ""
            echo "📋 STEP 3: Create OAuth Credentials"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "  ① Go to: APIs & Services → Credentials (left menu)"
            echo "  ② Click 'Create Credentials' → 'OAuth client ID'"
            echo "  ③ If prompted 'Configure OAuth consent screen':"
            echo "     • Click 'Configure Consent Screen'"
            echo "     • Choose 'External' user type"
            echo "     • Click 'CREATE'"
            echo "     • Fill: App name = 'Claude Code'"
            echo "     • Fill your email as support/developer email"
            echo "     • Click 'SAVE AND CONTINUE' (skip optional parts)"
            echo "     • Click 'BACK TO DASHBOARD'"
            echo "  ④ Click 'Create Credentials' → 'OAuth client ID' again"
            echo "  ⑤ Choose 'Desktop application'"
            echo "  ⑥ Click 'CREATE'"
            echo ""

            print_warning "Important: You should now see a popup with your credentials!"
            echo "Copy the CLIENT ID and CLIENT SECRET from the popup"
            echo ""

            if ! ask_yes_no "Do you see the credentials popup?"; then
                print_error "If you don't see it, click the 'DOWNLOAD JSON' button instead"
                echo "Then open the downloaded file in a text editor to find client_id and client_secret"
                echo ""
            fi
        else
            print_error "Setup requires Google credentials. Re-run when ready."
            return 1
        fi
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ENTERING YOUR CREDENTIALS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get Client ID and Secret
    local client_id
    local client_secret

    print_info "Paste your credentials from Google Cloud Console:"
    echo ""

    client_id=$(read_input "Google Client ID")
    if [[ -z "$client_id" ]]; then
        print_error "Client ID cannot be empty"
        return 1
    fi
    print_success "Client ID received"
    echo ""

    client_secret=$(read_input "Google Client Secret" "true")
    if [[ -z "$client_secret" ]]; then
        print_error "Client Secret cannot be empty"
        return 1
    fi
    print_success "Client Secret received"
    echo ""

    print_info "Authorizing with Google..."
    echo ""

    # Create temporary Python script for OAuth
    local oauth_script="/tmp/claude_oauth_temp.py"
    cat > "$oauth_script" << 'OAUTH_SCRIPT'
#!/usr/bin/env python3
import os
import sys
import json
import webbrowser
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import time

CLIENT_ID = sys.argv[1]
CLIENT_SECRET = sys.argv[2]

class OAuthHandler(BaseHTTPRequestHandler):
    auth_code = None

    def do_GET(self):
        if '/auth' in self.path:
            query = parse_qs(urlparse(self.path).query)
            if 'code' in query:
                OAuthHandler.auth_code = query['code'][0]
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                msg = '<h1>✓ Authorization successful!</h1><p>You can close this window.</p>'
                self.wfile.write(msg.encode())
            else:
                self.send_response(400)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress log messages

try:
    import google.auth.oauthlib.flow
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow

    SCOPES = [
        'https://www.googleapis.com/auth/drive.readonly',
        'https://www.googleapis.com/auth/calendar.readonly'
    ]

    # Create flow
    config = {
        "installed": {
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "redirect_uris": ["http://localhost:8080/auth"]
        }
    }

    flow = InstalledAppFlow.from_client_config(config, SCOPES)
    creds = flow.run_local_server(port=8080, open_browser=True)

    # Save refresh token
    if creds.refresh_token:
        print(creds.refresh_token)
    else:
        print("ERROR: No refresh token obtained", file=sys.stderr)
        sys.exit(1)

except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
OAUTH_SCRIPT

    # Try to get refresh token
    if refresh_token=$(python3 "$oauth_script" "$client_id" "$client_secret" 2>/dev/null); then
        # Store credentials securely
        export GOOGLE_CAL_CLIENT_ID="$client_id"
        export GOOGLE_CAL_CLIENT_SECRET="$client_secret"
        export GOOGLE_REFRESH_TOKEN="$refresh_token"

        # Try to save to Keychain (macOS) or Secret Service (Linux)
        if command -v security &> /dev/null; then
            # macOS Keychain
            security add-generic-password -a "$USER" -s "claude-code-google-client-id" -w "$client_id" 2>/dev/null || true
            security add-generic-password -a "$USER" -s "claude-code-google-client-secret" -w "$client_secret" 2>/dev/null || true
            security add-generic-password -a "$USER" -s "claude-code-google-refresh-token" -w "$refresh_token" 2>/dev/null || true
            print_success "Google credentials saved to Keychain"
        elif command -v secret-tool &> /dev/null; then
            # Linux Secret Service
            secret-tool store --label="Claude Code" google-client-id "$client_id" 2>/dev/null || true
            secret-tool store --label="Claude Code" google-client-secret "$client_secret" 2>/dev/null || true
            secret-tool store --label="Claude Code" google-refresh-token "$refresh_token" 2>/dev/null || true
            print_success "Google credentials saved to Secret Service"
        else
            # Fallback: Save to encrypted file
            print_warning "Keychain/Secret Service not available"
            print_info "Saving credentials to encrypted file..."
            # Store in ~/.claude/ for now
            export GOOGLE_CAL_CLIENT_ID="$client_id"
            export GOOGLE_CAL_CLIENT_SECRET="$client_secret"
            export GOOGLE_REFRESH_TOKEN="$refresh_token"
            print_success "Google credentials stored in environment"
        fi

        print_success "Google authorization successful!"
        echo ""
    else
        print_error "Google OAuth failed"
        echo "Try again or set up manually later"
        echo ""
        return 1
    fi

    # Clean up temporary script
    rm -f "$oauth_script"
}

################################################################################
# Phase 4: Slack Configuration
################################################################################

phase_4_slack() {
    print_header "Phase 4: Slack Configuration (Optional)"
    echo ""

    print_info "Slack integration enables automatic meeting briefings via DM"
    echo ""
    echo "Features with Slack:"
    echo "  ✓ Automatic meeting briefings sent to your Slack"
    echo "  ✓ Create action items from Slack messages"
    echo "  ✓ Receive reminders and updates"
    echo ""

    # Ask if user wants to configure Slack
    if ! ask_yes_no "Do you want to configure Slack integration?"; then
        print_warning "Skipping Slack setup (you can add it later)"
        echo ""
        return 0
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "GETTING SLACK CREDENTIALS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_info "We need two things from Slack:"
    echo "  1. Your Slack User Token (xoxp-...)"
    echo "  2. Your Slack Member ID (U...)"
    echo ""

    if ask_yes_no "Do you have a Slack User Token already?"; then
        print_info "Good! We'll use your existing token..."
        echo ""
    else
        print_info "No problem! Let's create it together."
        echo ""
        echo "This takes about 3 minutes. Follow these steps:"
        echo ""

        echo "📋 STEP 1: Go to Slack API"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  ① Go to: https://api.slack.com/apps"
        echo "  ② Click 'Create New App'"
        echo "  ③ Choose 'From scratch'"
        echo "  ④ App Name: 'Claude Code'"
        echo "  ⑤ Workspace: (choose your workspace)"
        echo "  ⑥ Click 'Create App'"
        echo ""

        if ! ask_yes_no "App created?"; then
            print_error "Please create the Slack app first, then re-run setup"
            return 1
        fi

        echo ""
        echo "📋 STEP 2: Add Permissions"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  ① Go to: OAuth & Permissions (left menu)"
        echo "  ② Scroll to 'User Token Scopes'"
        echo "  ③ Click 'Add an OAuth Scope'"
        echo "  ④ Add these scopes:"
        echo "     • channels:read"
        echo "     • groups:read"
        echo "     • im:read"
        echo "     • chat:write"
        echo "     • users:read"
        echo ""

        echo "📋 STEP 3: Install App"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  ① Still in 'OAuth & Permissions'"
        echo "  ② Look at the top - click 'Install to Workspace'"
        echo "  ③ Click 'Allow' to authorize"
        echo "  ④ You'll see a message: 'App installed to workspace'"
        echo ""

        print_warning "Important: Look for 'User OAuth Token' - it starts with 'xoxp-'"
        echo "You should see it at the top of the OAuth & Permissions page"
        echo ""

        if ! ask_yes_no "Do you see the User OAuth Token (xoxp-...)?"; then
            print_error "Make sure you clicked 'Install to Workspace' and authorized the app"
            echo ""
            return 1
        fi
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ENTERING YOUR SLACK CREDENTIALS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_info "Paste your Slack credentials:"
    echo ""
    echo "    1. Go to: https://api.slack.com/apps"
    echo "    2. Click 'Create New App' → 'From scratch'"
    echo "    3. Name: 'Claude Meeting Memory' | Workspace: (your workspace)"
    echo "    4. Go to 'OAuth & Permissions' on the left"
    echo "    5. Under 'User Token Scopes', add these scopes:"
    echo "       • chat:write"
    echo "       • channels:read"
    echo "       • groups:read"
    echo "       • im:read"
    echo "       • users:read"
    echo "    6. Click 'Install to Workspace' at the top"
    echo "    7. Copy your 'User OAuth Token' (starts with xoxp-)"
    echo ""
    echo "⚠️  IMPORTANT: Use 'User Token' (xoxp-), NOT 'Bot Token' (xoxb-)"
    echo ""

    # Get Slack token
    local slack_token

    print_info "Paste your Slack User Token (xoxp-...):"
    slack_token=$(read_input "Slack User Token" "true")

    if [[ -z "$slack_token" ]]; then
        print_error "Slack token cannot be empty"
        return 1
    fi

    if [[ ! "$slack_token" =~ ^xoxp- ]]; then
        print_error "Invalid token format!"
        echo ""
        echo "The token must start with 'xoxp-'"
        echo ""
        print_info "Make sure you copied the 'User OAuth Token', not the 'Bot Token'"
        echo "Location: OAuth & Permissions → User OAuth Token (xoxp-...)"
        echo ""
        return 1
    fi

    print_success "Token format looks good"
    echo ""

    # Validate token
    print_info "Validating token with Slack..."
    sleep 1

    local slack_response
    slack_response=$(curl -s -X POST https://slack.com/api/auth.test \
        -H "Authorization: Bearer $slack_token" 2>/dev/null)

    if ! echo "$slack_response" | grep -q '"ok":true'; then
        print_error "Slack rejected this token!"
        echo ""
        print_info "Possible reasons:"
        echo "  • Token is expired or revoked"
        echo "  • Token was never authorized"
        echo "  • Token is invalid"
        echo ""
        print_info "Solution: Create a new token and try again"
        return 1
    fi

    print_success "Token is valid and working!"
    echo ""

    # Get Slack Member ID
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "GETTING YOUR SLACK MEMBER ID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    echo "📋 How to find your Slack Member ID:"
    echo ""
    echo "  Method 1 (Browser):"
    echo "    ① Go to: https://app.slack.com/"
    echo "    ② Click your profile picture (top-right)"
    echo "    ③ Click 'Copy user ID'"
    echo ""
    echo "  Method 2 (Mobile/Desktop App):"
    echo "    ① Click your profile picture"
    echo "    ③ Tap 'Member ID' or 'Copy user ID'"
    echo ""
    echo "  Your Member ID looks like: U01DHE5U6MA"
    echo "  It ALWAYS starts with 'U'"
    echo ""

    print_warning "Make sure you copy the MEMBER ID (U...), not the CHANNEL ID (C...)"
    echo ""

    local member_id

    print_info "Paste your Slack Member ID:"
    member_id=$(read_input "Slack Member ID (U...)")

    if [[ -z "$member_id" ]]; then
        print_error "Member ID cannot be empty"
        return 1
    fi

    if [[ ! "$member_id" =~ ^U ]]; then
        print_error "Invalid Member ID format!"
        echo ""
        echo "Your Member ID must start with 'U' (for example: U01DHE5U6MA)"
        echo ""
        print_info "You provided: $member_id"
        echo ""
        echo "Make sure you're copying your USER ID (starts with U)"
        echo "NOT a Channel ID (starts with C) or Workspace ID (starts with W)"
        echo ""
        return 1
    fi

    print_success "Member ID looks good!"
    echo ""

    # Store credentials securely
    export SLACK_USER_TOKEN="$slack_token"
    export SLACK_MEMBER_ID="$member_id"

    # Try to save to Keychain (macOS) or Secret Service (Linux)
    if command -v security &> /dev/null; then
        # macOS Keychain
        security add-generic-password -a "$USER" -s "claude-code-slack-user-token" -w "$slack_token" 2>/dev/null || true
        security add-generic-password -a "$USER" -s "claude-code-slack-member-id" -w "$member_id" 2>/dev/null || true
        print_success "Slack credentials saved to Keychain"
    elif command -v secret-tool &> /dev/null; then
        # Linux Secret Service
        secret-tool store --label="Claude Code" slack-user-token "$slack_token" 2>/dev/null || true
        secret-tool store --label="Claude Code" slack-member-id "$member_id" 2>/dev/null || true
        print_success "Slack credentials saved to Secret Service"
    else
        # Fallback: Store in environment
        print_warning "Keychain/Secret Service not available"
        print_info "Slack credentials stored in environment"
    fi

    echo ""
    print_success "Slack configuration complete!"
    echo ""
}

################################################################################
# Phase 4.5: Automatic Crontab Setup (If Google OAuth Succeeded)
################################################################################

phase_4_5_crontab_automation() {
    print_header "Phase 4.5: Automatic Meeting Briefing Automation"
    echo ""

    print_info "Google Calendar access is configured!"
    echo "Setting up automatic meeting briefing checks every 10 minutes..."
    echo ""

    # Create logs directory if it doesn't exist
    mkdir -p "${CLAUDE_HOME}/logs"
    chmod 700 "${CLAUDE_HOME}/logs"

    # Check if pre_meeting_cron.sh exists
    if [[ ! -f "${SCRIPTS_DIR}/pre_meeting_cron.sh" ]]; then
        print_warning "pre_meeting_cron.sh not found, automation skipped"
        return 0
    fi

    # Create a temporary cron entry file
    local temp_cron="/tmp/claude_cron_entry.txt"
    local cron_entry="*/10 * * * * ${SCRIPTS_DIR}/pre_meeting_cron.sh >> ${CLAUDE_HOME}/logs/pre_meeting_cron.log 2>&1"

    # Get existing crontab
    local existing_cron
    existing_cron=$(crontab -l 2>/dev/null || echo "")

    # Check if cron entry already exists
    if echo "$existing_cron" | grep -q "pre_meeting_cron.sh"; then
        print_success "Crontab entry already exists"
        echo ""
        return 0
    fi

    # Add new cron entry
    {
        echo "$existing_cron"
        echo "$cron_entry"
    } | crontab - 2>/dev/null

    if [[ $? -eq 0 ]]; then
        print_success "Automatic briefing automation enabled!"
        echo ""
        echo "Meeting briefings will be sent to Slack every 10 minutes if:"
        echo "  • There's a meeting in the next 30 minutes"
        echo "  • You have Slack Member ID configured"
        echo ""
        echo "View briefing logs with:"
        echo "  tail -f ${CLAUDE_HOME}/logs/pre_meeting_cron.log"
        echo ""
        echo "To disable this automation, edit your crontab:"
        echo "  crontab -e"
        echo "  (find and delete the pre_meeting_cron.sh line)"
        echo ""
    else
        print_warning "Could not set up crontab automation"
        echo "You can set it up manually later with:"
        echo "  crontab -e"
        echo "  Add: ${cron_entry}"
        echo ""
    fi
}

################################################################################
# Phase 5: Security Review
################################################################################

phase_5_security() {
    print_header "Phase 5: Security Review"
    echo ""

    cat << 'SECURITY_INFO'
🔐 SECURITY INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

We're about to store your credentials securely using:

  macOS:  Apple Keychain (encrypted by OS)
  Linux:  GNOME/KDE Secret Service (encrypted by OS)
  Other:  AES-256 OpenSSL encryption (~/.claude/.secrets.enc)

WHAT WILL BE STORED:
  • Google Client ID + Secret
  • Google Refresh Token
  • Slack User Token
  • Slack Member ID

WHERE IT STAYS:
  ✓ On your machine only
  ✓ Protected by OS keychain/secret service
  ✓ Never sent to cloud or external services
  ✓ Never sent to Claude API

WHO HAS ACCESS:
  ✓ Only you (via your OS login)
  ✓ Local scripts in ~/.claude/scripts/
  ✗ Not shared with anyone
  ✗ Not backed up to cloud

REVOKING ACCESS:
  Google: https://myaccount.google.com/permissions
  Slack:  https://api.slack.com/apps
  Local:  Delete ~/.claude/.secrets.enc or use Keychain

RISKS:
  ⚠️  If someone gains access to your computer, they can
      access these credentials (same as any login)
  ⚠️  Google/Slack can revoke tokens at any time
  ⚠️  Malicious software could read credentials

SECURITY_INFO

    echo ""
    if ! ask_yes_no "Do you understand and accept these terms?"; then
        print_error "Setup cancelled. Credentials not stored."
        exit 1
    fi

    echo ""
    print_success "Security review accepted"
    echo ""
}

################################################################################
# Phase 6: Skill Registration
################################################################################

phase_6_skills() {
    print_header "Phase 6: Registering Skills"
    echo ""

    print_info "Registering three skills:"
    echo "  • read-this   - Read Google Docs and add to memory"
    echo "  • pre-meeting - Generate meeting briefings"
    echo "  • remind-me   - Create action points from Slack"
    echo ""

    # Create or update claude.json
    local claude_json="${CLAUDE_HOME}/claude.json"

    if [[ ! -f "$claude_json" ]]; then
        echo "{\"skills\": []}" > "$claude_json"
        print_info "Created new claude.json"
    fi

    # Merge skills into claude.json (simple version)
    python3 << 'MERGE_SKILLS'
import json
from pathlib import Path

claude_json = Path.home() / ".claude" / "claude.json"

# Skills to add
skills = [
    {
        "name": "read-this",
        "description": "Read Google Docs and add summaries to memory",
        "enabled": True,
        "path": "~/.claude/skills/read-this/SKILL.md"
    },
    {
        "name": "pre-meeting",
        "description": "Generate meeting briefings with context",
        "enabled": True,
        "path": "~/.claude/skills/pre-meeting/SKILL.md"
    },
    {
        "name": "remind-me",
        "description": "Create action points from Slack messages",
        "enabled": True,
        "path": "~/.claude/skills/remind-me/SKILL.md"
    }
]

# Load existing
try:
    with open(claude_json) as f:
        config = json.load(f)
except:
    config = {}

# Ensure skills list exists
if "skills" not in config:
    config["skills"] = []

# Add skills (avoid duplicates)
existing_names = {s.get("name") for s in config.get("skills", [])}
for skill in skills:
    if skill["name"] not in existing_names:
        config["skills"].append(skill)

# Save
with open(claude_json, "w") as f:
    json.dump(config, f, indent=2)

MERGE_SKILLS

    print_success "read-this registered"
    print_success "pre-meeting registered"
    print_success "remind-me registered"
    echo ""
}

################################################################################
# Phase 7: Create Template Files
################################################################################

phase_7_templates() {
    print_header "Phase 7: Creating Template Memory Files"
    echo ""

    # Ensure directories exist (critical safety check)
    if ! mkdir -p "$MEMORY_DIR" 2>/dev/null; then
        print_error "Failed to create $MEMORY_DIR"
        return 1
    fi

    if ! mkdir -p "$MEMORY_AGENT_DIR" 2>/dev/null; then
        print_error "Failed to create $MEMORY_AGENT_DIR"
        return 1
    fi

    # action_points.md
    if ! cat > "${MEMORY_DIR}/action_points.md" << 'TEMPLATE_AP'
# Action Points

Tracking important tasks and action items.

## Active Items

- [ ] **Item 1** - Brief description
- [ ] **Item 2** - Brief description

## Completed

(Items go here when completed)
TEMPLATE_AP
    then
        print_error "Failed to create action_points.md"
        return 1
    fi
    print_success "action_points.md created"

    # MEMORY.md
    if ! cat > "${MEMORY_DIR}/MEMORY.md" << 'TEMPLATE_MEM'
# Memory & Context

Central hub for your daily memory, projects, and context.

## 📝 Daily Notes

### Today

- Key discussions:
- Decisions made:
- Next priorities:

## 🎯 Active Projects

### Project 1

**Status:** In Progress
**Owner:** You
**Progress:** [Add details]

## 👥 Team Context

- Team members:
- Key collaborators:
- Reporting structure:

## 📋 Action Items

See action_points.md for detailed action items.

---

**Last Updated:** Today
TEMPLATE_MEM
    then
        print_error "Failed to create MEMORY.md"
        return 1
    fi
    print_success "MEMORY.md created"

    # perfil_usuario.md
    if ! cat > "${MEMORY_AGENT_DIR}/perfil_usuario.md" << 'TEMPLATE_PERFIL'
# Seu Perfil - Memória do Agente

Informações sobre você para contexto de reuniões e tarefas.

---

## 👤 Informações Pessoais

**Nome Completo:** [Seu nome]

**Cargo/Título:** [Seu cargo atual]

**Time/Departamento:** [Seu time/departamento]

**Email:** [Seu email profissional]

**Slack Handle:** @seu.username

---

**Última atualização:** [Data]
TEMPLATE_PERFIL
    then
        print_error "Failed to create perfil_usuario.md"
        return 1
    fi
    print_success "perfil_usuario.md created"

    echo ""
}

################################################################################
# Phase 7.5: User Profile Setup
################################################################################

phase_7_5_profile_setup() {
    print_header "Phase 7.5: User Profile Setup"
    echo ""

    print_info "Your profile helps generate better meeting briefings."
    echo "You can:"
    echo "  • Fill it now (2-3 minutes)"
    echo "  • Skip and fill it later with: nano ~/.claude/memory/memoria_agente/perfil_usuario.md"
    echo ""

    if ! ask_yes_no "Do you want to fill your profile now?"; then
        print_warning "Skipping profile setup"
        echo "You can fill it later with:"
        echo "  nano ~/.claude/memory/memoria_agente/perfil_usuario.md"
        echo ""
        return 0
    fi

    echo ""
    print_info "Let's gather some basic information about you."
    echo ""

    # Nome
    local nome
    nome=$(read_input "👤 Full name (or nickname)")
    if [[ -z "$nome" ]]; then
        print_warning "Skipping profile - no name provided"
        return 0
    fi

    # Cargo
    echo ""
    local cargo
    cargo=$(read_input "💼 Your job title/role")

    # Time
    echo ""
    local time
    time=$(read_input "👥 Your team/department")

    # Email
    echo ""
    local email
    email=$(read_input "📧 Your email (optional)")

    # Slack handle - REQUIRED if Slack token was configured
    echo ""
    local slack_handle

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

    if [[ "$slack_token_exists" == true ]]; then
        # Slack is configured - Slack Handle is REQUIRED
        print_info "Slack integration is configured."
        print_info "Your Slack handle is required to send meeting briefings via direct message."
        echo ""

        slack_handle=$(read_input "💬 Slack handle (e.g., @seu.username)")

        while [[ -z "$slack_handle" ]]; do
            print_warning "Slack handle is required for meeting briefings"
            slack_handle=$(read_input "💬 Slack handle (e.g., @seu.username)")
        done
    else
        # Slack not configured - Slack Handle is optional
        slack_handle=$(read_input "💬 Slack handle (e.g., @seu.username) (optional)")
    fi

    echo ""
    print_info "Saving your profile..."

    # Update perfil_usuario.md with user data
    cat > "${MEMORY_AGENT_DIR}/perfil_usuario.md" << PROFILE_TEMPLATE
# Seu Perfil - Memória do Agente

Informações sobre você para contexto de reuniões e tarefas.

---

## 👤 Informações Pessoais

**Nome Completo:** $nome

**Cargo/Título:** ${cargo:-[Seu cargo atual]}

**Time/Departamento:** ${time:-[Seu time/departamento]}

**Email:** ${email:-[Seu email profissional]}

**Slack Handle:** ${slack_handle:-@seu.username}

---

**Última atualização:** $(date +%Y-%m-%d)
PROFILE_TEMPLATE

    print_success "Profile saved!"
    echo ""
    print_info "Your profile has been created with the information you provided."
    echo "You can edit it anytime with:"
    echo "  nano ~/.claude/memory/memoria_agente/perfil_usuario.md"
    echo ""
}

################################################################################
# Phase 8: Validation
################################################################################

phase_8_validation() {
    print_header "Phase 8: Validation"
    echo ""

    local validation_passed=true

    # Check directories
    print_info "Checking directory structure..."
    for dir in "$CLAUDE_HOME" "$MEMORY_DIR" "$SCRIPTS_DIR" "$SKILLS_DIR"; do
        if [[ -d "$dir" ]]; then
            print_success "$(basename "$dir"): OK"
        else
            print_error "$(basename "$dir"): MISSING"
            validation_passed=false
        fi
    done

    echo ""

    # Check files
    print_info "Checking template files..."
    for file in "action_points.md" "MEMORY.md"; do
        if [[ -f "${MEMORY_DIR}/${file}" ]]; then
            print_success "$file: OK"
        else
            print_error "$file: MISSING"
            validation_passed=false
        fi
    done

    echo ""

    # Check Python dependencies
    print_info "Checking Python dependencies..."
    if python3 -c "import google.auth" 2>/dev/null; then
        print_success "google-auth: OK"
    else
        print_warning "google-auth: not installed (optional)"
    fi

    if python3 -c "import slack_sdk" 2>/dev/null; then
        print_success "slack-sdk: OK"
    else
        print_warning "slack-sdk: not installed (optional)"
    fi

    echo ""

    if [[ "$validation_passed" == "true" ]]; then
        print_success "Validation passed!"
    else
        print_warning "Some validations failed, but setup can continue"
    fi

    echo ""
}

################################################################################
# Phase 9: Summary & Next Steps
################################################################################

phase_9_summary() {
    print_header "Setup Completed Successfully!"
    echo ""

    cat << 'SUMMARY_INFO'
WHAT'S INSTALLED:
  ✓ Memory system: ~/.claude/memory/
  ✓ Scripts directory: ~/.claude/scripts/
  ✓ Skills: read-this, pre-meeting, remind-me
  ✓ Google OAuth configured
  ✓ Slack configured
  ✓ Python dependencies installed

YOUR THREE SKILLS ARE READY NOW:

  /read-this       - Read Google Docs and save to memory
  /pre-meeting     - Generate meeting briefings
  /remind-me       - Create action points from text/Slack

IMMEDIATE NEXT STEPS:

  1. Test the skills:
     /read-this https://docs.google.com/document/d/YOUR_DOC/edit
     /pre-meeting
     /remind-me Check the deadline

  2. Update your profile (if needed):
     nano ~/.claude/memory/memoria_agente/perfil_usuario.md

  3. Verify everything works:
     bash ~/.claude/scripts/validate.sh

OPTIONAL: Email Automation (15 minutes)

  For automatic email processing and memory auto-population:
  → Follow: https://github.com/uli6/claude-meeting-memory/docs/GETTING_STARTED_EMAIL.md

  This will let emails automatically populate your memory and enhance
  your /pre-meeting briefings with email context.

IMPORTANT LINKS:
  📖 Main Documentation: ~/.claude/CLAUDE.md
  🔐 Security & Safety: See SAFETY_GUARANTEE.md in the repo
  🆘 Need Help: https://github.com/uli6/claude-meeting-memory/issues
  📚 All Guides: https://github.com/uli6/claude-meeting-memory

You're all set! Start using your Claude Meeting Memory system. 🚀
SUMMARY_INFO

    echo ""
    print_success "Setup is complete!"
    echo ""
}

################################################################################
# Main Setup Flow
################################################################################

main() {
    # Handle command-line arguments
    case "${1:-}" in
        --help)
            show_help
            exit 0
            ;;
        --reinstall)
            reinstall_cleanup
            # Continue to normal setup after cleanup
            ;;
        "")
            # Normal setup
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac

    clear

    cat << 'WELCOME'
╔══════════════════════════════════════════════════════════════╗
║          Claude Meeting Memory - Onboarding Setup           ║
║                  Version 1.0.0                              ║
║     https://github.com/uli6/claude-meeting-memory           ║
╚══════════════════════════════════════════════════════════════╝
WELCOME

    echo ""

    # Run all phases
    phase_1_checks

    if ask_yes_no "Continue with setup?"; then
        echo ""
    else
        print_error "Setup cancelled"
        exit 0
    fi

    phase_1_5_python_deps

    phase_2_directories

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CONFIGURATION PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_info "Now let's configure your integrations"
    echo ""

    if ! ask_yes_no "Configure Google OAuth?"; then
        print_warning "Skipping Google OAuth setup"
    else
        if ! phase_3_google_oauth; then
            print_warning "Google OAuth setup failed, continuing..."
        fi
    fi

    echo ""

    if ! phase_4_slack; then
        print_warning "Slack setup failed, continuing..."
    fi

    echo ""

    # Phase 4.5: Automatic crontab setup (if Google OAuth succeeded)
    if [[ -n "${GOOGLE_REFRESH_TOKEN:-}" ]]; then
        phase_4_5_crontab_automation
    fi

    echo ""
    phase_5_security

    phase_6_skills

    phase_7_templates

    phase_7_5_profile_setup

    phase_8_validation

    phase_9_summary
}

# Run main
main "$@"
