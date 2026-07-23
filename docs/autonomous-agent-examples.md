# Casos de Uso Práticos: Visão Global de Terminal para Agentes Autônomos de IA

> **Escopo**: Demonstrações reais de como os métodos JSON-RPC do `acpd` (`tmux.list_sessions`, `tmux.list_windows`, `tmux.list_panes`, `tmux.capture_pane`, `tmux.send_keys`, `agentState/list`) transformam a IA em um desenvolvedor pareando em tempo real.
> **Arquivo**: [`/home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples.md`](file:///home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples.md)

---

## 1. Comparativo: O `herdr` faz uso dessas capacidades?

> **Resposta:** **SIM E NÃO.** O `herdr` possui uma ideia parecida, mas a sua arquitetura com `acpd` + `tmux` tem vantagens superiores.

### Como o `herdr` faz:
- O `herdr` implementa um socket Unix JSON-RPC nativo (`herdr.sock`) integrado ao seu próprio emulador de terminal/multiplexador em Rust.
- Ele permite que agentes listem painéis, enviem texto e capturem o buffer de saída dos painéis criados dentro do `herdr`.

### Por que a sua arquitetura com `acpd` + `tmux` é MELHOR:
1. **Preservação Total do Ecossistema**: O `herdr` te obriga a **abandonar o `tmux`**. Com a sua stack (`acpd`), você adicionou as mesmas APIs de controle via socket JSON-RPC em cima do `tmux`, mantendo o `vim-tmux-navigator`, `tmux-resurrect`, `tmux-thumbs`, `sesh` e os painéis do Waybar.
2. **Integração com o Loop de Revisão no Git**: O `herdr` não possui o servidor de anotações bidirecional do `lazygitrs`. Sua stack integra a navegação global no terminal com a revisão de código inline no diff do Git.

---

## 2. Exemplos Práticos e Reais de Uso

---

### 🟢 Exemplo 1: Diagnóstico Autônomo de Erros Full-Stack (Backend + Frontend + DB Logs)

#### 🎬 Cenário Real:
Você está testando o frontend em um navegador e clica em "Concluir Compra". A tela exibe o erro `"500 Internal Server Error"`.

#### 🤖 O que a IA faz sozinha via RPC:
1. Você envia o prompt para a IA (no popup `Alt+o` ou janela `Alt+a`):  
   > *"O botão de checkout deu erro 500. Descubra a causa e corrija."*
2. A IA executa **`tmux.list_sessions`** ➔ Descobre as sessões ativas `webapp` (frontend), `api-server` (backend Rust) e `postgres` (DB).
3. A IA executa **`tmux.list_windows`** na sessão `api-server` ➔ Localiza a janela `server-logs`.
4. A IA executa **`tmux.capture_pane`** na janela `server-logs` ➔ Lê a saída do buffer em tempo real:
   ```text
   [ERROR] 2026-07-22 20:05:12 - Failed to execute query: connection pool exhausted (port 5432)
   ```
5. A IA edita o arquivo de configuração do pool de conexões no disco e te responde no chat:
   > *"Identifiquei que o backend na sessão 'api-server' estourou o limite do pool de conexões do Postgres. Aumentei o `max_connections` de 5 para 20 no `src/config.rs:42`."*

---

### 🟢 Exemplo 2: Orquestração Multagente Sem Conflito (`agentState/list`)

#### 🎬 Cenário Real:
Você abre duas tarefas paralelas:
- **Agente A (OpenCode)** na janela `ai-refactor`: Refatorando o módulo de autenticação `auth.rs`.
- **Agente B (Antigravity)** na janela `ai-docs`: Escrevendo a documentação da API e os testes de integração.

#### 🤖 O que o Agente B faz sozinho via RPC:
1. O Agente B precisa rodar a suíte de testes da API, mas quer evitar conflitos caso o Agente A ainda esteja alterando arquivos.
2. O Agente B envia uma requisição **`agentState/list`** ao `acpd`:
   ```json
   {
     "jsonrpc": "2.0",
     "result": {
       "%1 (ai-refactor)": { "state": "working", "last_update": 1753224000 },
       "%4 (ai-docs)": { "state": "idle", "last_update": 1753224050 }
     },
     "id": 1
   }
   ```
3. O Agente B vê que a janela `%1 (ai-refactor)` está com o estado `"working"` (ocupada).
4. O Agente B aguarda o estado mudar para `"idle"` antes de executar os testes, **evitando conflitos de arquivos simultâneos!**

---

### 🟢 Exemplo 3: Re-execução Autônoma de Testes em Background pós-Refatoração

#### 🎬 Cenário Real:
Você aceitou uma sugestão de código da IA enviada pelo loop de revisão do `lazygitrs`.

#### 🤖 O que a IA faz sozinha via RPC:
1. Ao concluir a escrita do código no disco, a IA chama **`tmux.list_windows`** para verificar se existe uma janela de testes aberta no projeto.
2. Caso não exista, a IA executa **`tmux.new_window`** com o nome `test-runner`.
3. A IA executa **`tmux.send_keys`** para rodar `cargo test` ou `npm test` naquela nova janela em background.
4. A IA aguarda a execução e chama **`tmux.capture_pane`** para ler o relatório final.
5. Se a suíte passar, ela atualiza o status da nota no `lazygitrs` para `Addressed` e te notifica:
   > *"Refatoração aplicada e 128 testes unitários aprovados no background!"*

---

### 🟢 Exemplo 4: "Relatório de Troca de Turno" ao Voltar da Pausa

#### 🎬 Cenário Real:
Você deixou 3 tarefas com a IA e foi tomar um café. Ao retornar ao computador, você quer um resumo rápido do status de todo o seu terminal.

#### 🤖 O que a IA faz sozinha via RPC:
Você abre o popup flutuante (`Alt+o`) e digita: *"Resumo do workspace."*

1. A IA dispara em lote: **`tmux.list_sessions`** + **`tmux.list_windows`** + **`agentState/list`**.
2. A IA gera um painel síntese no chat:
   ```text
   📊 RELATÓRIO DO WORKSPACE:
   ─────────────────────────────────────────────────────────────
   • Sessão 'dotfiles':
     - acpd daemon: 6/6 unit tests ok (127.0.0.1:4040).
   • Sessão 'webapp':
     - Janela 'ai-refactor': Concluída (Idle há 5 min).
     - Janela 'ai-docs': Aguardando confirmação do usuário (Awaiting Permission).
     - Janela 'vite': Dev server ativo em http://localhost:5173.
   ```

---

### 🟢 Exemplo 5: Correção Automática de Build Falhando no Terminal

#### 🎬 Cenário Real:
Você tenta rodar `cargo build` na janela do seu terminal e o compilador acusa um erro de sintaxe complexo em um arquivo distante.

#### 🤖 O que a IA faz sozinha via RPC:
1. No seu chat da IA, você digita: *"Corrija o erro de compilação da janela ao lado."*
2. A IA executa **`tmux.list_panes`** na janela atual ➔ Identifica o pane vizinho com o terminal de dev.
3. A IA executa **`tmux.capture_pane`** com `escape_sequences: true` ➔ Lê a mensagem de erro do compilador com as cores e o número exato da linha (`src/parser.rs:142:18`).
4. A IA abre o arquivo `src/parser.rs` no disco, aplica a correção necessária e executa **`tmux.send_keys`** com `keys: ["cargo build\n"]` para rodar o build novamente no seu terminal.
5. O build passa sem você ter saído do seu lugar!

---

### 🟢 Exemplo 6: Monitoramento de Performance & Métricas de Logs ao Vivo

#### 🎬 Cenário Real:
Você está realizando um benchmark ou teste de carga no seu webapp e quer saber se há algum gargalo de memória ou vazamento.

#### 🤖 O que a IA faz sozinha via RPC:
1. Você solicita: *"Monitore o consumo de recursos da API enquanto faço requisições."*
2. A IA utiliza **`tmux.list_windows`** para encontrar a janela onde o `btop` ou `htop` está rodando (`prefix+B`).
3. A IA utiliza **`tmux.capture_pane`** periodicamente a cada 5 segundos para inspecionar o uso de CPU e memória RAM do processo alvo.
4. Se o consumo exceder 90%, ela captura a stack trace do processo via `tmux.send_keys` e te apresenta uma análise detalhada dos gargalos.

---

## 3. Matriz de Métodos JSON-RPC 2.0 do `acpd`

| Método | Tipo | Parâmetros | Caso de Uso Prático |
|---|---|---|---|
| `agentState/update` | Mutação | `{pane_id, state, timestamp?}` | Hook notifica que a IA começou a trabalhar ou ficou idle |
| `agentState/list` | Consulta | *Nenhum* | Agentes verificam o estado de outros agentes para evitar conflitos |
| `tmux.list_sessions` | Inspeção | *Nenhum* | Descobrir todas as sessões do tmux no sistema |
| `tmux.list_windows` | Inspeção | `{target?}` | Encontrar janelas de testes, logs, servidores ou editores |
| `tmux.list_panes` | Inspeção | `{target?, all?}` | Listar dimensões, CWD e comandos dos painéis ativos |
| `tmux.capture_pane` | Inspeção | `{target?, start_line?, end_line?, escape_sequences?}` | Ler logs de compilação, saída de testes ou erros de servidores |
| `tmux.send_keys` | Controle | `{target?, keys: [], literal?}` | Enviar comandos como `cargo test` ou `npm run build` |
| `tmux.split_pane` | Controle | `{command?, target_pane?, vertical?}` | Criar novos painéis laterais de trabalho |
| `tmux.new_window` | Controle | `{name?, target?, command?}` | Criar janelas dedicadas de execução em background |
| `tmux.kill_pane/window/session` | Teardown | `{target}` | Limpar painéis e processos finalizados |

---
*Documento salvo em: [`/home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples.md`](file:///home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples.md)*
