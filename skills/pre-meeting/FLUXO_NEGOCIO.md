# Fluxo de Negócio — Meeting Prepper

Documento que detalha o fluxo de negócio do **Meeting Prepper**: desde o gatilho até à entrega do briefing e exceções.

---

## 1. Objetivo

Preparar o utilizador para reuniões com um **briefing executivo** que combine:
- **Pendências ativas** (action points não concluídos) relevantes para a reunião
- **Contexto histórico** (memória do dia, projetos, pessoas, decisões) útil para essa reunião

A entrega pode ser **automática** (cron + Google Calendar + WhatsApp) ou **sob pedido** (skill no Claude Code, com dados da reunião fornecidos pelo utilizador).

---

## 2. Dois modos de operação

| Modo | Gatilho | Fonte da reunião | Entrega |
|------|---------|-------------------|---------|
| **Automático** | Cron a cada 10 min | Google Calendar API (próximos 30 min) | Slack DM (U01DHE5U6MA) |
| **Sob pedido** | Utilizador pede "briefing da reunião" / "meeting prepper" | Título (e opcionalmente participantes/descrição) dados pelo utilizador | Chat (Claude mostra o briefing) |

O **conteúdo do briefing** é o mesmo nos dois modos: template **Pendências Ativas** + **Contexto Histórico**, gerado a partir dos mesmos ficheiros de memória.

---

## 3. Fluxo automático (cron + script)

### 3.1 Gatilho

- **Cron OpenClaw**: a cada 10 minutos (`*/10 * * * *`, Europe/Madrid).
- Session key: `agent:main:cron:meeting_prepper`.
- O agente executa o script:  
  `/home/ulisses/.openclaw/workspace/scripts/meeting_prepper_wrapper.sh`

### 3.2 Autenticação e secrets

1. O **wrapper** lê `OP_SERVICE_ACCOUNT_TOKEN` de `op_secrets.env` e exporta no ambiente.
2. Executa: `op run --env-file=op_secrets.env -- python3 meeting_prepper.py`
3. O **1Password** injecta no ambiente (a partir de refs em `op_secrets.env`):
   - `GOOGLE_CAL_CLIENT_ID`
   - `GOOGLE_CAL_CLIENT_SECRET`
   - `GOOGLE_CAL_REFRESH_TOKEN`
   - (opcional) `WHATSAPP_TARGET` (default: +351919651334)

Se o token ou as refs falharem, o script termina com erro e o cron reporta ao utilizador (reconfigurar: ver `GOOGLE_CAL_RECONFIGURE.md`).

### 3.3 Obtenção das reuniões (Google Calendar)

1. **OAuth2**: refresh token → access token; construir cliente Google Calendar API v3.
2. **Regra "Ausente"**:
   - Se existir no calendário um evento **«Ausente»** às **00:00** ou **todo-o-dia** nesse dia (Europe/Madrid), o script **não processa nenhuma reunião** e termina com sucesso (exit 0). Log: "Dia marcado como Ausente. Meeting Prepper não executa."
3. **Janela temporal**: eventos que **começam** nos **próximos 30 minutos** (UTC).
4. **Filtros**:
   - Apenas eventos **com participantes** (attendees); blocos pessoais sem participantes são ignorados.
   - Eventos com título «Ausente» (avulsos) são ignorados.
5. **Dados por reunião**: `uid`, `title`, `description`, `participants`, `start`.

Se não houver eventos nessa janela: log "Nenhuma reunião nos próximos 30 minutos.", exit 0.

### 3.4 Evitar reenvios (cache de processadas)

- Ficheiro: `workspace/memory/.processed_meetings.txt`
- Contém um **UID por linha** (ID do evento no Google Calendar ou `title|start_iso`).
- Para cada reunião obtida:
  - Se o UID estiver no ficheiro → **ignorar** (não gerar briefing nem enviar). Log: "Reunião já processada, pulando: [título]".
  - Se não estiver → continuar para geração do briefing.

### 3.5 Geração do briefing (reasoner)

Para cada reunião **não** processada:

1. **Invocação**: `openclaw agent --agent reasoner --message "<prompt>" --timeout 180`
2. **Prompt** inclui:
   - Título, participantes e descrição da reunião.
   - **Instruções obrigatórias**: ler (via tools) os ficheiros:
     - `workspace/memory/action_points.md` — pendências
     - `workspace/memory/YYYY-MM-DD.md` — memória do dia (data de hoje)
     - `workspace/memoria_agente/*.md` — perfil, pessoas, projetos, pendencias, etc.
     - `workspace/MEMORY.md` — memória executiva
   - Pedido de output no formato exato:
     - **PENDÊNCIAS ATIVAS:** apenas itens não marcados com `[x]` relevantes para participantes/tema; ou "Nenhuma pendência ativa".
     - **CONTEXTO HISTÓRICO:** resumo conciso do que for útil para esta reunião (notas, projetos, pessoas, decisões, riscos).
3. **Timeout**: 180 s para o reasoner; o script tem um buffer extra (195 s) no `subprocess.run`.
4. Se o reasoner falhar ou devolver vazio: log do erro, **não** marcar UID como processado (será tentado de novo no próximo ciclo). Passar à próxima reunião.

### 3.6 Entrega por Slack DM

1. **Envio**: Slack SDK `conversations.open` + `chat.postMessage` para utilizador `U01DHE5U6MA`.
2. Se o envio falhar: log do erro, **não** marcar UID como processado. Passar à próxima reunião.
3. Se o envio for bem-sucedido:
   - **Append** do UID a `memory/.processed_meetings.txt`.
   - Log: "Briefing enviado por Slack."

