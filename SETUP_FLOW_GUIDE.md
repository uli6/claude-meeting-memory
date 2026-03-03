# Setup Flow Guide - Claude Meeting Memory

**Guia completo do que os usuários vão experimentar ao rodar o setup.sh**

---

## Visão Geral do Setup

Quando o usuário executa:
```bash
curl -fsSL https://raw.githubusercontent.com/uli6/claude-meeting-memory/main/setup.sh | bash
```

O script irá guiar através de **9 fases** interativas, resultando em um sistema completo e funcional.

### ⚠️ Importante: Como Claude Code é Usado

Este sistema usa **Claude Code's built-in authentication** - NÃO requer uma API key separada da Anthropic:

- ✅ Scripts Python importam a biblioteca `anthropic`
- ✅ Scripts usam `apiKeyHelper` (configurado em `~/.claude/settings.json`)
- ✅ `apiKeyHelper` chama `~/.claude/ifood_auth.sh` para obter autenticação
- ✅ Autenticação é gerenciada por Claude Code
- ❌ Nenhuma API key separada necessária
- ❌ Nenhuma configuração adicional de Anthropic

**Resultado:** Usuários não precisam gerenciar API keys. O sistema funciona com a instalação existente do Claude Code.

---

## Fase 1: Verificação Inicial (30 segundos)

### O que acontece:
- Script verifica dependências: curl, python3, openssl, jq
- Valida sistema operacional (macOS, Linux)
- Mostra welcome banner com checklist

### Output:
```
════════════════════════════════════════════════════════════
  Phase 1: Initial Checks & Welcome
════════════════════════════════════════════════════════════

✓ System requirements validated
✓ bash version 4+ detected
✓ Required tools found
```

---

## Fase 1.5: Instalação de Dependências Python (1-2 minutos)

### O que acontece:
- Verifica se Python 3.8+ está instalado
- Instala pacotes Python necessários automaticamente:
  - anthropic (Para scripts Python que usam Claude via Claude Code)
  - google-auth, google-api-client (Para autenticação Google OAuth)
  - slack-sdk (Para integração Slack)

### Nota Importante:
Os scripts Python (`add_action_point.py`, `email_memory_processor.py`, etc.) importam a biblioteca `anthropic`, mas não usam API keys separadas. Em vez disso, eles chamam o `apiKeyHelper` (configurado em `~/.claude/settings.json`) que usa a autenticação integrada do Claude Code via `~/.claude/ifood_auth.sh`.

**Resumo:**
- Scripts importam `anthropic` ✓
- Scripts NOT fazem requisições diretas à API Anthropic ✓
- Scripts usam autenticação do Claude Code ✓
- Nenhuma API key separada necessária ✓

### Output:
```
✓ Python 3.x installed
✓ Installing Python dependencies...
  Installing anthropic...
  Installing google-auth...
  Installing google-api-client...
  Installing slack-sdk...
✓ All dependencies installed
```

---

## Fase 2: Estrutura de Pastas (30 segundos)

### O que acontece:
- Cria diretórios necessários
- Copia scripts Python
- Copia skills do GitHub
- Copia templates

### Diretórios criados:
```
~/.claude/
├── memory/
│   ├── action_points.md (criado em branco)
│   ├── MEMORY.md
│   └── memoria_agente/
│       ├── memory_YYYY-MM-DD.md
│       └── perfil_usuario.md
├── scripts/ (copiados do GitHub)
├── skills/ (copiados do GitHub)
│   ├── read-this/
│   ├── pre-meeting/
│   └── remind-me/
└── CLAUDE.md (instruções)
```

### Output:
```
✓ Directory structure created
✓ Scripts copied from repository
✓ Skills installed
✓ Memory system initialized
```

---

## Fase 3: Configuração Google OAuth (3-5 minutos)

### O que o usuário vê:

**PASSO 1: Criar projeto Google Cloud**

```
📋 STEP 1: Create a Google Cloud Project
  1. Go to: https://console.cloud.google.com/
  2. Create a new project (name: 'Claude Meeting Memory')
  3. Enable APIs:
     - Google Drive API
     - Google Calendar API
     - Google Docs API
```

O script fornece links diretos que o usuário pode clicar.

**PASSO 2: Criar credenciais OAuth 2.0**

```
📋 STEP 2: Create OAuth 2.0 Credentials
  1. Go to: APIs & Services > Credentials
  2. Create Credentials > OAuth client ID
  3. Choose: Desktop application
  4. Download JSON file

📋 STEP 3: Configure OAuth
  Open the downloaded JSON file and provide:
```

