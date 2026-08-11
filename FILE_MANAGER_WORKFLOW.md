# Workflow otimizado de file manager

## Objetivo

O problema principal não é apenas navegar melhor. É escolher rapidamente três coisas:

1. a origem;
2. os itens;
3. o destino.

O fluxo ideal deve permitir escolher o destino sem abandonar o contexto da origem.

## Fluxo recomendado

```text
selecionar arquivos
    ↓
yank/copy
    ↓
Paste To
    ↓
buscar diretório por nome, caminho ou frecency
    ↓
Enter
    ↓
copiar arquivos
    ↓
opcionalmente entrar no destino
```

No cenário `~/dev/github/vimiuum` → `~/dev/github/lazygitrs`:

```text
~/dev/github/vimiuum
  → selecionar arquivos
  → y
  → Paste To
  → digitar lazygitrs
  → Enter
  → confirmar cópia para ~/dev/github/lazygitrs
```

Isso elimina a necessidade de subir até `github` e entrar manualmente no repositório destino.

## MVP: ação `PasteTo`

A primeira implementação poderia adicionar uma única ação: `PasteTo`.

Comportamento:

- sem clipboard interno, mostrar uma mensagem de erro;
- abrir uma seleção contendo apenas diretórios;
- começar mostrando diretórios próximos ou frequentemente usados;
- permitir filtro fuzzy;
- `Enter` copiar os itens para o diretório selecionado;
- `Esc` cancelar;
- depois da cópia, oferecer a opção de entrar no destino.

Mensagem sugerida:

```text
Copied 4 items to ~/dev/github/lazygitrs
[Enter] go there   [Esc] stay here
```

Bindings possíveis:

```text
y       → copiar/yank
m       → cortar
p       → colar no diretório atual
P       → Paste To...
M-p     → Paste To... usando o último destino
```

O `p` deve continuar simples e previsível. O `P` seria o fluxo inteligente.

## Como pesquisar o destino

O seletor de destino poderia combinar três fontes.

### Diretórios recentes

Registrar diretórios visitados recentemente pelo Matchmaker.

### Frecency

Usar a base de frecency existente para priorizar diretórios acessados com frequência.

Exemplo:

```text
~/dev/github/lazygitrs       score: 98   accessed 2 min ago
~/dev/github/matchmaker      score: 91   accessed 5 min ago
~/dev/github                 score: 75
```

### Busca global limitada

Em vez de pesquisar todo o filesystem, usar raízes configuráveis:

```toml
[jump]
roots = [
  "~/dev",
  "~/projects",
  "~/work"
]
```

Ao digitar `lazygitrs`, a busca poderia encontrar:

```text
~/dev/github/lazygitrs
~/projects/lazygitrs
~/work/lazygitrs
```

A lista de diretórios deveria ser indexada ou atualizada em background, evitando uma busca lenta no momento do paste.

## Modo temporário de destino

Inicialmente não é necessário criar uma segunda janela ou um segundo painel. Pode ser criado um modo temporário:

```text
┌ Paste 4 items to ─────────────────────┐
│ lazygitrs                             │
├───────────────────────────────────────┤
│ ~/dev/github/lazygitrs                │
│ ~/dev/github/matchmaker               │
│ ~/dev/github                          │
└───────────────────────────────────────┘
```

Esse modo deve aceitar:

- somente diretórios;
- filtro fuzzy;
- caminho absoluto ou relativo digitado manualmente;
- preview da árvore do destino;
- informações de tamanho e número de arquivos;
- status Git;
- indicação de conflitos existentes.

## Confirmações

A confirmação deve aparecer apenas quando houver risco:

- arquivos já existentes;
- cópia recursiva de pasta;
- destino dentro da própria origem;
- movimentação em vez de cópia;
- operação muito grande.

Para uma cópia normal, `Enter` pode executar diretamente.

Em caso de conflito:

```text
3 files already exist in destination
[o] overwrite  [s] skip  [r] rename  [c] cancel
```

## Operações úteis

Uma evolução natural dos bindings seria:

```text
y       copy
m       move
p       paste here
P       paste to...
R       rename before paste
D       duplicate with suffix
```

Também seriam úteis:

- copiar arquivos selecionados;
- mover arquivos selecionados;
- copiar uma pasta inteira;
- colar em múltiplos destinos;
- repetir no último destino;
- desfazer a operação;
- mostrar progresso para cópias grandes.

O último destino é especialmente importante:

```text
y → P → lazygitrs → Enter
y → M-p
```

O segundo comando reutiliza `~/dev/github/lazygitrs` sem abrir novamente o seletor.

## Aliases de diretórios

Além do frecency, pode haver aliases configuráveis:

```toml
[jump.aliases]
mm = "~/dev/github/matchmaker"
lg = "~/dev/github/lazygitrs"
dot = "~/.config"
```

Uso:

```text
Paste To → lg
```

Ou atalhos:

```text
g m → ~/dev/github/matchmaker
g l → ~/dev/github/lazygitrs
g c → ~/dev/github
```

Isso provavelmente oferece mais produtividade do que uma busca global muito sofisticada.

## Integração com Git

Como o caso principal envolve repositórios, os destinos poderiam mostrar:

```text
lazygitrs  [git: clean]     ~/dev/github/lazygitrs
matchmaker [git: 2 modified] ~/dev/github/matchmaker
```