### 3.7 Comportamento do agente (cron)

- Se o script **enviar** briefing por Slack: o agente responde **NO_REPLY** (evitar duplicar a mensagem no chat).
- Se o script **falhar** (erro de Calendar, 1Password, timeout, etc.): o agente responde com a mensagem de erro ao utilizador.
- Erros de conta de serviço (1Password) ou autenticação Google (403, refresh token expirado): indicar ao Ulisses que é preciso reconfigurar (`GOOGLE_CAL_RECONFIGURE.md`).

---

## 4. Fluxo sob pedido (skill no Claude Code)

Usado quando o utilizador pede explicitamente um briefing (ex.: "briefing da reunião", "meeting prepper", "prepara-me para a reunião X") **sem** depender do cron nem do Google Calendar.

### 4.1 Gatilho

- Frases como: "briefing da reunião", "meeting prepper", "prepara-me para a reunião", "o que tenho de saber para a reunião X".
- Ou o utilizador partilha título/participantes/descrição de uma reunião e pede um resumo.

### 4.2 Obtenção dos dados da reunião

- Se o utilizador já indicou **título** (e opcionalmente **participantes** e **descrição**): usar esses dados.
- Se não: pedir ao utilizador que indique a reunião (título e, se possível, participantes e descrição) ou que cole os dados do convite/Google Calendar.

### 4.3 Leitura dos ficheiros (obrigatória)

No Claude Code, os paths são em `~/.claude/memory/` (sincronizados do Notion via `sync-notion-memory.sh`):

| Ficheiro | Propósito |
|----------|-----------|
| `~/.claude/memory/action_points.md` | Pendências ativas (itens sem `[x]`) → secção **Pendências Ativas** |
| `~/.claude/memory/memory/YYYY-MM-DD.md` | Memória diária do dia (contexto do dia) |
| `~/.claude/memory/memoria_agente/*.md` | Perfil, pessoas, projetos, pendencias, decisoes, diretrizes, etc. |
| `~/.claude/memory/MEMORY.md` | Memória executiva geral (estado atual, projetos, próximos passos) |

### 4.4 Geração do briefing

- **Formato exato**:
  - **PENDÊNCIAS ATIVAS:** listar apenas itens não concluídos relevantes para participantes ou tema da reunião; ou "Nenhuma pendência ativa".
  - **CONTEXTO HISTÓRICO:** resumo conciso do que for útil para esta reunião (evitar texto genérico).
- Filtrar pendências por relevância; incluir sempre a secção Pendências Ativas.

### 4.5 Entrega

- Mostrar o briefing ao utilizador no chat.
- Opcional: sugerir envio manual por WhatsApp ou execução do wrapper no OpenClaw para o fluxo completo (Calendar + envio automático).

---

## 5. Fontes de dados (resumo)

| Dado | Ficheiro / origem |
|------|-------------------|
| Pendências ativas | `~/.claude/memory/action_points.md` (Claude Code) / `workspace/memory/action_points.md` (OpenClaw) |
| Memória do dia | `~/.claude/memory/memory/YYYY-MM-DD.md` / `workspace/memory/YYYY-MM-DD.md` |
| Pessoas, projetos, perfil, pendências gerais | `~/.claude/memory/memoria_agente/*.md` / `workspace/memoria_agente/*.md` |
| Estado executivo, decisões, próximos passos | `~/.claude/memory/MEMORY.md` / `workspace/MEMORY.md` |
| Reuniões já processadas (só fluxo automático) | `workspace/memory/.processed_meetings.txt` |
| Reuniões (só fluxo automático) | Google Calendar API (próximos 30 min) |
| **Fonte primária** | Notion [Clawdia Memory](https://www.notion.so/Clawdia-Memory-312d9a25aaca80689a81cbe3376ab260) — sync via `~/.claude/scripts/sync-notion-memory.sh` |

---

## 6. Exceções e regras de negócio

- **Dia "Ausente"**: evento «Ausente» às 00:00 ou todo-o-dia → não executar Meeting Prepper nesse dia (fluxo automático).
- **Reunião já processada**: UID em `.processed_meetings.txt` → não gerar novo briefing nem reenviar (fluxo automático).
- **Falha no reasoner ou no WhatsApp**: não adicionar UID ao cache; no próximo ciclo (10 min) a mesma reunião será tentada de novo.
- **Timeout**: reasoner 180 s; cron com margem (ex. 300 s). Se a sessão encerrar antes do envio, a reunião não fica como processada e será reprocessada.

---

## 7. Diagrama de fluxo (automático)

```
[Cron 10 min] → [Wrapper: export OP_SERVICE_ACCOUNT_TOKEN]
       → [op run → meeting_prepper.py]
       → [Carregar op_secrets.env / resolver credenciais 1Password]
       → [Google Calendar API: eventos próximos 30 min, com participantes]
       → [Se dia "Ausente" → exit 0]
       → [Para cada evento não em .processed_meetings.txt]
              → [openclaw agent reasoner: ler action_points, memory, memoria_agente, MEMORY.md]
              → [Gerar briefing: Pendências Ativas + Contexto Histórico]
              → [send_whatsapp(briefing)]
              → [Append UID a .processed_meetings.txt]
       → [Log "Briefing enviado" / NO_REPLY no cron]
```