**PASSO 3: Copiar credenciais**

O script solicita:
```
Google Client ID (copy from JSON: client_id): [USER PASTES]
Google Client Secret (copy from JSON: client_secret): [MASKED INPUT]
```

**PASSO 4: Autorização automática no navegador**

```
Starting browser for authorization...

[Navegador abre automaticamente]
[Usuário clica "Allow"]
[Token obtido automaticamente]
```

### O que acontece nos bastidores:
1. Script executa Python para abrir fluxo OAuth
2. Browser abre com página de autorização do Google
3. Usuário clica "Allow"
4. Token de refresh é obtido automaticamente
5. Credenciais são armazenadas de forma segura

### Output:
```
Starting browser for authorization...
✓ Google authorization successful!
✓ Google credentials saved to Keychain (ou Secret Service ou environment)
```

---

## Fase 4: Configuração Slack (3-5 minutos)

### O que o usuário vê:

**Confirmação inicial:**
```
ℹ This will authorize Claude Code to use Slack:
  • Read messages from channels you have access to
  • Send direct messages to you

Do you want to configure Slack integration? (Y/n):
```

**Se usuário disser NÃO**: Pula para Fase 5

**Se usuário disser SIM:**

**PASSO 1: Workspace do Slack**

```
📋 STEP 1: Create or Use Existing Slack Workspace
  You need a Slack workspace where you can create apps.

  Option A - Use your company workspace:
    1. Open: https://app.slack.com/apps
    2. You're already in your workspace

  Option B - Create personal workspace:
    1. Go to: https://slack.com/create
    2. Follow the setup steps

  Make sure you have ADMIN access to create apps.
```

**PASSO 2: Obter User Token**

```
📋 STEP 2: Get Your User Token (xoxp-...)
  Method A - Using Legacy Token (Simplest):
    1. Go to: https://api.slack.com/custom-integrations/legacy-tokens
    2. Click 'Create New Token' for your workspace
    3. Copy the token (starts with xoxp-)

  Method B - Create a Personal App (Recommended):
    1. Go to: https://api.slack.com/apps
    2. Click 'Create New App' → 'From scratch'
    3. Name: 'Claude Meeting Memory' | Workspace: (your workspace)
    4. Go to 'OAuth & Permissions' on the left
    5. Under 'User Token Scopes', add these scopes:
       • chat:write
       • channels:read
       • groups:read
       • im:read
       • users:read
    6. Click 'Install to Workspace' at the top
    7. Copy your 'User OAuth Token' (starts with xoxp-)

⚠️  IMPORTANT: Use 'User Token' (xoxp-), NOT 'Bot Token' (xoxb-)
```

O script solicita:
```
Slack User Token (copy the xoxp-... token): [MASKED INPUT]
```

**PASSO 3: Validar token**

```
Validating Slack token...
✓ Slack token is valid
```

**PASSO 4: Obter Member ID**

```
📋 STEP 3: Get Your Slack Member ID (U...)
  1. Open Slack in your browser or app
  2. Click your profile picture (usually bottom-left)
  3. Look for 'Member ID' or click 'Copy user ID'
  4. It starts with 'U' (example: U01DHE5U6MA)

  If you don't see it:
    • Right-click your name in any channel
    • Select 'View profile'
    • Look for the ID starting with 'U'
```

O script solicita:
```
Slack Member ID (copy the U... ID): [USER PASTES]
```

### Output:
```
✓ Slack credentials saved to Keychain (ou Secret Service ou environment)
✓ Slack configuration complete!
```

---

## Fase 5: Revisão de Segurança (1 minuto)

### O que acontece:
- Script mostra onde as credenciais foram armazenadas
- Explica como revogar acesso
- Confirma que nenhum segredo foi enviado para a cloud

### Output:
```
═══════════════════════════════════════════════════════════
  Phase 5: Security Review
═══════════════════════════════════════════════════════════

✓ Credential Storage Method:
  macOS:   Apple Keychain (secure, OS-protected)
  Linux:   Secret Service (secure, OS-protected)
  Fallback: Environment variables

✓ What was stored:
  • Google Client ID & Secret
  • Google Refresh Token
  • Slack User Token
  • Slack Member ID

✓ Security Notes:
  • No secrets sent to cloud
  • No passwords stored
  • Credentials protected by OS security
  • You can revoke anytime at:
    - Google: https://myaccount.google.com/permissions
    - Slack: https://api.slack.com/apps
```

