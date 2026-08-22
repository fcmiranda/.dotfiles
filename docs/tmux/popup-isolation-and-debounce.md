# Tmux Popup Isolation, ACPD Debounce & Event-Driven Architecture

Este documento registra os problemas identificados de oscilação visual, colisão de renderização em popups flutuantes durante streaming de IA, e as soluções arquiteturais definitivas aplicadas no `tmux` e no daemon `acpd`.

---

## 1. Problemas Identificados (Root Causes)

### 🔴 Problema A: Trepidação do Ícone de Status (Flicker / Bounce)
- **Causa:** Durante execuções de IA (como Antigravity / OpenCode), tarefas encadeadas disparam eventos de ciclo de vida rápidos: `PostInvocation` (`idle`) seguido de `PreInvocation` (`working`) em intervalos de 20ms a 100ms a cada leitura de arquivo ou comando executado.
- **Efeito Visual:** O ícone e o pill da aba no topo do tmux ficavam piscando e oscilando freneticamente entre amarelo (`󰑮` working) e azul (`󱥂` idle) várias vezes por segundo durante uma única resposta da IA.

### 🔴 Problema B: Borda Superior e Linha de Input Desaparecendo em Popups
- **Causa:** O comando `display-popup` do tmux renderiza uma camada flutuante por cima do painel ativo. Enquanto a IA está respondendo, o painel de fundo cospe dezenas de linhas de texto e escape codes de rolagem por segundo. No motor do tmux, a rotina `server_client_draw_pane` atualiza as células modificadas do painel de fundo diretamente no terminal, sobrescrevendo a camada do popup.
- **Efeito Visual:** A moldura superior arredondada (`╭─── Sesh ───╮`) e o campo de busca (`⚡ ` / ` `) sumiam da tela enquanto a IA estava gerando respostas, só reaparecendo quando a IA finalizava.

### 🔴 Problema C: Perda de Navegação ao Selecionar Sessão/Janela
- **Causa:** Scripts de popup que capturavam o estado anterior executavam um `tmux switch-client -t ""` incondicional no retorno, forçando o cliente de volta para onde o popup foi aberto e anulando a seleção de uma nova sessão ou janela.

### 🔴 Problema D: Polling Periódico Inútil (`status-interval 1`)
- **Causa:** O tmux acordava 60 vezes por minuto para reavaliar formatos e executar subprocessos de formatação em segundo plano, mesmo com o terminal ocioso.

---

