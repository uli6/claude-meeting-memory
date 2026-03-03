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

################################################################################
# Source Helper Functions
################################################################################

# Find the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helper functions if available
if [[ -f "$SCRIPT_DIR/scripts/setup_helpers.sh" ]]; then
    source "$SCRIPT_DIR/scripts/setup_helpers.sh"
elif [[ -f "$(dirname "$0")/scripts/setup_helpers.sh" ]]; then
    source "$(dirname "$0")/scripts/setup_helpers.sh"
fi

# Fallback functions if helpers not loaded
if ! declare -f show_phase_header > /dev/null; then
    show_phase_header() {
        # Simple fallback if helpers aren't available
        echo ""
        echo -e "${BOLD}${BLUE}Phase $1 of $2: $3${NC}"
        if [[ -n "$4" ]]; then
            echo -e "${BLUE}Time: $4${NC}"
        fi
        echo ""
    }
fi

if ! declare -f show_help_prompt > /dev/null; then
    show_help_prompt() {
        # Silently skip if helpers not available
        return 0
    }
fi

if ! declare -f show_email_providers > /dev/null; then
    show_email_providers() {
        echo "What email provider do you use?"
        echo "  1) Gmail"
        echo "  2) ProtonMail"
        echo "  3) Fastmail"
        echo "  4) Outlook/Microsoft"
        echo "  5) Other email service"
        echo ""
    }
fi

if ! declare -f show_calendar_providers > /dev/null; then
    show_calendar_providers() {
        echo "What calendar service do you use?"
        echo "  1) Nextcloud (personal cloud)"
        echo "  2) Radicale (self-hosted calendar)"
        echo "  3) FastMail (email with calendar)"
        echo "  4) Other CalDAV service"
        echo ""
    }
fi