---

## Fase 6: Registar Skills (30 segundos)

### O que acontece:
- Atualiza `~/.claude/claude.json` com as 3 skills
- Skills são registradas em Claude Code

### Output:
```
═══════════════════════════════════════════════════════════
  Phase 6: Skill Registration
═══════════════════════════════════════════════════════════

✓ Skills registered in Claude Code:
  • /read-this
  • /pre-meeting
  • /remind-me
```

---

## Fase 7: Criar Templates (30 segundos)

### O que acontece:
- Cria arquivos iniciais de memória
- Instrui usuário a preencher perfil

### Arquivos criados:
```
~/.claude/memory/action_points.md
~/.claude/memory/MEMORY.md
~/.claude/memory/memoria_agente/perfil_usuario.md
~/.claude/CLAUDE.md (instruções locais)
```

### Output:
```
═══════════════════════════════════════════════════════════
  Phase 7: Create Template Files
═══════════════════════════════════════════════════════════

✓ Memory system initialized
✓ Templates created
```

---

## Fase 7.5: User Profile Setup (2-3 minutos - Opcional)

### O que acontece:
- Script pergunta se usuário quer preencher o perfil agora
- Se SIM: coleta informações básicas (nome, cargo, time, email, Slack)
- Pre-preenche `perfil_usuario.md` com dados fornecidos
- Se NÃO: usuário pode preencher manualmente depois com nano

### Por que é importante:
- O perfil melhora os contextos das reuniões
- `/pre-meeting` usa estas informações
- Melhor experiência desde o primeiro dia

### O que o usuário vê:

```
════════════════════════════════════════════════════════════
  Phase 7.5: User Profile Setup
════════════════════════════════════════════════════════════

ℹ Your profile helps generate better meeting briefings.
You can:
  • Fill it now (2-3 minutes)
  • Skip and fill it later with: nano ~/.claude/memory/memoria_agente/perfil_usuario.md

Do you want to fill your profile now? (Y/n): y

ℹ Let's gather some basic information about you.

👤 Full name (or nickname): João Silva
💼 Your job title/role: Software Engineer
👥 Your team/department: Platform Team
📧 Your email (optional): joao.silva@company.com
💬 Slack handle (e.g., @seu.username) (optional): @joao.silva

ℹ Saving your profile...
✓ Profile saved!

ℹ Your profile has been created with the information you provided.
You can edit it anytime with:
  nano ~/.claude/memory/memoria_agente/perfil_usuario.md
```

### Cenário alternativo (usuário pula):

```
Do you want to fill your profile now? (Y/n): n

⚠ Skipping profile setup
You can fill it later with:
  nano ~/.claude/memory/memoria_agente/perfil_usuario.md
```

### Resultado:

**Arquivo criado:** `~/.claude/memory/memoria_agente/perfil_usuario.md`

Com conteúdo pre-preenchido:
```markdown
# Seu Perfil - Memória do Agente

## 👤 Informações Pessoais
**Nome Completo:** João Silva
**Cargo/Título:** Software Engineer
**Time/Departamento:** Platform Team
**Email:** joao.silva@company.com
**Slack Handle:** @joao.silva

## 🏢 Organização
[Resto do template para completar manualmente]
```

---

## Fase 8: Validação (1 minuto)

### O que acontece:
- Testa se Google credentials funcionam
- Testa se Slack token é válido
- Verifica se skills estão registradas
- Confirma que Python dependencies estão OK

### Output:
```
═══════════════════════════════════════════════════════════
  Phase 8: Validation
═══════════════════════════════════════════════════════════

Testing setup...
✓ Google credentials working
✓ Slack token validated
✓ Skills registered in Claude Code
✓ Python dependencies installed
✓ Memory system ready

All systems operational!
```

---

## Fase 9: Resumo & Próximos Passos (1 minuto)

### O que acontece:
- Mostra resumo do que foi configurado
- Fornece próximos passos
- Links para documentação

