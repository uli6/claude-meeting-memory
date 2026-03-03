---
name: read-this
description: "Reads documents/links and adds summary to memory. docs.google.com → RUN read_google_doc_wrapper.sh (Bash) — NEVER curl, Python inline or copy-paste without trying."
---

# Read This (Reading and Memory)

## ⚠️ GOOGLE DOCS — CRITICAL RULE

**Link docs.google.com → ONLY permitted action:** execute this exact command in the Bash tool:

```
~/.claude/scripts/read_google_doc_wrapper.sh "URL_PASTED_BY_USER"
```

**FORBIDDEN:** curl, Python inline, manual OAuth, "different approach", checking credentials, reading secrets, assuming it fails.
**FORBIDDEN:** Suggesting "copy and paste" without executing the wrapper first and receiving a real error.

**Example:** URL `https://docs.google.com/document/d/1IwRSIsIhtOEk93lPjzdGYF3So6kPylju4ZtPSgjlczc/edit` → command: `~/.claude/scripts/read_google_doc_wrapper.sh "https://docs.google.com/document/d/1IwRSIsIhtOEk93lPjzdGYF3So6kPylju4ZtPSgjlczc/edit"`

---

When the user says **"read this"**, **"read this document"**, **"read this link"** or similar — read the content, generate a summary, and **add to daily memory** for the knowledge base.

## Triggers

- "read this" (with file, document, or link attached/pasted)
- "read this document"
- "read this link"
- "read this" / "read that document" / "read that link"

## Flow

### 1. Identify the source

- **Local file**: path in system (e.g., `~/Downloads/doc.pdf`, `./report.md`)
- **Generic URL**: use `mcp_web_fetch` to get content
- **Google Docs** (`https://docs.google.com/document/...`): use the script `read_google_doc.py` with 1Password credentials

### 2. Get the content

| Type | Action |
|------|--------|
| File `.md`, `.txt`, etc. | Read with the `Read` tool |
| URL (except Google Docs) | Use `mcp_web_fetch` |
| Google Docs | **First action:** use **Bash** tool with: `~/.claude/scripts/read_google_doc_wrapper.sh "URL"` — never suggest copy-paste without executing first |

**Example for Google Docs:** If user pastes `https://docs.google.com/document/d/1IwRS.../edit`, the first action is `Bash(~/.claude/scripts/read_google_doc_wrapper.sh "https://docs.google.com/document/d/1IwRS.../edit")`.

**Important:** For links `https://docs.google.com/` (Docs, Sheets, etc.) — credentials are in 1Password under **iFood Google** (already configured in `meeting-prepper-secrets.env` with `op://OpenClaw/iFood Google/client_id`, etc.).

### 3. Generate summary

Create a concise summary (3–8 paragraphs) that captures:
- Title/main topic
- Key points and conclusions
- Information relevant for decisions or follow-up

### 4. Add to daily memory

- **Destination file:** `~/.claude/memory/memoria_agente/memory_YYYY-MM-DD.md.md`
- **Format** (append at end of file):

```markdown
---

## 📝 Summary: [Title or brief description]
**Source:** [path or URL] | **Date:** YYYY-MM-DD HH:MM

[Generated summary]
```

- If the day's file doesn't exist, create it in `memoria_agente/memory_YYYY-MM-DD.md.md`.

### 5. Confirm to user

Inform that the content was read and the summary was added to daily memory.

## Paths

| Resource | Path |
|----------|------|
| Google Docs Wrapper | `~/.claude/scripts/read_google_doc_wrapper.sh` |
| Daily memory | `~/.claude/memory/memoria_agente/memory_YYYY-MM-DD.md.md` |

## Notes

- The `meeting-prepper-secrets.env` already contains references to 1Password for **iFood Google** (client_id, client_secret, refresh_token). The same file is used for Meeting Prepper and for reading Google Docs.
- If the Google document requires additional permissions, the user may need to reauthorize the application in Google Cloud Console with the scope `https://www.googleapis.com/auth/documents.readonly`.
