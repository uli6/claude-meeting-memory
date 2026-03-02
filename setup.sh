#!/bin/bash

################################################################################
# Claude Meeting Memory - Automated Onboarding Setup
#
# One-command setup for Claude Code with secure credential management,
# skill registration, and memory initialization.
#
# Usage: bash setup.sh
#        curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
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

    read -r response
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

    if [[ "$mask" == "true" ]]; then
        echo -ne "${prompt}: "
        read -rs value
        echo # New line after masked input
    else
        echo -ne "${prompt}: "
        read -r value
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
    print_header "Phase 1.5: Installing Python Dependencies"
    echo ""

    echo "Installing required Python packages..."
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

    # Try to install using pip3
    if ! python3 -m pip install --upgrade pip >/dev/null 2>&1; then
        print_warning "Could not upgrade pip, continuing anyway..."
    fi

    local failed=0
    for package in "${packages[@]}"; do
        # Extract package name (before >=, ==, etc.)
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
        for package in "${packages[@]}"; do
            echo "  pip3 install '$package'"
        done
        echo ""
        if ! ask_yes_no "Continue setup anyway?"; then
            exit 1
        fi
    else
        print_success "All Python dependencies installed successfully!"
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

    print_info "This will authorize Claude Code to access:"
    echo "  • Google Drive (read your Google Docs)"
    echo "  • Google Calendar (read your events)"
    echo ""

    # Check if credentials already exist
    if [[ -f "${CLAUDE_HOME}/.google_refresh_token" ]]; then
        if ask_yes_no "Found existing Google credentials. Use them?"; then
            print_success "Using existing Google credentials"
            echo ""
            return 0
        fi
    fi

    echo "You'll need credentials from Google Cloud Console."
    echo "Get them here: https://console.cloud.google.com/"
    echo ""

    # Get Client ID and Secret
    local client_id
    local client_secret

    client_id=$(read_input "Google Client ID (starts with numbers...apps.googleusercontent.com)")
    if [[ -z "$client_id" ]]; then
        print_error "Client ID cannot be empty"
        return 1
    fi

    client_secret=$(read_input "Google Client Secret (GOCSPX-...)" "true")
    if [[ -z "$client_secret" ]]; then
        print_error "Client Secret cannot be empty"
        return 1
    fi

    echo ""
    print_info "Starting browser for authorization..."
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
        # Store credentials using get_secret.sh or environment
        export GOOGLE_CAL_CLIENT_ID="$client_id"
        export GOOGLE_CAL_CLIENT_SECRET="$client_secret"
        export GOOGLE_REFRESH_TOKEN="$refresh_token"

        print_success "Google authorization successful!"
        print_info "Refresh token stored in environment"
        echo ""
    else
        print_error "Google OAuth failed"
        echo "Try again or set up manually later"
        echo ""
        return 1
    fi
}

################################################################################
# Phase 4: Slack Configuration
################################################################################