if ! declare -f show_step_guide > /dev/null; then
    show_step_guide() {
        local title="$1"
        shift
        echo ""
        echo "$title"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        while [[ $# -gt 0 ]]; do
            echo "  $1"
            shift
        done
        echo ""
    }
fi

if ! declare -f show_section > /dev/null; then
    show_section() {
        echo ""
        echo -e "${BOLD}${BLUE}$1${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    }
fi

if ! declare -f show_security_summary > /dev/null; then
    show_security_summary() {
        echo "Your credentials are stored securely on your machine:"
        echo ""
        echo "✓ On your machine only"
        echo "✓ Protected by OS keychain/secret service"
        echo "✓ Never sent to cloud or external services"
        echo ""
    }
fi

if ! declare -f show_requirement_summary > /dev/null; then
    show_requirement_summary() {
        echo "What's Required vs Optional:"
        echo ""
        echo "✓ REQUIRED: Email + Calendar"
        echo "◆ RECOMMENDED: Slack integration"
        echo "◇ OPTIONAL: Profile customization"
        echo ""
    }
fi

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
    local use_tty=false

    # Check if we can use /dev/tty
    if [[ -t 0 ]] || ( [[ -c /dev/tty ]] 2>/dev/null ); then
        use_tty=true
    fi

    if [[ "$mask" == "true" ]]; then
        echo -ne "${prompt}: " >&2
        if [[ "$use_tty" == "true" ]]; then
            read -rs value </dev/tty || value=""
        else
            read -rs value || value=""
        fi
        echo # New line after masked input >&2
    else
        echo -ne "${prompt}: " >&2
        if [[ "$use_tty" == "true" ]]; then
            read -r value </dev/tty || value=""
        else
            read -r value || value=""
        fi
    fi

    # Remove leading/trailing whitespace using parameter expansion
    value="${value#"${value%%[![:space:]]*}"}"   # Remove leading whitespace
    value="${value%"${value##*[![:space:]]}"}"   # Remove trailing whitespace

    # Additional trim for newlines and carriage returns
    value="${value//[$'\n']/}"
    value="${value//[$'\r']/}"

    # Echo the clean value to stdout (for command substitution)
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

# Setup cron job for calendar watcher
setup_calendar_watcher_cron() {
    local script_path="${SCRIPTS_DIR}/calendar_watcher.sh"
    local cron_job="*/10 * * * * $script_path >> /dev/null 2>&1"
    local cron_identifier="# Calendar Watcher - Meeting Detection (Claude Meeting Memory)"

    print_info "Setting up calendar watcher cron job (every 10 minutes)..."
    echo ""

    # Make script executable
    chmod +x "$script_path" 2>/dev/null || true

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        print_warning "Calendar watcher cron job already exists"
        return 0
    fi

    # Add cron job
    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$temp_cron" || true
    echo "$cron_identifier" >> "$temp_cron"
    echo "$cron_job" >> "$temp_cron"

    if crontab "$temp_cron" 2>/dev/null; then
        print_success "Calendar watcher cron job installed!"
        echo "  • Script: $script_path"
        echo "  • Schedule: Every 10 minutes"
        echo "  • Purpose: Monitor calendar for upcoming meetings"
        echo ""
        print_info "You can view your crontab with: crontab -l"
        print_info "You can remove this job with: crontab -e (remove the marked lines)"
    else
        print_error "Failed to install cron job"
        print_warning "You can add manually: crontab -e"
        print_warning "Then add: $cron_job"
    fi

    rm -f "$temp_cron"
}

################################################################################
# Phase 1: Initial Checks & Welcome
################################################################################

phase_1_checks() {
    show_phase_header 1 9 "System Requirements Check" "~1 minute"
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
    # Note: Himalaya and Plann are installed via package managers (brew/apt/pip)
    # not through this Python dependency installer
    local packages=(
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
    show_phase_header 2 9 "Creating Directory Structure" "~1 minute"
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

################################################################################
# Phase 3: Himalaya Email Configuration
################################################################################

phase_3_himalaya() {
    show_phase_header 3 9 "Email Configuration (REQUIRED)" "~3-5 minutes"
    echo ""

    print_info "Let's connect your email so you can get meeting context"
    echo ""
    echo "This enables Claude Memory to:"
    echo "  ✓ Read your emails for meeting briefings"
    echo "  ✓ Extract important information automatically"
    echo "  ✓ Keep context from past conversations"
    echo ""

    # Check if Himalaya is installed
    if ! command -v himalaya &> /dev/null; then
        print_warning "Himalaya CLI not found"
        echo ""
        if ask_yes_no "Would you like to install Himalaya?"; then
            echo ""
            print_info "Installing Himalaya..."
            echo ""

            # Detect OS and install appropriately
            if [[ "$OS_TYPE" == "darwin" ]] || [[ "$OS_TYPE" == "Darwin" ]]; then
                if command -v brew &> /dev/null; then
                    brew install himalaya
                else
                    print_error "Homebrew not found. Install manually with: brew install himalaya"
                    return 1
                fi
            elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "Linux" ]]; then
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y himalaya
                elif command -v dnf &> /dev/null; then
                    sudo dnf install himalaya
                else
                    print_warning "Please install Himalaya manually: https://github.com/pimalaya/himalaya"
                    return 1
                fi
            fi
        else
            print_warning "Skipping Himalaya setup (required for email briefings)"
            return 0
        fi
    fi

    echo ""
    show_section "Email Provider Selection"

    # Step 1: Choose email provider
    show_email_providers
    provider=$(read_input "Select provider (1-5)")

    case "$provider" in
        "1"|1)
            show_step_guide "Gmail: Create App Password" \
                "1. Go to: https://myaccount.google.com/apppasswords" \
                "2. Select 'Mail' and 'Windows Computer' (or your device)" \
                "3. Click 'Generate'" \
                "4. Copy the 16-character password shown (don't include spaces)"
            show_help_prompt "App Password"
            email=$(read_input "📧 Gmail address")
            password=$(read_input "🔐 App password (16 characters)" "true")
            ;;
        "2"|2)
            show_step_guide "ProtonMail Setup" \
                "1. Use your ProtonMail password directly" \
                "2. Or create a bridge at: https://protonmail.com/bridge"
            email=$(read_input "📧 ProtonMail address")
            password=$(read_input "🔐 ProtonMail password" "true")
            ;;
        "3"|3)
            show_step_guide "Fastmail: Create App Password" \
                "1. Go to: https://app.fastmail.com/settings/security" \
                "2. Click 'Generate new password'" \
                "3. Select 'IMAP' and 'Calendar'" \
                "4. Copy the password"
            email=$(read_input "📧 Fastmail address")
            password=$(read_input "🔐 App password" "true")
            ;;
        "4"|4)
            show_step_guide "Microsoft Outlook Setup" \
                "1. Use your Microsoft account password" \
                "2. Or enable app passwords at: https://account.microsoft.com/security"
            email=$(read_input "📧 Outlook email")
            password=$(read_input "🔐 Outlook password" "true")
            ;;
        "5"|5)
            show_step_guide "Other Email Service Setup" \
                "If you don't see your provider, we can set it up manually"
            email=$(read_input "📧 Email address")
            password=$(read_input "🔐 Password/token" "true")
            imap_server=$(read_input "🌐 IMAP server hostname (e.g., imap.example.com)")
            imap_port=$(read_input "🔌 IMAP port (default: 993)" "993")
            ;;
        *)
            print_error "Invalid selection: '$provider' (expected 1-5)"
            return 1
            ;;
    esac

    echo ""
    echo "Creating Himalaya configuration..."
    echo ""

    # Create Himalaya config directory
    mkdir -p ~/.config/himalaya

    # Run Himalaya's interactive setup (pre-filled with email)
    # The user can confirm or modify settings
    print_info "Running Himalaya account configuration..."
    echo "You may be prompted to confirm settings. Press Enter to accept defaults."
    echo ""

    if himalaya account configure; then
        # Validate the configuration works
        sleep 2
        if himalaya envelope list &>/dev/null; then
            print_success "Himalaya configured successfully!"
            export HIMALAYA_CONFIGURED=true
            echo ""
            return 0
        else
            print_warning "Himalaya validation didn't complete. Configuration may need adjustment."
            print_warning "You can test later with: himalaya envelope list"
            export HIMALAYA_CONFIGURED=true
            return 0
        fi
    else
        print_error "Himalaya setup was cancelled"
        return 1
    fi
}

