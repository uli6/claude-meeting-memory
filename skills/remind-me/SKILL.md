---
name: remind-me
description: "Cria entradas em action_points.md. Use SEMPRE que o utilizador disser me lembre disso, me lembre de, remind me ou similar. Com link Slack executa add_action_point.py. Sem link usa o texto."
---

# Remind Me (Action Points)

**IMPORTANTE:** Quando o utilizador disser "me lembre disso", "me lembre de", "remind me" ou similar — **EXECUTE imediatamente** o script `add_action_point.py`. **NÃO** responda que não consegue acessar links do Slack. O script obtém o conteúdo via API.

## Gatilhos (executar o script sempre que ver)

- "me lembre disso" (com link Slack)
- "me lembre de [X]"
- "remind me of this" / "remind me to [X]"
- "adiciona aos action points"
- "cria um action point"

## Fluxo

### 1. Com link do Slack

Se o utilizador colar um URL do Slack (ex.: `https://workspace.slack.com/archives/C.../p...`) e disser "me lembre disso" ou similar:

1. Extrair o URL do Slack da mensagem.
2. Executar o script com o URL:
   ```bash
   cd ~/.claude/scripts && op run --env-file=meeting-prepper-secrets.env -- python3 add_action_point.py --slack-url "URL_COLADO" "me lembre disso"
   ```
3. O script obtém o conteúdo da mensagem no Slack, usa o LLM para formatar e adiciona a `action_points.md`.

### 2. Sem link do Slack

Se o utilizador disser apenas "me lembre de falar com a Sheila sobre M&A" (ou similar):

1. Executar o script com o texto:
   ```bash
   cd ~/.claude/scripts && op run --env-file=meeting-prepper-secrets.env -- python3 add_action_point.py "me lembre de falar com a Sheila sobre M&A"
   ```
2. O script usa o LLM para formatar e adiciona a `action_points.md`.

### 3. Formato da entrada

Todas as entradas seguem:
```
- [ ] @[Nome]: [Assunto] (Criado em: YYYY-MM-DD)
```

Exemplo: `- [ ] @Sheila: Conversa pendente sobre processos de M&A e tema da Deloitte (Criado em: 2026-02-24)`

## Alternativa (sem op run)

Se o utilizador já tiver as variáveis no ambiente (SLACK_BOT_TOKEN, etc.):
```bash
~/.claude/scripts/add_action_point.py "me lembre de X"
```

## Paths

- Script: `~/.claude/scripts/add_action_point.py`
- Destino: `~/.claude/memory/action_points.md`
- Secrets: `~/.claude/scripts/meeting-prepper-secrets.env`
