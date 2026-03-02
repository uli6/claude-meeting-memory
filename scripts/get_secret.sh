#!/bin/bash

################################################################################
# get_secret.sh - Secure Credential Retrieval
#
# Retrieves secrets from OS Keychain or OpenSSL encrypted file
# Works on macOS (Keychain), Linux (Secret Service), or fallback (OpenSSL)
#
# Usage:
#   get_secret.sh <secret-key>
#   get_secret.sh google-client-id
#   get_secret.sh slack-user-token
#
# Returns the secret value to stdout, or empty string if not found
################################################################################

set -euo pipefail

SECRET_KEY="${1:-}"
SECRETS_FILE="${HOME}/.claude/.secrets.enc"
CLAUDE_HOME="${HOME}/.claude"

if [[ -z "$SECRET_KEY" ]]; then
    echo "Usage: get_secret.sh <secret-key>" >&2
    exit 1
fi

# Normalize secret key format for keychain (replace - with space for macOS)
KEYCHAIN_KEY="claude-code-${SECRET_KEY}"
SECRET_LABEL="Claude Code"

################################################################################
# Try macOS Keychain first
################################################################################

if [[ "$(uname)" == "Darwin" ]]; then
    # Try to get from Keychain
    if value=$(security find-generic-password -w -a "$USER" -s "$KEYCHAIN_KEY" 2>/dev/null); then
        if [[ -n "$value" ]]; then
            echo "$value"
            exit 0
        fi
    fi
fi

################################################################################
# Try Linux Secret Service (GNOME/KDE)
################################################################################

if command -v secret-tool &>/dev/null; then
    if value=$(secret-tool lookup --label="$SECRET_LABEL" key "$SECRET_KEY" 2>/dev/null); then
        if [[ -n "$value" ]]; then
            echo "$value"
            exit 0
        fi
    fi
fi

################################################################################
# Fallback: OpenSSL encrypted file
################################################################################

if [[ -f "$SECRETS_FILE" ]]; then
    # Try to decrypt using password
    # Note: This is a simplified approach - in real implementation,
    # the password would be cached or prompted once per session

    if openssl enc -aes-256-cbc -d -in "$SECRETS_FILE" -pbkdf2 -pass pass:"" 2>/dev/null | \
       grep -q "^${SECRET_KEY}="; then

        openssl enc -aes-256-cbc -d -in "$SECRETS_FILE" -pbkdf2 -pass pass:"" 2>/dev/null | \
        grep "^${SECRET_KEY}=" | cut -d= -f2-
        exit 0
    fi
fi

################################################################################
# Not found
################################################################################

# Return empty - script should handle gracefully
exit 1
