# Guia Definitivo: Configuração e Uso do AI-Jail e AI-Memory

Este guia descreve passo a passo a configuração inicial, automação via systemd, rastreamento no dotfiles (stow) e o fluxo de trabalho diário para utilizar o **ai-jail** e o **ai-memory**.

---

## 1. Visão Geral das Ferramentas

* **ai-jail**: Executa agentes de IA em um ambiente isolado (sandbox Linux usando `bubblewrap` e `Landlock`). Garante que o agente não altere nem leia arquivos fora do repositório ou acesse credenciais do sistema.
* **ai-memory**: Servidor MCP e banco de dados SQLite local que registra sessões, observações, histórico e páginas de conhecimento (wiki) dos agentes.

---

## 2. Passo a Passo de Configuração Inicial (Executado Uma Única Vez)

### Passo 1: Inicializar a Estrutura do ai-memory
Cria os diretórios e o arquivo de configuração padrão em `~/.local/share/ai-memory/config.toml`:
```bash
ai-memory init
```

### Passo 2: Configurar o Serviço de Segundo Plano (Systemd User Service)
Crie o arquivo de serviço do sistema em `~/.config/systemd/user/ai-memory.service`:

```ini
[Unit]
Description=ai-memory background daemon
After=network.target

[Service]
ExecStart=/home/fecavmi/.cargo/bin/ai-memory serve --transport http
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
```

Em seguida, recarregue os daemons e ative o serviço para iniciar no login:
```bash
systemctl --user daemon-reload
systemctl --user enable --now ai-memory
```

Para verificar se o serviço está ativo e saudável:
```bash
systemctl --user status ai-memory
ai-memory status
```

---

### Passo 3: Adotar as Configurações no Dotfiles (`stow-it`)
Adote o arquivo de serviço do systemd e o arquivo de configuração do ai-memory no pacote `ai-memory` do seu repositório de dotfiles:

```bash
~/.dotfiles/main/utils/.local/bin/stow-it ~/.config/systemd/user/ai-memory.service ai-memory
~/.dotfiles/main/utils/.local/bin/stow-it ~/.local/share/ai-memory/config.toml ai-memory
```

Verifique os pacotes stowed:
```bash
./stow.sh -s
```

---

### Passo 4: Registrar os Servidores MCP nos Agentes
Vincule o ai-memory como servidor MCP nos seus clientes/agentes:

```bash
# Para OpenCode
ai-memory install-mcp --client open-code --apply

# Para Codex CLI
ai-memory install-mcp --client codex --apply
```

---

### Passo 5: Instalar os Lifecycle Hooks
Permita que o ai-memory capture o início, fim de sessão e contexto dos agentes:

```bash
# Para OpenCode
ai-memory install-hooks --agent opencode --apply

# Para Codex
ai-memory install-hooks --agent codex --apply
```

---

### Passo 6: Instalar Instruções e Skills no Repositório
No repositório do seu projeto, injete as instruções e skills do ai-memory no `AGENTS.md` ou `CLAUDE.md`:

```bash
ai-memory install-instructions
```

---

## 3. Fluxo de Trabalho Diário (Ordem Correta de Execução)

Com o serviço do systemd ativado, o servidor do `ai-memory` estará sempre rodando em segundo plano.

### Opção A: Executar o Agente com Sandbox + Memória (Recomendado)
Para iniciar uma sessão do OpenCode com o ai-jail e ai-memory:

```bash
ai-jail ai-memory run opencode --yolo
```

> **Atenção:** Caso seja a primeira vez no projeto e o ai-memory solicite `Select [1]:`, digite **`0`** no terminal para iniciar uma nova sessão.

Para criar uma nova *workstream* diretamente sem prompt interativo:
```bash
ai-jail ai-memory run --new minhasessao opencode --yolo
```

---

### Opção B: Executar o Agente Direto no Sandbox (`ai-jail opencode --yolo`)
Na execução direta, o agente **já tem acesso completo a todo o histórico e conhecimento do projeto** via plugin/MCP do `ai-memory`:

