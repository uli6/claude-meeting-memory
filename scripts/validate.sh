#!/bin/bash

################################################################################
# validate.sh - Post-Setup Validation Script
#
# Validates that all components of Claude Meeting Memory are properly installed
# and configured.
#
# Usage: bash ~/.claude/scripts/validate.sh
#
# Checks:
#   - Directory structure
#   - Google OAuth credentials
#   - Slack credentials
#   - Skills registration
#   - Python dependencies
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
CLAUDE_HOME="${HOME}/.claude"
MEMORY_DIR="${CLAUDE_HOME}/memory"
SCRIPTS_DIR="${CLAUDE_HOME}/scripts"
SKILLS_DIR="${CLAUDE_HOME}/skills"

# Results tracking
PASSED=0
FAILED=0
WARNINGS=0

################################################################################
# Utility Functions
################################################################################

print_header() {
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

################################################################################
# Validation Tests
################################################################################

test_directory_structure() {
    print_header "Directory Structure"
    echo ""

    local dirs=(
        "$CLAUDE_HOME"
        "$MEMORY_DIR"
        "$SCRIPTS_DIR"
        "$SKILLS_DIR"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "$dir exists"
        else
            print_error "$dir missing"
        fi
    done

    echo ""
}

test_template_files() {
    print_header "Template Files"
    echo ""

    local files=(
        "${MEMORY_DIR}/action_points.md"
        "${MEMORY_DIR}/MEMORY.md"
        "${CLAUDE_HOME}/claude.json"
    )

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "$(basename "$file") exists"
        else
            print_error "$(basename "$file") missing"
        fi
    done

    echo ""
}

test_python_dependencies() {
    print_header "Python Dependencies"
    echo ""

    # Check Python version
    if python3 --version &>/dev/null; then
        version=$(python3 --version 2>&1)
        print_success "python3: $version"
    else
        print_error "python3: not found"
        return
    fi

    # Check google-auth
    if python3 -c "import google.auth" 2>/dev/null; then
        print_success "google-auth: installed"
    else
        print_warning "google-auth: not installed (required for /read-this)"
    fi

    # Check slack-sdk
    if python3 -c "import slack_sdk" 2>/dev/null; then
        print_success "slack-sdk: installed"
    else
        print_warning "slack-sdk: not installed (required for /remind-me)"
    fi

    # Check google-api-client
    if python3 -c "import googleapiclient" 2>/dev/null; then
        print_success "google-api-client: installed"
    else
        print_warning "google-api-client: not installed (required for /pre-meeting)"
    fi

    echo ""
}

test_google_oauth() {
    print_header "Google OAuth Credentials"
    echo ""

    # Look for Google credentials in various places
    found=false

    # Check environment variables
    if [[ -n "${GOOGLE_REFRESH_TOKEN:-}" ]]; then
        print_success "GOOGLE_REFRESH_TOKEN: set in environment"
        found=true
    fi

    if [[ -n "${GOOGLE_CAL_CLIENT_ID:-}" ]]; then
        print_success "GOOGLE_CAL_CLIENT_ID: set in environment"
        found=true
    fi

    # Check keychain (macOS)
    if [[ "$(uname)" == "Darwin" ]]; then
        if security find-generic-password -a "$USER" -s "claude-code-google-refresh-token" 2>/dev/null; then
            print_success "Google token: stored in Keychain"
            found=true
        fi
    fi

    # Check Secret Service (Linux)
    if command -v secret-tool &>/dev/null; then
        if secret-tool lookup google-refresh-token 2>/dev/null; then
            print_success "Google token: stored in Secret Service"
            found=true
        fi
    fi

    if [[ "$found" == "false" ]]; then
        print_warning "Google credentials not found (optional)"
    fi

    echo ""
}

test_slack_credentials() {
    print_header "Slack Credentials"
    echo ""

    # Look for Slack credentials
    found=false

    if [[ -n "${SLACK_USER_TOKEN:-}" ]]; then
        print_success "SLACK_USER_TOKEN: set in environment"
        found=true
    fi

    if [[ -n "${SLACK_MEMBER_ID:-}" ]]; then
        print_success "SLACK_MEMBER_ID: set in environment"
        found=true
    fi

    # Check keychain (macOS)
    if [[ "$(uname)" == "Darwin" ]]; then
        if security find-generic-password -a "$USER" -s "claude-code-slack-user-token" 2>/dev/null; then
            print_success "Slack token: stored in Keychain"
            found=true
        fi
    fi

    # Check Secret Service (Linux)
    if command -v secret-tool &>/dev/null; then
        if secret-tool lookup slack-user-token 2>/dev/null; then
            print_success "Slack token: stored in Secret Service"
            found=true
        fi
    fi

    if [[ "$found" == "false" ]]; then
        print_warning "Slack credentials not found (optional)"
    fi

    echo ""
}

test_skills_registration() {
    print_header "Skills Registration"
    echo ""

    if [[ ! -f "${CLAUDE_HOME}/claude.json" ]]; then
        print_error "claude.json not found"
        echo ""
        return
    fi

    # Check if skills are registered
    local skills=("read-this" "pre-meeting" "remind-me")

    for skill in "${skills[@]}"; do
        if grep -q "\"$skill\"" "${CLAUDE_HOME}/claude.json" 2>/dev/null; then
            print_success "$skill: registered in claude.json"
        else
            print_warning "$skill: not registered"
        fi
    done

    echo ""
}

test_script_permissions() {
    print_header "Script Permissions"
    echo ""

    local scripts=(
        "${SCRIPTS_DIR}/get_secret.sh"
        "${SCRIPTS_DIR}/secrets_helper.py"
        "${SCRIPTS_DIR}/validate.sh"
    )

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                print_success "$(basename "$script"): executable"
            else
                print_warning "$(basename "$script"): not executable (consider: chmod +x)"
            fi
        else
            print_warning "$(basename "$script"): not found"
        fi
    done

    echo ""
}

test_file_permissions() {
    print_header "File Permissions"
    echo ""

    # Check .claude directory permissions (should be 700)
    if [[ -d "$CLAUDE_HOME" ]]; then
        perms=$(stat -f%A "$CLAUDE_HOME" 2>/dev/null || stat -c %a "$CLAUDE_HOME" 2>/dev/null || echo "unknown")
        if [[ "$perms" == "700" ]] || [[ "$perms" == "unknown" ]]; then
            print_success "$CLAUDE_HOME: permissions OK"
        else
            print_warning "$CLAUDE_HOME: permissions are $perms (should be 700)"
        fi
    fi

    echo ""
}

################################################################################
# Summary
################################################################################

print_summary() {
    print_header "Validation Summary"
    echo ""

    echo -e "${GREEN}✓ Passed: $PASSED${NC}"
    echo -e "${RED}✗ Failed: $FAILED${NC}"
    echo -e "${YELLOW}⚠ Warnings: $WARNINGS${NC}"
    echo ""

    if [[ $FAILED -eq 0 ]]; then
        if [[ $WARNINGS -eq 0 ]]; then
            print_success "All checks passed!"
        else
            print_warning "All critical checks passed, but see warnings above"
        fi
        echo ""
        echo "Your Claude Meeting Memory setup is ready to use!"
        echo ""
        echo "Next steps:"
        echo "  1. Fill your profile: nano ~/.claude/memory/memoria_agente/perfil_usuario.md"
        echo "  2. Test the skills: /read-this, /pre-meeting, /remind-me"
        echo "  3. See documentation: cat ~/.claude/CLAUDE.md"
    else
        print_error "Some checks failed. See details above."
        echo ""
        echo "Common fixes:"
        echo "  - Missing Python packages: pip3 install google-auth google-api-client slack-sdk"
        echo "  - Missing credentials: Run setup.sh again"
        echo "  - File permissions: chmod 700 ~/.claude"
    fi

    echo ""
}

################################################################################
# Main
################################################################################

main() {
    clear

    cat << 'WELCOME'
╔══════════════════════════════════════════════════════════════╗
║     Claude Meeting Memory - Post-Setup Validation           ║
╚══════════════════════════════════════════════════════════════╝
WELCOME

    echo ""

    test_directory_structure
    test_template_files
    test_python_dependencies
    test_google_oauth
    test_slack_credentials
    test_skills_registration
    test_script_permissions
    test_file_permissions

    print_summary
}

main "$@"
