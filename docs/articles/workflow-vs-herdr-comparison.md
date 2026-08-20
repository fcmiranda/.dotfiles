# Comparativo Detalhado: Workflow Atual (Tmux + ACPD + MM + Lazygitrs) vs. Herdr

> **Documento de Análise Técnica e Arquitetural**  
> **Data:** Agosto de 2026  
> **Autor:** Antigravity AI Pair Programmer & fecavmi  
> **Repositório:** [fcmiranda/.dotfiles](file:///home/fecavmi/.dotfiles/main)  

---

## 1. Resumo Executivo & Veredito Estratégico

### Veredito: **Manter e Evoluir a Stack Atual (NÃO Migrar para o Herdr)**

A sua stack atual é um **Control Plane de IA composável baseado na Filosofia Unix**, onde ferramentas especializadas de alta performance se comunicam através de protocolos abertos (JSON-RPC 2.0, Unix Sockets, ANSI buffers e stdout).

O **Herdr** é um projeto ambicioso que busca ser um "runtime de agentes" unificado, mas atua como um **monólito que substitui o multiplexador por inteiro**. Migrar para o Herdr significaria perder o ecossistema maduro do Tmux, a navegação contínua com o Neovim, os pickers customizados do Matchmaker e, principalmente, o **loop bidirecional de revisão de código no Git (`lazygitrs`)**, que é o maior diferencial do seu workflow.

---

## 2. Mapa Conceitual e Terminologia

| Conceito | Stack Atual (Tmux / Sesh / MM) | Herdr | Comportamento Comparado |
| :--- | :--- | :--- | :--- |
| **Sessão / Projeto** | **Tmux Session** (`sesh`) | **Workspace** | No Tmux, projetos são sessões isoladas conectadas via `sesh` + `mm`. No Herdr, são workspaces na mesma instância. |
| **Aba / Janela** | **Tmux Window** | **Tab** | Agrupamento de splits/panes. |
| **Divisão de Terminal** | **Tmux Pane** | **Pane** | Terminais individuais executando shells ou CLIs. |
| **Troca de Sessão Anterior** | `Prefix + L` ([`last-session.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/last-session.sh)) | `keys.last_pane` *(desabilitado por padrão)* | No Tmux, alterna diretamente para a sessão anterior (MRU). No Herdr, `last_pane` pula entre panes cross-workspace se configurado. |
| **Seletor de Sessões** | [`sesh-picker.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/sesh-picker.sh) (`mm`) | `keys.workspace_picker` (`Ctrl+b w`) | No setup atual, usa Matchmaker com busca fuzzy e preview; no Herdr, usa picker TUI embutido. |
| **Seletor de Janelas** | [`window-picker.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/window-picker.sh) (`mm`) | Sidebar TUI fixa / Navigator | No setup atual, popup com preview ao vivo do pane, status de IA colorido e toggle de footer (`?`/`F1`). |

---

## 3. Matriz Comparativa Completa de Recursos

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   MATRIZ DE CAPACIDADES                                         │
├──────────────────────────────────────┬────────────────────────────┬─────────────────────────────┤
│ RECURSO / CAPACIDADE                 │ STACK ATUAL                │ HERDR                       │
├──────────────────────────────────────┼────────────────────────────┼─────────────────────────────┤
│ Loop de Revisão no Git (Diff + AI)   │ ✅ Sim (lazygitrs 'S')     │ ❌ Não                      │
│ Navegação Neovim ⇄ Terminal          │ ✅ Sim (vim-tmux-navigator)│ ❌ Quebra o fluxo           │
│ Motor de Busca TUI & Pickers         │ ✅ Matchmaker (mm) nativo  │ ⚠️ Lista básica embutida    │
│ Detecção de Estado da IA             │ ✅ Hooks estruturados acpd │ ⚠️ Screen Scraping (heur.)  │
│ Popups Flutuantes Dedicados          │ ✅ tmux display-popup      │ ❌ Apenas Splits/Tabs       │
│ Ring Buffer de Atenção               │ ✅ ai-agent-bell-popup.sh  │ ⚠️ Navegação por status     │
│ Persistência de Sessões              │ ✅ tmux-resurrect/continuum│ ⚠️ Persistência própria     │
│ Integração Desktop / OS              │ ✅ Waybar (RTMIN+13)       │ ❌ Isolado no terminal      │
│ Suporte a Áudio / Sound Effects      │ ⚠️ Fácil via script/pw-play│ ✅ MP3 embutido (assets/)   │
│ Arquitetura                          │ 🧩 Modular (Filosofia Unix)│ 📦 Monolítica               │
└──────────────────────────────────────┴────────────────────────────┴─────────────────────────────┘
```

---

## 4. Comparação Arquitetural Detalhada

### A. Loop Bidirecional de Revisão no Git (`lazygitrs`)
* **Na sua stack:**
  1. No `lazygitrs`, você navega pelo diff de um arquivo e seleciona uma linha.
  2. Pressiona `S` e digita uma anotação (ex: *"Tratar erro quando lista for vazia"*).
  3. O `lazygitrs` empurra a nota + arquivo + número da linha diretamente para a sessão ativa do OpenCode/Antigravity via HTTP/SSE.
  4. O agente modifica o código no disco e responde para a API local do `lazygitrs`.
  5. A resposta é renderizada **inline** no diff, logo abaixo da linha anotada.
* **No Herdr:** **Não existe nada equivalente.** O Herdr não possui integração com diffs do Git nem com visualização de anotações inline.

---

### B. Integração com o Editor (`vim-tmux-navigator`)
* **Na sua stack:**
  * Com `vim-tmux-navigator` e `@vim_navigator_pattern`, o atalho `Ctrl+h/j/k/l` transita sem costura entre janelas de código no Neovim e panes de terminal no Tmux.
* **No Herdr:**
  * O Herdr implementa seu próprio gerenciador de terminal em Rust e não repassa ou intercepta eventos de borda coordenados com o Neovim da mesma forma, quebrando a memória muscular de navegação.

---

### C. Detecção de Estado da IA: Hooks Determinísticos vs. Screen Scraping
* **Na sua stack (`acpd`):**
  * O `acpd` escuta eventos estruturados enviados diretamente pelos hooks dos agentes ([`tmux-hook.mjs`](file:///home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/tmux-hook.mjs), [`hook-lib.mjs`](file:///home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/hook-lib.mjs)).
  * Estados como `working`, `question`, `permission`, `error` e `idle` são 100% precisos e atualizam variáveis do Tmux (`@ai_agent_state`, `@ai_agent_bell`).
* **No Herdr:**
  * O Herdr utiliza **manifestos de detecção de tela** (*screen scraping* em `src/detect/manifests/`), lendo as últimas linhas do buffer de texto do PTY para tentar "adivinhar" quando o agente parou em um prompt de confirmação.
  * *Risco:* Falsos positivos frequentes e quebras quando a CLI do agente altera o formato de saída visual.

---

### D. Pickers com Matchmaker (`mm`) vs. Sidebar do Herdr
* **Na sua stack:**
  * [`window-picker.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/window-picker.sh): Exibe todas as janelas de todas as sessões agrupadas por `# Session`, com preview do pane em tempo real, status de IA colorido, seleção múltipla e rodapé dinâmico configurável.
  * [`sesh-picker.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/sesh-picker.sh): Gerencia conexões e alternância de repositórios via `sesh`.
* **No Herdr:**
  * Utiliza uma sidebar lateral fixa com abas e árvores de workspaces. Não oferece preview flexível de múltiplos comandos nem customizações via TOML nos moldes do `mm`.

---

## 5. Diagrama Arquitetural: Abordagem Modular vs. Monolítica

```
Abordagem da Sua Stack (Modular & Composável):
┌───────────────────────────────────────────────────────────────────────────┐
│ CAMADA VISUAL: Tmux + Neovim + Waybar + Popups                            │
│  - Popups arredondados com Alt+o (OpenCode), Ctrl+g (lazygitrs)           │
│  - Transição fluida Neovim ⇄ Panes (Ctrl+h/j/k/l)                         │
├───────────────────────────────────────────────────────────────────────────┤
│ MOTOR DE BUSCA: Matchmaker (mm)                                           │
│  - window-picker.sh (preview ao vivo + badges de IA + ToggleFooter)      │
│  - sesh-picker.sh (MRU + sessões Sesh)                                   │
├───────────────────────────────────────────────────────────────────────────┤
│ CONTROL PLANE: acpd (Daemon Rust @ 127.0.0.1:4040/rpc)                    │
│  - JSON-RPC 2.0 leve com token de segurança (0600)                        │
│  - Status em tempo real, spinners (@ai_agent_spinner) e bells            │
├───────────────────────────────────────────────────────────────────────────┤
│ CODE REVIEW LOOP: lazygitrs                                               │
│  - Linha do Diff ➔ Tecla 'S' ➔ Prompt ➔ Agente de IA ➔ Resposta Inline  │
└───────────────────────────────────────────────────────────────────────────┘

Abordagem do Herdr (Monólito Fechado):
┌───────────────────────────────────────────────────────────────────────────┐
│ HERDR (Runtime de Terminal Tudo-em-Um)                                    │
│  - Multiplexador próprio (substitui o Tmux)                               │
│  - Parser de PTY e Renderizador TUI próprio                               │
│  - Screen Scraper embutido (lê o texto do terminal para deduzir estado)  │
│  - Sidebar fixa e atalhos internos                                        │
│  - Sem integração com Neovim / Waybar / Git Review                       │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 6. O que Pode Ser Adotado do Herdr no Seu Setup Atual?

Em vez de migrar, você pode incorporar as boas ideias do Herdr sem perder nada da sua stack:

1. **Notificações Sonoras (Audio Cues):**
   * O Herdr reproduz sons curtos (`done.mp3`, `request.mp3`) quando um agente necessita de resposta.
   * *Implementação no seu setup:* O [`ai-agent-bell-popup.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/ai-agent-bell-popup.sh) ou o próprio `acpd` pode acionar `pw-play /usr/share/sounds/freedesktop/stereo/bell.oga` de forma assíncrona ao receber `question` ou `permission`.
2. **Capacidades de RPC para Agentes Autônomos:**
   * O `acpd` já incorporou todos os métodos RPC úteis do Herdr (`tmux.capture_pane`, `tmux.send_keys`, `tmux.list_panes`, `tmux.list_windows`, `tmux.list_sessions`).

---

## 7. Tabela Comparativa de Atalhos (Cheat Sheet)

| Ação Desejada | Atalho na Sua Stack (Tmux) | Atalho no Herdr |
| :--- | :--- | :--- |
| **Popup Flutuante da IA** | `Alt + o` (`display-popup`) | ❌ *(Não suportado como popup flutuante)* |
| **Ir para Janela da IA** | `Alt + a` (janela `ai`) | `prefix + 1..9` / sidebar |
| **Popup do Git** | `Ctrl + g` (`lazygitrs`) | ❌ *(Precisa abrir em split/tab manual)* |
| **Alternar Sidebar de IA** | `Prefix + o` (split de 35%) | `prefix + b` (toggle sidebar do Herdr) |
| **Rotacionar Atenção (Bells)** | `Prefix + i` (`ai-agent-bell-popup.sh`) | `prefix + o` (`open_notification_target`) |
| **Seletor de Janelas / Workspaces** | `Prefix + s` ([`window-picker.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/window-picker.sh)) | `prefix + w` (`workspace_picker`) |
| **Alternar para Última Sessão** | `Prefix + L` ([`last-session.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/last-session.sh)) | `prefix + l` *(se `last_pane` configurado)* |
| **Seletor de Sessões (Sesh)** | `Prefix + t` ([`sesh-picker.sh`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/sesh-picker.sh)) | `prefix + w` |
| **Navegação Direta 0-9** | `Ctrl + 0..9` (sem prefixo) | `prefix + 1..9` |

---

## 8. Conclusão

Sua stack atual representa o melhor estado da arte para desenvolvimento com IA no terminal:
* **Autonomia e Customização Total:** Nenhuma dependência de binários monolíticos fechados.
* **Ergonomia Máxima:** Zero atrito entre terminal, Neovim e Git.
* **Controle Determinístico:** Estados de agentes gerenciados com precisão cirúrgica via `acpd`.