```bash
# OpenCode
ai-jail opencode --yolo

# Antigravity CLI (agy)
ai-jail agy

# Codex CLI
ai-jail codex --yolo
```

#### 🔍 O que o Agente SABE na Execução Direta:
* ✅ **Regras e Conhecimento do Projeto:** Lê as regras do repositório (`AGENTS.md` / wiki do `ai-memory`).
* ✅ **Busca no Histórico via MCP:** Consulta livremente o banco de dados da memória chamando `memory_search` ou `memory_read_page`.

#### 💡 A única diferença do Managed Workstream (`ai-memory run`):
* **Execução Direta:** Abre com o prompt limpo. O agente sabe a teoria e regras do projeto, mas **não recebe um resumo automático de boot (*Handoff*)** do tipo: *"Você parou ontem no arquivo X na linha Y"*.
* **Managed Workstream (`ai-memory run`):** Força a injeção desse resumo de transição no boot inicial e permite trocar de IA (ex: OpenCode -> Claude -> Codex) compartilhando a mesma linha de trabalho.


---

## 4. Como Verificar se o Sandbox Está Ativo

Existem 5 formas simples de confirmar se o agente está realmente rodando dentro da sandbox do **ai-jail**:

1. **Verificar o Hostname do Sistema:**
   Rodar `hostname` no terminal do agente retornará obrigatoriamente **`ai-sandbox`** (diferente do nome real da máquina).
2. **Banner no Terminal:**
   Ao iniciar, o ai-jail exibe no topo:
   ```text
   ▸ Jail Active: /caminho/do/projeto
   ▸ Landlock: fully enforced
   ```
3. **Bloqueio de Arquivos Sensíveis (Landlock / Isolamento):**
   Tentar acessar diretórios privados como `ls -la ~/.ssh` resultará em `Permission denied` ou pasta inacessível.
4. **Indicador `(jail)` no Prompt:**
   O ambiente interno define a variável `PS1` prefixada com `(jail) \w $ `.
5. **Comando de Status do ai-jail:**
   Fora do sandbox, execute `ai-jail status` para inspecionar todas as permissões ativas.

---

## 5. Como Limpar e Gerenciar a Memória (ai-memory)

Existem 3 formas de apagar ou resetar os dados da memória:

1. **Limpar APENAS o Projeto Atual (Recomendado):**
   Remove todas as páginas de wiki, sessões e histórico armazenados para o projeto/repositório atual:
   ```bash
   ai-memory purge-project --confirm
   ```
2. **Limpar TUDO (Reset Geral):**
   Apaga todo o banco de dados e arquivos de memória de **todos** os projetos salvos:
   ```bash
   ai-memory reset --confirm
   ```
3. **Apagar uma Página Específica:**
   Apaga uma nota ou página de memória por busca/palavra-chave:
   ```bash
   ai-memory delete-page --query "nome da pagina"
   ```

---

## 6. Integração Nativa MCP com Agentes (`agy` / `antigravity-cli`)

Agentes como o **`agy` (Google Antigravity CLI)** carregam o `ai-memory` nativamente através do protocolo MCP configurado em `~/.gemini/antigravity-cli/mcp_config.json`.

Ao executar:
```bash
ai-jail agy
```
O `ai-jail` isola o ambiente enquanto o `agy` conecta automaticamente ao servidor HTTP do `ai-memory` (porta `49374`), permitindo usar todas as ferramentas MCP (`memory_search`, `memory_read_page`, `memory_write_page`, etc.) de forma totalmente transparente e sem necessidade de chamar o wrapper `ai-memory run`.

---

## 7. Solução de Problemas Rápidos

* **Erro `Connection refused (os error 111)`:**
  Significa que o serviço do systemd está parado. Inicie-o com:
  `systemctl --user start ai-memory`

* **Mensagem `another launcher owns this workstream`:**
  Outro processo ou terminal ficou aguardando no prompt `Select [1]:`. Responda o prompt no terminal aberto ou force uma nova workstream com `--new <nome>`.


