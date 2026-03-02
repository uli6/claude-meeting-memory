---
name: meeting-prepper
description: Prepara briefings executivos antes de reuniões. Lê pendências (action_points), memória diária, memoria_agente e MEMORY.md; gera briefing estruturado (Pendências Ativas + Contexto Histórico). Use quando o utilizador pedir briefing de reunião, meeting prepper, ou preparação para reunião.
---

# Meeting Prepper (Skill para Claude Code)

Gera briefing executivo antes de reuniões usando pendências e memória em `~/.claude/memory/`. Os dados são sincronizados do Notion via script; a skill apenas lê os ficheiros locais.

**Fonte:** [Clawdia Memory](https://www.notion.so/Clawdia-Memory-312d9a25aaca80689a81cbe3376ab260) no Notion. Sincronizar com `~/.claude/scripts/sync-notion-memory.sh` antes de gerar briefings.

**Fluxo de negócio:** Ver [FLUXO_NEGOCIO.md](FLUXO_NEGOCIO.md) para o fluxo completo (automático + sob pedido).

## Como executar (Claude Code)

Escreve no chat uma destas frases:

- **"Briefing da reunião"** ou **"Meeting prepper"**
- **"Prepara-me para a reunião"**
- **"O que tenho de saber para a reunião [título]?"**

Se não indicares título/participantes, o Claude pede. Podes colar dados do calendário ou convite.

---

## Quando usar

- Utilizador pede "briefing da reunião", "meeting prepper", "prepara-me para a reunião" ou "o que tenho de saber para a reunião X".
- Utilizador partilha título/participantes/descrição de uma reunião e quer um resumo com pendências e contexto.

## Fluxo (o que fazer)

### 1. Obter dados da reunião

- Se o utilizador já indicou **título**, **participantes** e (opcional) **descrição**, usar esses dados.
- Se não: pedir ao utilizador que indique a reunião (título e, se possível, participantes e descrição) ou que cole os dados do calendário / convite.

### 2. Ler os ficheiros em ~/.claude/memory/

Todos os paths são em `~/.claude/memory/` (ou `$HOME/.claude/memory/`).

| Ficheiro | Propósito |
|----------|-----------|
| `~/.claude/memory/action_points.md` | Pendências ativas (itens não marcados com `[x]`) — **fonte para "Pendências Ativas"** |
| `~/.claude/memory/memory/YYYY-MM-DD.md` | Memória diária do dia (substituir YYYY-MM-DD pela data de hoje) |
| `~/.claude/memory/memoria_agente/*.md` | Perfil, pessoas, projetos, pendencias, etc. |
| `~/.claude/memory/MEMORY.md` | Memória executiva geral — contexto estratégico e próximos passos |

- Ler todos os `.md` em `~/.claude/memory/memoria_agente/` que existam.
- Se algum ficheiro não existir, prosseguir com os que existirem e indicar brevemente o que faltou.
- Se a pasta `~/.claude/memory/memory/` estiver vazia ou não existir, sugerir ao utilizador executar o sync: `~/.claude/scripts/sync-notion-memory.sh`

### 3. Gerar o briefing com este formato exato

Produzir um **Briefing Executivo** estruturado assim:

```
🔥 PENDÊNCIAS ATIVAS:
(Listar APENAS os itens não marcados com [x] do action_points.md que sejam relevantes para os participantes desta reunião ou para o tema. Se não houver, escrever "Nenhuma pendência ativa".)

📚 CONTEXTO HISTÓRICO:
(Resumo conciso das notas do dia, memoria_agente e MEMORY.md relevantes para esta reunião: projetos, pessoas, decisões, risk assessment, etc. Ser direto.)
```

Regras:

- Incluir sempre a secção **Pendências Ativas**; não omitir mesmo que sejam poucas.
- Filtrar pendências por relevância aos participantes ou ao título da reunião quando possível.
- Contexto histórico: só o que for útil para essa reunião; evitar texto genérico.

### 4. Entregar o resultado

- Mostrar o briefing ao utilizador no chat.

## Sync (bidirecional: Notion ↔ ~/.claude/memory/)

Antes de gerar briefings, sincronizar:

```bash
~/.claude/scripts/sync-notion-memory.sh
```

**Cron (a cada 30 min):** `*/30 * * * * ~/.claude/scripts/sync-notion-memory.sh >> /tmp/sync-notion-memory.log 2>&1`

- **Bidirecional:** alterações no Notion são puxadas; alterações locais são enviadas para o Notion.
- **Timestamp:** usa sempre a versão mais recente (Notion vs local).
- **Skip:** se não houver alterações em nenhum lado, o script termina com "No updates" sem fazer nada.
- **1Password CLI:** o token da Notion é obtido via `op read`. Configurar em `~/.claude/scripts/sync-notion-memory.conf` (opcional).

## Estrutura em ~/.claude/

```
~/.claude/
├── memory/                    # Dados sincronizados do Notion
│   ├── action_points.md
│   ├── MEMORY.md
│   ├── memory/                # Memória diária (YYYY-MM-DD.md)
│   │   └── YYYY-MM-DD.md
│   └── memoria_agente/
│       ├── perfil_usuario.md
│       ├── pessoas.md
│       └── ...
├── scripts/
│   └── sync-notion-memory.sh  # Sync Notion → memory/
└── skills/
    └── pre-meeting/
        └── SKILL.md
```

## Modo automático (cron + Slack)

Um script corre a cada 10 minutos (`meeting_prepper_wrapper.sh`):

1. Consulta **Google Calendar** — próxima reunião nos próximos 30 min
2. Obtém título, participantes e descrição
3. Gera briefing via Claude (mesmo prompt e fontes)
4. Envia **DM no Slack** para `U01DHE5U6MA`

Ver `~/.claude/scripts/README-meeting-prepper.md` para configuração (1Password, cron, etc.).

---

## Resumo

1. Obter título (e se possível participantes e descrição) da reunião.
2. Ler `~/.claude/memory/action_points.md`, `~/.claude/memory/memory/YYYY-MM-DD.md`, `~/.claude/memory/memoria_agente/*.md`, `~/.claude/memory/MEMORY.md`.
3. Gerar briefing com o template **Pendências Ativas** + **Contexto Histórico**.
4. Mostrar o briefing ao utilizador. Se memory/ estiver vazio, sugerir executar o sync.