### Output:
```
═══════════════════════════════════════════════════════════
  SETUP COMPLETE! ✓
═══════════════════════════════════════════════════════════

YOUR THREE SKILLS ARE READY NOW:

  /read-this       - Read Google Docs and save to memory
  /pre-meeting     - Generate meeting briefings
  /remind-me       - Create action points from text/Slack

IMMEDIATE NEXT STEPS:

  1. Test the skills:
     /read-this https://docs.google.com/document/d/YOUR_DOC/edit
     /pre-meeting
     /remind-me Check the deadline

  2. Update your profile (if needed):
     nano ~/.claude/memory/memoria_agente/perfil_usuario.md

  3. Verify everything works:
     bash ~/.claude/scripts/validate.sh

OPTIONAL - Email Automation (15 minutes):
  Follow: https://github.com/uli6/claude-meeting-memory/docs/GETTING_STARTED_EMAIL.md

═══════════════════════════════════════════════════════════

Setup time: ~10 minutes
Documentation: https://github.com/uli6/claude-meeting-memory
Issues: https://github.com/uli6/claude-meeting-memory/issues
```

---

## Timeline Total

| Fase | Tempo | Ação |
|------|-------|------|
| 1 | 30s | Verificação inicial |
| 1.5 | 1-2m | Instalar dependências Python |
| 2 | 30s | Criar estrutura de pastas |
| 3 | 3-5m | **Google OAuth (interativo)** |
| 4 | 3-5m | **Slack Token (interativo)** |
| 5 | 1m | Revisão de segurança |
| 6 | 30s | Registar skills |
| 7 | 30s | Criar templates |
| 7.5 | 2-3m | **Preencher Perfil (opcional)** |
| 8 | 1m | Validação |
| 9 | 1m | Resumo |
| **TOTAL** | **~12-18m** | **Setup Completo** |

---

## O Que Cada Fase Requer do Usuário

### Fase 3 (Google OAuth) - Requer:
- ✓ Clique em link (Google Cloud Console)
- ✓ Criar projeto (3 cliques)
- ✓ Copiar 2 valores (Client ID, Client Secret)
- ✓ Autorizar no navegador (1 clique)

### Fase 4 (Slack) - Requer:
- ✓ Clique sim/não (quer configurar Slack?)
- ✓ Clique em link (Slack API)
- ✓ Criar token (Legacy ou Personal App)
- ✓ Copiar token (xoxp-...)
- ✓ Obter Member ID (copiar de profile)

### Fase 7.5 (Perfil) - Requer:
- ✓ Clique sim/não (quer preencher perfil agora?)
- ✓ Se SIM: Preencher nome + cargo + time + email + Slack handle
- ✓ Se NÃO: Pode preencher depois com nano

### Outras Fases:
- Automáticas (sem input do usuário necessário)

---

## Cenários Especiais

### Cenário 1: Usuário pula Google OAuth
```
Configure Google OAuth? (Y/n): n

⚠ Skipping Google OAuth setup
ℹ You can configure it later by running: setup.sh

→ Continua para Slack
```

### Cenário 2: Google token é inválido
```
⚠ Client Secret cannot be empty
→ Script pede novamente
```

### Cenário 3: Slack token inválido
```
✗ Token must start with 'xoxp-' (this is a User Token, not a Bot Token)
ℹ Make sure you copied the correct token from:
  • Legacy Tokens: https://api.slack.com/custom-integrations/legacy-tokens
  • OAuth & Permissions: https://api.slack.com/apps → Your App → OAuth & Permissions

→ Script retorna 1 (falha)
```

### Cenário 4: Keychain não disponível
```
⚠ Keychain/Secret Service not available
ℹ Google credentials stored in environment
→ Credenciais armazenadas em variáveis de ambiente (menos seguro, mas funciona)
```

---

## Depois do Setup

### Usuário tem:
✅ 3 skills funcionais
✅ Memory system inicializado
✅ Credenciais armazenadas de forma segura
✅ Google OAuth configurado
✅ Slack configurado
✅ Documentação completa

### Próximos passos do usuário:
1. Preencher perfil em `~/.claude/memory/memoria_agente/perfil_usuario.md`
2. Testar skills manualmente
3. (Opcional) Configurar email automation

---

## Documentação Relevante

- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Guia completo com screenshots
- [GOOGLE_OAUTH_SETUP.md](./docs/GOOGLE_OAUTH_SETUP.md) - Detalhes Google
- [SLACK_SETUP.md](./docs/SLACK_SETUP.md) - Detalhes Slack
- [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) - Problemas comuns
- [HOW_TO_USE.md](./docs/HOW_TO_USE.md) - Como usar as skills

---

**Status:** ✅ Setup Flow Completo e Documentado
**Última Atualização:** March 3, 2026
