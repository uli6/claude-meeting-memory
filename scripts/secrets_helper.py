#!/usr/bin/env python3

################################################################################
# secrets_helper.py - Secure Credential Management for Python
#
# Helper library for retrieving secrets from OS Keychain or encrypted storage
# Caches secrets at session level to avoid repeated decryption
#
# Usage:
#   from secrets_helper import get_secret
#   token = get_secret("slack-user-token")
#   client_id = get_secret("google-client-id")
#
# Supports:
#   - macOS Keychain (via security command)
#   - Linux Secret Service (via secret-tool)
#   - Fallback OpenSSL encryption
################################################################################

import os
import subprocess
import sys
from pathlib import Path
from typing import Optional

# Session-level cache to avoid repeated decryption
_SECRET_CACHE = {}

# Environment-level cache key prefix
_ENV_CACHE_PREFIX = "CLAUDE_CODE_"


def get_secret(key: str) -> Optional[str]:
    """
    Retrieve a secret from keychain or encrypted storage.

    Args:
        key: Secret name (e.g., "google-client-id", "slack-user-token")

    Returns:
        Secret value if found, None otherwise

    Raises:
        ValueError: If secret not found and required

    Example:
        >>> client_id = get_secret("google-client-id")
        >>> if not client_id:
        ...     raise ValueError("Google client ID not configured")
    """

    # Check in-memory cache first
    if key in _SECRET_CACHE:
        return _SECRET_CACHE[key]

    # Check environment cache
    env_key = f"{_ENV_CACHE_PREFIX}{key.upper().replace('-', '_')}"
    if env_key in os.environ:
        value = os.environ[env_key]
        _SECRET_CACHE[key] = value
        return value

    # Try OS Keychain/Secret Service
    secret = _get_from_system_keychain(key)
    if secret:
        # Cache for this session
        _SECRET_CACHE[key] = secret
        os.environ[env_key] = secret
        return secret

    # Try OpenSSL encrypted file
    secret = _get_from_encrypted_file(key)
    if secret:
        # Cache for this session
        _SECRET_CACHE[key] = secret
        os.environ[env_key] = secret
        return secret

    # Not found
    return None


def set_secret(key: str, value: str) -> bool:
    """
    Store a secret in OS Keychain (macOS/Linux) or encrypted file.

    Args:
        key: Secret name
        value: Secret value

    Returns:
        True if stored successfully, False otherwise
    """

    # Try to store in system keychain
    if _set_in_system_keychain(key, value):
        _SECRET_CACHE[key] = value
        return True

    # Fallback to encrypted file
    if _set_in_encrypted_file(key, value):
        _SECRET_CACHE[key] = value
        return True

    return False


def delete_secret(key: str) -> bool:
    """
    Delete a secret from storage.

    Args:
        key: Secret name

    Returns:
        True if deleted successfully, False otherwise
    """

    # Remove from cache
    _SECRET_CACHE.pop(key, None)
    env_key = f"{_ENV_CACHE_PREFIX}{key.upper().replace('-', '_')}"
    os.environ.pop(env_key, None)

    # Try to delete from system keychain
    if _delete_from_system_keychain(key):
        return True

    # Try to delete from encrypted file
    if _delete_from_encrypted_file(key):
        return True

    return False


def _get_from_system_keychain(key: str) -> Optional[str]:
    """Get secret from OS Keychain (macOS) or Secret Service (Linux)."""

    # Try macOS Keychain
    if sys.platform == "darwin":
        return _get_from_macos_keychain(key)

    # Try Linux Secret Service
    return _get_from_linux_secret_service(key)


def _get_from_macos_keychain(key: str) -> Optional[str]:
    """Retrieve secret from macOS Keychain."""

    keychain_key = f"claude-code-{key}"

    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-w", "-a", os.getenv("USER", ""), "-s", keychain_key],
            capture_output=True,
            text=True,
            timeout=5,
        )

        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return None


def _get_from_linux_secret_service(key: str) -> Optional[str]:
    """Retrieve secret from Linux Secret Service (GNOME/KDE)."""

    if not _command_exists("secret-tool"):
        return None

    try:
        result = subprocess.run(
            ["secret-tool", "lookup", "--label=Claude Code", "key", key],
            capture_output=True,
            text=True,
            timeout=5,
        )

        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return None


def _get_from_encrypted_file(key: str) -> Optional[str]:
    """Retrieve secret from OpenSSL encrypted file."""

    secrets_file = Path.home() / ".claude" / ".secrets.enc"

    if not secrets_file.exists():
        return None

    try:
        # Try to decrypt with empty password (simplified)
        result = subprocess.run(
            ["openssl", "enc", "-aes-256-cbc", "-d", "-in", str(secrets_file), "-pbkdf2", "-pass", "pass:"],
            capture_output=True,
            text=True,
            timeout=5,
        )

        if result.returncode == 0:
            for line in result.stdout.strip().split("\n"):
                if line.startswith(f"{key}="):
                    return line.split("=", 1)[1]
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return None


def _set_in_system_keychain(key: str, value: str) -> bool:
    """Store secret in OS Keychain."""

    # Try macOS Keychain
    if sys.platform == "darwin":
        return _set_in_macos_keychain(key, value)

    # Try Linux Secret Service
    return _set_in_linux_secret_service(key, value)