## 2. Soluções Implementadas (Architectural Fixes)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           ARQUITETURA FINAL                             │
├────────────────────────────────┬────────────────────────────────────────┤
│ IA Ociosa / Terminal Estático  │ Abertura Direta & Nativa               │
│                                │ (display-popup imediato sem backdrop)  │
├────────────────────────────────┼────────────────────────────────────────┤
│ IA Respondendo / Executando    │ Backdrop com Snapshot Transparente     │
│ (@ai_agent_state_raw = busy)   │ (tmux capture-pane -ep -> _popups)     │
├────────────────────────────────┼────────────────────────────────────────┤
│ Transições de Ferramentas IA   │ Debounce de 400ms no ACPD              │
│ (Tool Calls em sequência)      │ (Cancela idles intermediários)         │
├────────────────────────────────┼────────────────────────────────────────┤
│ Consumo de CPU & Bateria       │ status-interval 0 (100% Event-Driven)  │
│                                │ (Atualizações via ACPD / Tmux Events)  │
└────────────────────────────────┴────────────────────────────────────────┘
```

---

### 🛡️ 1. Debounce de 400ms e Deduplicação no ACPD (`dev/github/acpd`)
No arquivo `src/adapters.rs` do daemon `acpd`:
- **Debounce de 400ms para `AgentState::Idle`:**
  ```rust
  // Se o estado for Idle, agenda uma tarefa assíncrona de 400ms
  let task = tokio::spawn(async move {
      tokio::time::sleep(tokio::time::Duration::from_millis(400)).await;
      // Atualiza para Idle apenas se nenhuma nova tool call entrou no período
      set_tmux_option(&pane_id, "@ai_agent_state", &t.icon).await;
      set_tmux_option(&pane_id, "@ai_agent_state_raw", "idle").await;
      refresh_tmux_client().await;
  });
  ```
- **Cancelamento Imediato:** Qualquer novo evento `Working` cancela a tarefa pendente de `Idle`, mantendo o spinner girando sem interrupção.
- **Deduplicação de Estados (`pane_states`):** Evita chamadas repetidas a comandos do tmux quando o estado do painel não foi alterado.

---

### 🪄 2. Backdrop com Snapshot Transparente Congelado
Nos scripts dos popups (`sesh-picker.sh`, `window-picker.sh`, `lazygitrs-popup.sh`):

```bash
AI_STATE=idle
if [ "" = "busy" ] || [ "" = "working" ]; then
    CURRENT_PANE=%2
    ORIG_TARGET=_dotfiles/main:0
    
    # 1. Tira um snapshot visual do buffer com cores ANSI (<1ms)
    tmux capture-pane -ep -t "" > /tmp/tmux-backdrop.ansi 2>/dev/null || true

    # 2. Carrega o snapshot na janela de fundo estática
    if ! tmux list-windows -t "_popups" -F '#W' 2>/dev/null | grep -q "^backdrop$"; then
        tmux new-window -d -t "_popups" -n "backdrop" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null"
    else
        tmux respawn-window -k -t "_popups:backdrop" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null"
    fi

    # 3. Alterna o cliente para o backdrop limpo e abre o popup
    tmux switch-client -t "_popups:backdrop" 2>/dev/null || true
    tmux display-popup -b rounded -T " Titulo " -w 80% -h 35% -y 34 -E "..."

    # 4. Restauração inteligente: apenas se o usuário cancelou (ainda em _popups)
    CURRENT_SESS=_dotfiles/main
    if [ "" = "_popups" ]; then
        tmux switch-client -t "" 2>/dev/null || true
    fi
    exit 0
else
    # Terminal limpo/estático: abre o popup nativo direto sem backdrop
    exec tmux display-popup -b rounded -T " Titulo " -w 80% -h 35% -y 34 -E "..."
fi
```

---

### ⚡ 3. Barra de Status 100% Orientada a Eventos (`status-interval 0`)
No `tmux.conf`:
```tmux
# Event-driven status bar (sem polling de relógio no fundo — acionado por eventos e acpd)
set -g status-interval 0
```
- **Vantagens:** 0.0% de uso de CPU em repouso, sem forks de processos desnecessários.
- **Animação do Spinner:** Continua rodando a 12 FPS (83ms) pelo daemon `acpd` via `refresh_tmux_client()`.

---

## 3. Arquivos Envolvidos e Referências

- [`acpd/src/adapters.rs`](../../dev/github/acpd/src/adapters.rs): Implementação do debounce de 400ms e deduplicação de estado.
- [`tmux/.config/tmux/tmux.conf`](../../tmux/.config/tmux/tmux.conf): Configuração de `status-interval 0` e popups ergonômicos no terço inferior.
- [`tmux/.config/tmux/sesh-picker.sh`](../../tmux/.config/tmux/sesh-picker.sh): Seletor de sessões com backdrop inteligente e preservação de navegação.
- [`tmux/.config/tmux/window-picker.sh`](../../tmux/.config/tmux/window-picker.sh): Seletor de janelas Matchmaker com backdrop inteligente.
- [`tmux/.config/tmux/lazygitrs-popup.sh`](../../tmux/.config/tmux/lazygitrs-popup.sh): Popup do Lazygitrs posicionado no rodapé (`-y 28 -h 45%`).
- [`docs/tmux/ai-status-bar.md`](ai-status-bar.md): Documentação geral do status bar e estados dos agentes de IA.