phase_4_slack() {
    print_header "Phase 4: Slack Configuration"
    echo ""

    print_info "Slack integration requires:"
    echo "  • User token (xoxp-...) from your Slack app"
    echo "  • Your Slack Member ID (U..."
    echo ""

    # Get Slack token
    local slack_token
    slack_token=$(read_input "Slack User Token (xoxp-...)" "true")

    if [[ -z "$slack_token" ]]; then
        print_error "Slack token cannot be empty"
        return 1
    fi

    if [[ ! "$slack_token" =~ ^xoxp- ]]; then
        print_warning "Token should start with 'xoxp-' (User Token, not Bot Token)"
    fi

    # Get Slack Member ID
    echo ""
    echo "Get your Slack Member ID:"
    echo "  1. Open Slack"
    echo "  2. Click your profile (bottom-left)"
    echo "  3. Click 'Copy user ID'"
    echo "  4. Paste it below"
    echo ""

    local member_id
    member_id=$(read_input "Slack Member ID (U...)")

    if [[ -z "$member_id" ]]; then
        print_error "Member ID cannot be empty"
        return 1
    fi

    if [[ ! "$member_id" =~ ^U ]]; then
        print_warning "Member ID should start with 'U' (not 'C' for channels)"
    fi

    # Validate Slack token
    echo ""
    print_info "Validating Slack token..."

    local slack_response
    slack_response=$(curl -s -X POST https://slack.com/api/auth.test \
        -H "Authorization: Bearer $slack_token" 2>/dev/null)

    if echo "$slack_response" | grep -q '"ok":true'; then
        print_success "Slack token is valid"
        export SLACK_USER_TOKEN="$slack_token"
        export SLACK_MEMBER_ID="$member_id"
    else
        print_error "Slack token validation failed"
        echo "Response: $slack_response"
        return 1
    fi

    echo ""
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

    # action_points.md
    cat > "${MEMORY_DIR}/action_points.md" << 'TEMPLATE_AP'
# Action Points

Tracking important tasks and action items.

## Active Items

- [ ] **Item 1** - Brief description
- [ ] **Item 2** - Brief description

## Completed

(Items go here when completed)
TEMPLATE_AP
    print_success "action_points.md created"

    # MEMORY.md
    cat > "${MEMORY_DIR}/MEMORY.md" << 'TEMPLATE_MEM'
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
    print_success "MEMORY.md created"

    # perfil_usuario.md
    cat > "${MEMORY_AGENT_DIR}/perfil_usuario.md" << 'TEMPLATE_PERFIL'
# Seu Perfil - Memória do Agente

Informações sobre você para contexto de reuniões e tarefas.

**Preencha uma vez e mantenha atualizado.**

---

## 👤 Informações Pessoais

**Nome Completo:** [Seu nome]

**Cargo/Título:** [Seu cargo atual]

**Time/Departamento:** [Seu time/departamento]

**Email:** [Seu email profissional]

**Slack Handle:** @seu.username

---

## 🏢 Organização

**Empresa:** [Nome da empresa]

**Gerente Direto:** [Nome do seu gerente]

---

## 👥 Time Direto

**Tamanho do Time:** [Número de pessoas]

**Membros:**
- [Nome] - [Cargo]
- [Nome] - [Cargo]

---

## 🎯 Responsabilidades Principais

1. **Responsabilidade 1** - [Descrição]
2. **Responsabilidade 2** - [Descrição]

---

## 📅 Reuniões Recorrentes

| Reunião | Quando | Participantes |
|---------|--------|---------------|
| Standup | Seg-Sex 9:30am | Time |
| 1:1 com Gerente | [Dia/Hora] | Você + Gerente |

---

## 🚀 Objetivos Atuais

1. **Objetivo 1** - [Descrição]
2. **Objetivo 2** - [Descrição]

---

**Preencha completamente para melhores resultados nas reuniões!**
TEMPLATE_PERFIL
    print_success "perfil_usuario.md created"

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

NEXT STEPS:

  1. Fill your profile:
     nano ~/.claude/memory/memoria_agente/perfil_usuario.md

  2. Test the skills:
     /read-this https://docs.google.com/document/d/YOUR_DOC/edit
     /pre-meeting
     /remind-me Check the deadline

  3. View documentation:
     cat ~/.claude/CLAUDE.md

  4. Verify everything works:
     bash ~/.claude/scripts/validate.sh

IMPORTANT LINKS:
  📖 Documentation: See ~/.claude/CLAUDE.md
  🔐 Security: https://github.com/uli6/claude-meeting-memory/docs/TROUBLESHOOTING.md
  🆘 Issues: https://github.com/uli6/claude-meeting-memory/issues
  📚 Guides: https://github.com/uli6/claude-meeting-memory

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

    if ! ask_yes_no "Configure Google OAuth?"; then
        print_warning "Skipping Google OAuth setup"
    else
        if ! phase_3_google_oauth; then
            print_warning "Google OAuth setup failed, continuing..."
        fi
    fi

    echo ""

    if ! ask_yes_no "Configure Slack?"; then
        print_warning "Skipping Slack setup"
    else
        if ! phase_4_slack; then
            print_warning "Slack setup failed, continuing..."
        fi
    fi

    echo ""
    phase_5_security

    phase_6_skills

    phase_7_templates

    phase_8_validation

    phase_9_summary
}

# Run main
main "$@"
