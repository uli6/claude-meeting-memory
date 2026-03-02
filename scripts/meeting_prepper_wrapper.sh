#!/bin/bash
# Meeting Prepper (modo automático)
# Executa a cada 10 min via cron. Consulta Google Calendar, gera briefing, envia Slack DM.
#
# Cron: */10 * * * * /Users/ulisses.oliveira/.claude/scripts/meeting_prepper_wrapper.sh >> /tmp/meeting_prepper.log 2>&1

set -e

# PATH para cron: op, python3, tompero (~/.local/bin)
export PATH="/Users/ulisses.oliveira/.local/bin:/opt/homebrew/bin:/usr/local/bin:/Library/Frameworks/Python.framework/Versions/3.11/bin:/usr/bin:/bin:$PATH"
export HOME="${HOME:-/Users/ulisses.oliveira}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$CLAUDE_DIR/memory"
export MEMORY_DIR

# 1Password service account (para op read)
[[ -f "$SCRIPT_DIR/op.env" ]] && source "$SCRIPT_DIR/op.env"

# Config
if [[ -f "$SCRIPT_DIR/meeting-prepper.conf" ]]; then
  source "$SCRIPT_DIR/meeting-prepper.conf"
fi
OP_SECRETS="${OP_SECRETS:-$SCRIPT_DIR/meeting-prepper-secrets.env}"

# Executar com secrets injetados pelo 1Password (se ficheiro existir)
if [[ -f "$OP_SECRETS" ]] && command -v op &>/dev/null; then
  exec op run --env-file="$OP_SECRETS" -- python3 "$SCRIPT_DIR/meeting_prepper.py"
else
  # Sem op run: variáveis já no ambiente
  exec python3 "$SCRIPT_DIR/meeting_prepper.py"
fi
