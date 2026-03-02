---
name: read-this
description: "Lê documentos/links e adiciona resumo à memória. docs.google.com → EXECUTAR read_google_doc_wrapper.sh (Bash) — NUNCA curl, Python inline ou copy-paste sem tentar."
---

# Read This (Leitura e Memória)

## ⚠️ GOOGLE DOCS — REGRA CRÍTICA

**Link docs.google.com → ÚNICA ação permitida:** executar este comando exato na ferramenta Bash:

```
~/.claude/scripts/read_google_doc_wrapper.sh "URL_COLADO_PELO_UTILIZADOR"
```

**PROIBIDO:** curl, Python inline, OAuth manual, "abordagem diferente", verificar credenciais, ler secrets, assumir que falha.
**PROIBIDO:** Sugerir "copie e cole" sem ter executado o wrapper e recebido erro real.

**Exemplo:** URL `https://docs.google.com/document/d/1IwRSIsIhtOEk93lPjzdGYF3So6kPylju4ZtPSgjlczc/edit` → comando: `~/.claude/scripts/read_google_doc_wrapper.sh "https://docs.google.com/document/d/1IwRSIsIhtOEk93lPjzdGYF3So6kPylju4ZtPSgjlczc/edit"`

---

Quando o utilizador disser **"leia isso"**, **"leia esse documento"**, **"leia esse link"** ou similar — ler o conteúdo, gerar um resumo e **adicionar à memória diária** para a base de conhecimento.

## Gatilhos

- "leia isso" (com ficheiro, documento ou link anexado/colado)
- "leia esse documento"
- "leia esse link"
- "read this" / "read this document" / "read this link"

## Fluxo

### 1. Identificar a fonte

- **Ficheiro local**: path no sistema (ex.: `~/Downloads/doc.pdf`, `./relatorio.md`)
- **URL genérica**: usar `mcp_web_fetch` para obter o conteúdo
- **Google Docs** (`https://docs.google.com/document/...`): usar o script `read_google_doc.py` com credenciais do 1Password

### 2. Obter o conteúdo

| Tipo | Ação |
|------|------|
| Ficheiro `.md`, `.txt`, etc. | Ler com a ferramenta `Read` |
| URL (exceto Google Docs) | Usar `mcp_web_fetch` |
| Google Docs | **Primeira ação:** usar a ferramenta **Bash** com: `~/.claude/scripts/read_google_doc_wrapper.sh "URL"` — nunca sugerir copy-paste sem executar primeiro |

**Exemplo para Google Docs:** Se o utilizador colar `https://docs.google.com/document/d/1IwRS.../edit`, a primeira ação é `Bash(~/.claude/scripts/read_google_doc_wrapper.sh "https://docs.google.com/document/d/1IwRS.../edit")`.

**Importante:** Para links `https://docs.google.com/` (Documentos, Sheets, etc.) — as credenciais estão no 1Password em **iFood Google** (já configurado em `meeting-prepper-secrets.env` com `op://OpenClaw/iFood Google/client_id`, etc.).

### 3. Gerar resumo

Criar um resumo conciso (3–8 parágrafos) que capture:
- Título/assunto principal
- Pontos-chave e conclusões
- Informação relevante para decisões ou follow-up

### 4. Adicionar à memória diária

- **Ficheiro de destino:** `~/.claude/memory/memoria_agente/memory_YYYY-MM-DD.md.md`
- **Formato** (append no final do ficheiro):

```markdown
---

## 📝 Resumo: [Título ou descrição breve]
**Fonte:** [path ou URL] | **Data:** YYYY-MM-DD HH:MM

[Resumo gerado]
```

- Se o ficheiro do dia não existir, criar em `memoria_agente/memory_YYYY-MM-DD.md.md`.

### 5. Confirmar ao utilizador

Informar que o conteúdo foi lido e o resumo foi adicionado à memória diária. Mencionar que pode sincronizar com o Notion com `~/.claude/scripts/sync-notion-memory.sh` se quiser.

## Paths

| Recurso | Path |
|---------|------|
| Wrapper Google Docs | `~/.claude/scripts/read_google_doc_wrapper.sh` |
| Secrets (1Password) | `~/.claude/scripts/meeting-prepper-secrets.env` |
| Memória diária | `~/.claude/memory/memoria_agente/memory_YYYY-MM-DD.md.md` |
| Sync Notion | `~/.claude/scripts/sync-notion-memory.sh` |

## Notas

- O `meeting-prepper-secrets.env` já contém as referências ao 1Password para **iFood Google** (client_id, client_secret, refresh_token). O mesmo ficheiro serve para o Meeting Prepper e para ler Google Docs.
- Se o documento Google exigir permissões adicionais, o utilizador pode precisar de reautorizar a aplicação no Google Cloud Console com o scope `https://www.googleapis.com/auth/documents.readonly`.