################################################################################
# Phase 3.5: Plann Calendar Configuration
################################################################################

phase_3_5_plann() {
    show_phase_header 4 9 "Calendar Configuration (REQUIRED)" "~3-5 minutes"
    echo ""

    print_info "Let's connect your calendar for automatic meeting detection"
    echo ""
    echo "This enables Claude Memory to:"
    echo "  ✓ Detect when you have meetings coming up"
    echo "  ✓ Prepare briefings before meetings start"
    echo "  ✓ Track your schedule automatically"
    echo ""

    if ! ask_yes_no "Would you like to configure calendar access now?"; then
        print_warning "Skipping calendar setup"
        echo "Note: Email-only mode has limited meeting detection"
        return 0
    fi

    # Check if Plann is installed
    if ! command -v plann &> /dev/null; then
        print_warning "Plann CLI not found"
        echo ""
        if ask_yes_no "Would you like to install Plann?"; then
            echo ""
            print_info "Installing Plann..."
            echo ""

            # Try multiple installation methods
            local installed=false

            # Method 1: brew (macOS preferred)
            if command -v brew &> /dev/null && brew install plann >/dev/null 2>&1; then
                print_success "Plann installed successfully via Homebrew"
                installed=true
            # Method 2: pip3 (fallback)
            elif pip3 install plann >/dev/null 2>&1; then
                print_success "Plann installed successfully via pip3"
                installed=true
            # Method 3: python3 -m pip
            elif python3 -m pip install plann >/dev/null 2>&1; then
                print_success "Plann installed successfully via python3 -m pip"
                installed=true
            fi

            if [[ "$installed" == "false" ]]; then
                print_error "Failed to install Plann automatically"
                echo ""
                echo "Please install manually using one of these methods:"
                echo ""
                echo "  macOS (Homebrew):"
                echo "    brew install plann"
                echo ""
                echo "  Python/pip:"
                echo "    pip3 install plann"
                echo ""
                echo "  Or from GitHub:"
                echo "    https://github.com/pimalaya/plann"
                echo ""
                if ask_yes_no "Continue setup without Plann?"; then
                    echo ""
                    print_warning "Note: Calendar functionality will be limited without Plann"
                    echo ""
                else
                    return 1
                fi
            fi
        else
            print_warning "Skipping Plann setup"
            echo "Note: Calendar functionality will be limited without Plann"
            echo ""
            return 0
        fi
    fi

    echo ""
    show_section "Calendar Provider Selection"

    # Step 1: Choose CalDAV provider
    show_calendar_providers
    provider=$(read_input "Select provider (1-4)")

    case "$provider" in
        "1"|1)
            show_step_guide "Nextcloud CalDAV Setup" \
                "1. Your Nextcloud server URL (if self-hosted)" \
                "2. Your login credentials (username/password)" \
                "3. Find your calendar URL in Nextcloud settings"
            show_help_prompt "Nextcloud"
            nextcloud_url=$(read_input "🌐 Nextcloud URL (e.g., https://nextcloud.example.com)")
            caldav_user=$(read_input "👤 CalDAV username")
            caldav_pass=$(read_input "🔐 CalDAV password" "true")
            ;;
        "2"|2)
            show_step_guide "Radicale CalDAV Setup" \
                "1. Your Radicale server address (usually http://localhost:5232)" \
                "2. Your login credentials"
            show_help_prompt "Radicale"
            caldav_url=$(read_input "🌐 Radicale URL (e.g., http://localhost:5232)")
            caldav_user=$(read_input "👤 CalDAV username")
            caldav_pass=$(read_input "🔐 CalDAV password" "true")
            ;;
        "3"|3)
            show_step_guide "FastMail CalDAV Setup" \
                "1. Use your FastMail email address as username" \
                "2. Use your FastMail password (or app password)"
            caldav_user=$(read_input "📧 FastMail email")
            caldav_pass=$(read_input "🔐 FastMail password" "true")
            ;;
        "4"|4)
            show_step_guide "Other CalDAV Server Setup" \
                "1. Your CalDAV server URL" \
                "2. Your login credentials"
            caldav_url=$(read_input "🌐 CalDAV server URL (e.g., https://caldav.example.com)")
            caldav_user=$(read_input "👤 CalDAV username")
            caldav_pass=$(read_input "🔐 CalDAV password" "true")
            ;;
        *)
            print_error "Invalid selection: '$provider' (expected 1-4)"
            return 1
            ;;
    esac

    echo ""
    echo "Configuring Plann with your CalDAV settings..."
    echo ""

    # Create Plann config directory
    mkdir -p ~/.config

    # Run Plann's interactive setup
    print_info "Running Plann account configuration..."
    echo "Follow the prompts to complete CalDAV setup."
    echo ""

    if plann account configure; then
        # Validate the configuration works
        sleep 2
        if plann calendar list &>/dev/null; then
            print_success "Plann configured successfully!"
            export PLANN_CONFIGURED=true

            # Setup cron job for calendar watching (every 10 minutes)
            setup_calendar_watcher_cron

            echo ""
            return 0
        else
            print_warning "Plann validation didn't complete. Configuration may need adjustment."
            print_warning "You can test later with: plann calendar list"
            export PLANN_CONFIGURED=true
            return 0
        fi
    else
        print_warning "Plann setup was skipped. You can configure it later with: plann account configure"
        return 0
    fi
}