Também poderiam existir destinos semânticos:

```text
Paste to git root
Paste to current repository
Paste to repository sibling
Paste to ~/dev/github
```

Atalhos possíveis:

```text
g r → raiz do repositório atual
g s → repositórios irmãos
```

## Ferramentas existentes

### `lf`

Tem o modelo clássico de clipboard: `y` copia, `d` corta e `p` cola no diretório atual. É simples e previsível, mas normalmente exige navegar manualmente até o destino.

### `broot`

É provavelmente a ferramenta mais próxima da ideia de busca de destino. Combina filtro fuzzy com comandos configuráveis, chamados de “verbs”, permitindo operações de foco, cópia e movimentação.

### `Yazi`

Possui yank/paste, keymaps configuráveis, integração com comandos externos e atalhos de jump. É uma boa referência para uma experiência de file manager mais tradicional.

### Linha de comando

Para operações repetitivas, a linha de comando ainda é melhor:

```bash
cp -a -- file1 file2 pasta ~/dev/github/lazygitrs/
```

Para diretórios grandes ou cópias com progresso:

```bash
rsync -a --info=progress2 -- pasta/ ~/dev/github/lazygitrs/pasta/
```

A vantagem é que o comando é reproduzível e pode ser colocado em script. A desvantagem é selecionar arquivos e destinos de forma confortável.

Uma boa integração seria o Matchmaker mostrar ou copiar o comando equivalente:

```text
Copied 4 items to ~/dev/github/lazygitrs

Command:
cp -a -- file1 file2 ~/dev/github/lazygitrs/
```

## Fluxo recomendado para múltiplas origens

Quando o usuário já está na primeira pasta de origem, o fluxo origem-first é mais natural e rápido:

```text
Tab
→ iniciar na origem atual

Ctrl-F
→ selecionar arquivos
→ Enter adiciona à fila

A
→ adicionar arquivos de outra origem

Space
→ revisar a fila

Ctrl-F
→ escolher o destino

Enter
→ revisar conflitos
→ Enter executa a cópia
```

O destino-first continua útil como uma alternativa, especialmente quando o destino é conhecido e existem muitas origens:

```text
Ctrl-Shift-T
→ fixar o destino atual
→ adicionar arquivos de qualquer lugar
→ revisar e executar
```

Assim, a primeira tecla pode representar a intenção do usuário:

- `Tab`: iniciar pela origem atual;
- `Ctrl-Shift-T`: iniciar pelo destino atual.

## Ação para adicionar outra origem

Depois que os primeiros arquivos forem adicionados à fila, a ação `A` deve abrir uma nova busca sem apagar o estado da transferência.

Há duas variantes úteis.

### `A`: buscar arquivos globalmente

O picker pesquisa arquivos em raízes configuradas, como `~/dev`, `~/projects` e `~/work`:

```text
A
→ buscar arquivos em várias raízes

digitar: matchmaker toml
Space
→ selecionar config.toml

digitar: vimiuum main
Space
→ selecionar main.rs

Enter
→ retornar à fila
```

A fila poderia mostrar:

```text
Transfer queue:
✓ ~/dev/github/vimiuum/src/main.rs
✓ ~/dev/github/vimiuum/assets/logo.png
✓ ~/dev/github/matchmaker/config.toml
```

Esse é o caminho mais rápido quando o usuário conhece o nome aproximado dos arquivos.

### `Ctrl-A`: buscar uma pasta de origem

Quando o usuário quer explorar uma pasta inteira, `Ctrl-A` pode abrir um picker somente de diretórios:

```text
Ctrl-A
→ buscar vimiuum
→ Enter entra na pasta
→ Ctrl-F seleciona arquivos
→ Enter adiciona à fila
```

Isso substitui o ciclo manual:

```text
Tab
→ voltar para a pasta parente
→ procurar outra pasta
→ entrar nela
```

As duas ações cobrem estilos diferentes:

```text
arquivo conhecido       → A, busca global direta
projeto/pasta conhecida  → Ctrl-A, entra na origem e explora
```

## Estados da sessão de transferência

A operação pode ser modelada com quatro estados explícitos:

```text
SOURCE   → selecionar arquivos
QUEUE    → revisar itens selecionados
TARGET   → escolher destino
EXECUTE  → confirmar e copiar
```

Transições sugeridas:

```text
SOURCE  --Enter-->  SOURCE
SOURCE  --A------>  SOURCE, adicionando arquivos de outra origem
SOURCE  --Space-->  QUEUE
QUEUE   --Ctrl-F->  TARGET
TARGET  --Enter-->  EXECUTE
EXECUTE --Enter-->  copiar
```

O cabeçalho deve indicar claramente o estado atual:

```text
ADD SOURCES | 6 items selected
REVIEW TRANSFER | 6 items
PASTE TO | ~/dev/github/lazygitrs
```

## Ordem recomendada de implementação

1. `PasteTo` com seletor apenas de diretórios.
2. Frecency e diretórios visitados recentemente.
3. Reutilização do último destino.
4. Confirmação inteligente para conflitos.
5. Aliases de diretórios.
6. Preview do destino e status Git.
7. Indexação de diretórios em background.
8. Progresso e cancelamento de cópia.

A primeira versão já resolveria a maior parte do cenário descrito sem exigir um segundo painel, uma árvore global complexa ou uma grande reformulação do event loop.
