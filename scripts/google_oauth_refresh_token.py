#!/usr/bin/env python3
"""
Gera um novo refresh_token do Google com os scopes necessários para:
- Meeting Prepper (Calendar)
- read_google_doc (Docs)

Uso (com 1Password):
  source ~/.claude/scripts/op.env
  ~/.claude/scripts/read_google_doc_wrapper.sh  # só para verificar que op funciona
  cd ~/.claude/scripts && op run --env-file=meeting-prepper-secrets.env -- python3 google_oauth_refresh_token.py

Ou manualmente: export GOOGLE_CAL_CLIENT_ID, GOOGLE_CAL_CLIENT_SECRET e executar.

Depois: copiar o refresh_token para 1Password (iFood Google > refresh_token).
"""
import json
import os
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
TOKEN_FILE = SCRIPT_DIR / "google_oauth_token.json"

SCOPES = [
    "https://www.googleapis.com/auth/calendar.events.readonly",
    "https://www.googleapis.com/auth/documents.readonly",
    "https://www.googleapis.com/auth/drive.readonly",  # fallback para export via Drive API
]

if os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1":
    import ssl
    ssl._create_default_https_context = ssl._create_unverified_context


def main():
    from google_auth_oauthlib.flow import InstalledAppFlow

    client_id = os.environ.get("GOOGLE_CAL_CLIENT_ID")
    client_secret = os.environ.get("GOOGLE_CAL_CLIENT_SECRET")

    if not client_id or not client_secret:
        print("Erro: GOOGLE_CAL_CLIENT_ID e GOOGLE_CAL_CLIENT_SECRET necessários.")
        print("Execute com: op run --env-file=meeting-prepper-secrets.env -- python3 google_oauth_refresh_token.py")
        return 1

    config = {
        "installed": {
            "client_id": client_id,
            "client_secret": client_secret,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob", "http://localhost"]
        }
    }
    flow = InstalledAppFlow.from_client_config(config, SCOPES)
    creds = flow.run_local_server(port=0)

    # Guardar token (opcional, para debug)
    with open(TOKEN_FILE, "w") as f:
        f.write(creds.to_json())

    refresh_token = creds.refresh_token
    if not refresh_token:
        print("Erro: Não foi obtido refresh_token. Tente revogar acesso em myaccount.google.com e executar de novo.")
        return 1

    print("\n" + "=" * 60)
    print("NOVO REFRESH TOKEN (copie para 1Password > iFood Google > refresh_token):")
    print("=" * 60)
    print(refresh_token)
    print("=" * 60)
    print("\nDepois de atualizar no 1Password, apague google_oauth_token.json por segurança.")
    return 0


if __name__ == "__main__":
    exit(main())
