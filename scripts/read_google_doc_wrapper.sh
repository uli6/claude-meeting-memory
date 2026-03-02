#!/bin/bash
# Wrapper para read_google_doc.py — carrega op.env e injeta credenciais via 1Password.
# Uso: ~/.claude/scripts/read_google_doc_wrapper.sh "https://docs.google.com/document/d/ID/edit"
#
# O Claude Code deve executar ESTE script (não o python diretamente) para que o 1Password funcione.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1Password Service Account — obrigatório para op run funcionar sem login interativo
[[ -f "$SCRIPT_DIR/op.env" ]] && source "$SCRIPT_DIR/op.env"

if [[ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]]; then
  echo "Error: OP_SERVICE_ACCOUNT_TOKEN não definido."
  echo "  Configure em ~/.claude/scripts/op.env (ver README-1password.md)"
  exit 1
fi

OP_SECRETS="${SCRIPT_DIR}/meeting-prepper-secrets.env"
if [[ ! -f "$OP_SECRETS" ]]; then
  echo "Error: $OP_SECRETS não encontrado."
  exit 1
fi

# VPN corporativa (iFood): certificados auto-assinados
export GOOGLE_SKIP_SSL_VERIFY=1

if [[ -z "$1" ]]; then
  echo "Uso: read_google_doc_wrapper.sh \"URL_DO_GOOGLE_DOC\""
  exit 1
fi

exec op run --env-file="$OP_SECRETS" -- python3 "$SCRIPT_DIR/read_google_doc.py" "$1"
