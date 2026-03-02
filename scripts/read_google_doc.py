#!/usr/bin/env python3
"""
Lê o conteúdo de um Google Doc e imprime em texto plano.

Uso:
  read_google_doc.py "https://docs.google.com/document/d/DOC_ID/edit"
  op run --env-file=meeting-prepper-secrets.env -- python3 read_google_doc.py "URL"

Requer variáveis de ambiente (via op run ou manualmente):
  GOOGLE_CAL_CLIENT_ID, GOOGLE_CAL_CLIENT_SECRET, GOOGLE_CAL_REFRESH_TOKEN

Nota: O refresh_token deve ter sido obtido com o scope documents.readonly.
      Se falhar com "insufficient permissions", reautorize a app no Google Cloud
      adicionando https://www.googleapis.com/auth/documents.readonly
"""
import os
import re
import ssl

if os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1":
    ssl._create_default_https_context = ssl._create_unverified_context


def get_env(name: str) -> str:
    val = os.environ.get(name)
    if not val:
        raise SystemExit(f"Error: {name} not set. Use: op run --env-file=meeting-prepper-secrets.env -- python3 read_google_doc.py URL")
    return val


def extract_document_id(url: str) -> str:
    """Extrai o document ID de um URL do Google Docs."""
    # https://docs.google.com/document/d/1abc123xyz/edit
    # https://docs.google.com/document/d/1abc123xyz/view
    m = re.search(r"/document/d/([a-zA-Z0-9_-]+)", url)
    if not m:
        raise SystemExit(f"URL inválido. Esperado: https://docs.google.com/document/d/DOC_ID/...")
    return m.group(1)


def extract_text_from_document(doc: dict) -> str:
    """Extrai texto do JSON retornado pela API do Google Docs."""
    content = doc.get("body", {}).get("content", [])
    parts = []

    def extract_from_element(el):
        if "paragraph" in el:
            for elem in el["paragraph"].get("elements", []):
                if "textRun" in elem:
                    parts.append(elem["textRun"].get("content", ""))
        elif "table" in el:
            for row in el["table"].get("tableRows", []):
                for cell in row.get("tableCells", []):
                    for c in cell.get("content", []):
                        if "paragraph" in c:
                            for elem in c["paragraph"].get("elements", []):
                                if "textRun" in elem:
                                    parts.append(elem["textRun"].get("content", ""))

    for el in content:
        extract_from_element(el)

    return "".join(parts)


def main():
    import sys
    if len(sys.argv) < 2:
        raise SystemExit("Uso: read_google_doc.py <URL_GOOGLE_DOC>")

    url = sys.argv[1].strip()
    doc_id = extract_document_id(url)

    client_id = get_env("GOOGLE_CAL_CLIENT_ID")
    client_secret = get_env("GOOGLE_CAL_CLIENT_SECRET")
    refresh_token = get_env("GOOGLE_CAL_REFRESH_TOKEN")

    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from google_auth_httplib2 import AuthorizedHttp
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    import httplib2

    def _refresh_creds(scopes: list):
        c = Credentials(
            token=None,
            refresh_token=refresh_token,
            token_uri="https://oauth2.googleapis.com/token",
            client_id=client_id,
            client_secret=client_secret,
            scopes=scopes,
        )
        if os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1":
            import requests
            import urllib3
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            session = requests.Session()
            session.verify = False
            c.refresh(Request(session=session))
        else:
            c.refresh(Request())
        return c

    def _build_service(creds, api: str, version: str):
        """Build API service, com SSL desativado em VPN corporativa."""
        if os.environ.get("GOOGLE_SKIP_SSL_VERIFY") == "1":
            http = httplib2.Http(disable_ssl_certificate_validation=True)
            http = AuthorizedHttp(creds, http=http)
            return build(api, version, http=http)
        return build(api, version, credentials=creds)

    def _handle_refresh_error(e):
        err = str(e).lower()
        if "invalid_scope" in err:
            raise SystemExit(
                "Erro: invalid_scope — o refresh_token não tem o scope necessário.\n\n"
                "O token em 1Password foi criado ANTES de adicionar o scope. Precisa de um NOVO token:\n\n"
                "1. No Google Cloud Console: APIs & Services > Library > ativar 'Google Docs API' e 'Drive API'\n"
                "2. OAuth consent screen > Scopes > adicionar 'documents.readonly' E 'drive.readonly'\n"
                "3. Executar: source ~/.claude/scripts/op.env && cd ~/.claude/scripts && op run --env-file=meeting-prepper-secrets.env -- python3 google_oauth_refresh_token.py\n"
                "4. Copiar o novo refresh_token para 1Password (iFood Google)\n\n"
                "Ver ~/.claude/scripts/README-google-docs.md"
            )
        if "invalid_grant" in err or "invalid_request" in err or "reauth" in err:
            raise SystemExit(
                "Erro: refresh_token inválido ou expirado. Execute google_oauth_refresh_token.py e atualize no 1Password."
            )
        raise

    title = "(sem título)"
    text = None

    # Tentar Docs API primeiro
    try:
        creds = _refresh_creds(["https://www.googleapis.com/auth/documents.readonly"])
        service = _build_service(creds, "docs", "v1")
        document = service.documents().get(documentId=doc_id).execute()
        title = document.get("title", "(sem título)")
        text = extract_text_from_document(document)
    except Exception as e:
        err = str(e).lower()
        if "invalid_scope" in err or "invalid_grant" in err:
            # Fallback: Drive API (scope drive.readonly pode já estar configurado)
            try:
                creds = _refresh_creds(["https://www.googleapis.com/auth/drive.readonly"])
                from googleapiclient.http import MediaIoBaseDownload
                import io
                drive_service = _build_service(creds, "drive", "v3")
                request = drive_service.files().export_media(fileId=doc_id, mimeType="text/plain")
                fh = io.BytesIO()
                downloader = MediaIoBaseDownload(fh, request)
                done = False
                while not done:
                    _, done = downloader.next_chunk()
                text = fh.getvalue().decode("utf-8", errors="replace")
                meta = drive_service.files().get(fileId=doc_id, fields="name").execute()
                title = meta.get("name", "(sem título)")
            except Exception as e2:
                _handle_refresh_error(e2)
        else:
            raise

    if text is None:
        raise SystemExit("Não foi possível obter o conteúdo do documento.")

    print(f"# {title}\n")
    print(text)


if __name__ == "__main__":
    main()
