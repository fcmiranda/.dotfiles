# O Mistério do Highlight nas Abas do Tmux (Window Activity)

Você notou que ao fazer uma pergunta para a IA usando o `agy` (Antigravity) enquanto estava em outra aba, a aba original do `agy` ficava em destaque (highlight, invertendo a cor do fundo), mas o mesmo não acontecia ao usar o `oc` (OpenCode).

## Por que isso acontece?

Isso não é um bug, nem foi causado pelo nosso daemon `acpd`. É uma mecânica de design clássica (e muito útil) chamada **Tmux Window Activity Monitoring**.

### O caso do Antigravity (`agy`)
O Antigravity funciona como uma ferramenta de terminal pura (CLI). Enquanto ele processa sua resposta ou imprime uma pergunta (ex: `"O que deseja fazer?"`), ele envia **texto comum** (Standard Output) para a tela do terminal. 

Quando o Tmux percebe que uma aba que está escondida/em segundo plano (background) acaba de receber novos caracteres de texto na tela, ele pensa: *"Opa, o terminal lá atrás atualizou, o usuário precisa saber!"*. Então ele inverte a cor daquela aba na barra de status para te chamar atenção.

### O caso do OpenCode (`oc`)
O OpenCode usa uma interface avançada de TUI (Text User Interface) — parecido com o funcionamento do `htop`, `lazygit` ou `neovim`. Em vez de apenas "cuspir" linhas de texto, essas aplicações controlam ativamente onde desenham na tela e, na maioria das vezes, param de enviar atualizações cruas quando ficam em modo de espera aguardando seu input (ou usam buffers alternativos de tela). Como nenhum "novo texto contínuo" é impresso na tela crua, o Tmux não aciona o gatilho de atividade.

## Como configurar (Ligar/Desligar)

Se você gosta desse aviso visual, você pode garantir que ele fique ligado sempre. Se você acha irritante a aba piscar enquanto a IA está rodando comandos em segundo plano, você pode desligar.

Essa configuração fica no seu arquivo `~/.config/tmux/tmux.conf` (já deixei preparado lá!):

```tmux
# Window Activity Monitoring
setw -g monitor-activity on
set -g visual-activity off
```

- `setw -g monitor-activity on` -> Liga o highlight (Destaque visual na aba quando o `agy` responde ou interage).
- `setw -g monitor-activity off` -> Desliga completamente. A aba não mudará de cor mesmo que o `agy` termine a tarefa.
- `set -g visual-activity off` -> Evita que o Tmux mostre aquela mensagem irritante em texto embaixo ("Activity in window 0"), fazendo o aviso ser puramente o highlight na aba (modo silencioso).

> **Para recarregar a configuração:**
> Basta dar `Ctrl+Space` e depois `r` no Tmux para rodar o `tmux source-file`!