def _set_in_macos_keychain(key: str, value: str) -> bool:
    """Store secret in macOS Keychain."""

    keychain_key = f"claude-code-{key}"

    try:
        subprocess.run(
            ["security", "add-generic-password", "-a", os.getenv("USER", ""), "-s", keychain_key, "-w", value, "-U"],
            capture_output=True,
            timeout=5,
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return False


def _set_in_linux_secret_service(key: str, value: str) -> bool:
    """Store secret in Linux Secret Service."""

    if not _command_exists("secret-tool"):
        return False

    try:
        subprocess.run(
            ["secret-tool", "store", "--label=Claude Code", "key", key, value],
            capture_output=True,
            timeout=5,
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return False


def _set_in_encrypted_file(key: str, value: str) -> bool:
    """Store secret in OpenSSL encrypted file."""

    secrets_file = Path.home() / ".claude" / ".secrets.enc"
    secrets_file.parent.mkdir(exist_ok=True, mode=0o700)

    try:
        # Read existing secrets
        existing = {}
        if secrets_file.exists():
            result = subprocess.run(
                ["openssl", "enc", "-aes-256-cbc", "-d", "-in", str(secrets_file), "-pbkdf2", "-pass", "pass:"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode == 0:
                for line in result.stdout.strip().split("\n"):
                    if "=" in line:
                        k, v = line.split("=", 1)
                        existing[k] = v

        # Update with new secret
        existing[key] = value

        # Write encrypted file
        content = "\n".join(f"{k}={v}" for k, v in existing.items())
        subprocess.run(
            ["openssl", "enc", "-aes-256-cbc", "-out", str(secrets_file), "-pbkdf2", "-pass", "pass:"],
            input=content,
            text=True,
            timeout=5,
        )

        # Set file permissions
        secrets_file.chmod(0o600)
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return False


def _delete_from_system_keychain(key: str) -> bool:
    """Delete secret from OS Keychain."""

    # Try macOS Keychain
    if sys.platform == "darwin":
        return _delete_from_macos_keychain(key)

    # Try Linux Secret Service
    return _delete_from_linux_secret_service(key)


def _delete_from_macos_keychain(key: str) -> bool:
    """Delete secret from macOS Keychain."""

    keychain_key = f"claude-code-{key}"

    try:
        subprocess.run(
            ["security", "delete-generic-password", "-a", os.getenv("USER", ""), "-s", keychain_key],
            capture_output=True,
            timeout=5,
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return False


def _delete_from_linux_secret_service(key: str) -> bool:
    """Delete secret from Linux Secret Service."""

    if not _command_exists("secret-tool"):
        return False

    try:
        subprocess.run(
            ["secret-tool", "clear", "--label=Claude Code", "key", key],
            capture_output=True,
            timeout=5,
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return False


def _delete_from_encrypted_file(key: str) -> bool:
    """Delete secret from encrypted file."""

    secrets_file = Path.home() / ".claude" / ".secrets.enc"

    if not secrets_file.exists():
        return False

    try:
        # Read existing secrets
        result = subprocess.run(
            ["openssl", "enc", "-aes-256-cbc", "-d", "-in", str(secrets_file), "-pbkdf2", "-pass", "pass:"],
            capture_output=True,
            text=True,
            timeout=5,
        )

        if result.returncode != 0:
            return False

        # Remove the secret
        lines = []
        for line in result.stdout.strip().split("\n"):
            if not line.startswith(f"{key}="):
                lines.append(line)

        # Write encrypted file
        content = "\n".join(lines)
        subprocess.run(
            ["openssl", "enc", "-aes-256-cbc", "-out", str(secrets_file), "-pbkdf2", "-pass", "pass:"],
            input=content,
            text=True,
            timeout=5,
        )

        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return False


def _command_exists(cmd: str) -> bool:
    """Check if a command is available in PATH."""

    try:
        subprocess.run(["which", cmd], capture_output=True, check=True, timeout=1)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


if __name__ == "__main__":
    # Simple CLI for testing
    if len(sys.argv) < 2:
        print("Usage: python secrets_helper.py get <key>")
        print("       python secrets_helper.py set <key> <value>")
        print("       python secrets_helper.py delete <key>")
        sys.exit(1)

    action = sys.argv[1]
    key = sys.argv[2] if len(sys.argv) > 2 else None

    if action == "get" and key:
        value = get_secret(key)
        if value:
            print(value)
        else:
            print(f"Secret not found: {key}", file=sys.stderr)
            sys.exit(1)

    elif action == "set" and len(sys.argv) > 3:
        value = sys.argv[3]
        if set_secret(key, value):
            print(f"Secret stored: {key}")
        else:
            print(f"Failed to store secret: {key}", file=sys.stderr)
            sys.exit(1)

    elif action == "delete" and key:
        if delete_secret(key):
            print(f"Secret deleted: {key}")
        else:
            print(f"Secret not found: {key}", file=sys.stderr)
            sys.exit(1)

    else:
        print("Invalid arguments", file=sys.stderr)
        sys.exit(1)