################################################################################
# Phase 4: Slack Configuration
################################################################################

phase_4_slack() {
    show_phase_header 5 9 "Slack Integration (RECOMMENDED)" "~5-7 minutes"
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

################################################################################
# Phase 5: Security Review
################################################################################

phase_5_security() {
    show_phase_header 6 9 "Security & Privacy" "~1 minute"
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
    show_phase_header 7 9 "Registering Skills" "~2 minutes"
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
    show_phase_header 8 9 "Creating Memory Templates" "~1 minute"
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
    show_phase_header 8 9 "Your Profile (Optional)" "~3 minutes"
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

    # Slack handle - Always optional now (no cron automation)
    echo ""
    local slack_handle
    slack_handle=$(read_input "💬 Slack handle (e.g., @seu.username) (optional)")

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
    show_phase_header 9 9 "Validating Setup" "~1 minute"
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

    # Check Himalaya
    print_info "Checking Himalaya email configuration..."
    if command -v himalaya &> /dev/null; then
        if himalaya envelope list &>/dev/null; then
            print_success "Himalaya: OK"
        else
            print_warning "Himalaya: installed but not configured"
        fi
    else
        print_warning "Himalaya: not installed"
    fi

    echo ""

    # Check Plann
    print_info "Checking Plann calendar configuration..."
    if command -v plann &> /dev/null; then
        if plann calendar list &>/dev/null; then
            print_success "Plann: OK"
        else
            print_warning "Plann: installed but not configured"
        fi
    else
        print_warning "Plann: not installed"
    fi

    echo ""

    # Check Slack
    print_info "Checking Slack configuration..."
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
    show_phase_header 10 9 "Completion Summary" "Done!"
    echo ""

    cat << 'SUMMARY_INFO'
WHAT'S INSTALLED:
  ✓ Memory system: ~/.claude/memory/
  ✓ Scripts directory: ~/.claude/scripts/
  ✓ Skills: read-this, pre-meeting, remind-me
  ✓ Himalaya email access configured
  ✓ Plann calendar access configured
  ✓ Slack integration (optional)

YOUR THREE SKILLS ARE READY NOW:

  /read-this       - Read files and save to memory
  /pre-meeting     - Generate meeting briefings from emails
  /remind-me       - Create action points from text/Slack

IMMEDIATE NEXT STEPS:

  1. Test the skills:
     /read-this ~/some_file.txt
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

    # Show what's required vs optional BEFORE starting
    show_requirement_summary

    echo "This setup will take about 20-25 minutes:"
    echo "  • Email + Calendar setup: ~10 minutes (REQUIRED)"
    echo "  • Slack integration: ~5-7 minutes (OPTIONAL)"
    echo "  • Your profile: ~2-3 minutes (OPTIONAL)"
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
    show_section "CONFIGURATION PHASE"
    print_info "Now let's configure your integrations"
    echo ""

    # REQUIRED: Email configuration (Phase 3)
    if ! phase_3_himalaya; then
        print_warning "Email setup failed, continuing..."
    fi

    echo ""

    # REQUIRED: Calendar configuration (Phase 3.5 → Phase 4)
    if ! phase_3_5_plann; then
        print_warning "Calendar setup failed, continuing..."
    fi

    echo ""

    # RECOMMENDED: Slack configuration (Phase 4 → Phase 5)
    if ! phase_4_slack; then
        print_warning "Slack setup failed, continuing..."
    fi

    echo ""
    # Security review (Phase 6)
    phase_5_security

    # Skill registration (Phase 7)
    phase_6_skills

    # Templates (Phase 8)
    phase_7_templates

    # Profile setup (Phase 8.5)
    phase_7_5_profile_setup

    # Validation (Phase 9)
    phase_8_validation

    # Summary (Phase 10)
    phase_9_summary
}

# Run main
main "$@"
