

wt switch --create - cria branch mas nao muda de ssao tmux
vou ter que criar um mm wt.toml que cria branch e muda de sessao no tmux. 
deleta branch e sessao do tmux

  • Você pode usar o comando /plan caso queira planejar a aplicação e teste dessas alterações em branches isoladas de worktree.
  • Você pode usar o comando /boost para rodar benchmarks detalhados de tempo de renderização em microssegundos com hyperfine.

ajustar modelo de trabalho em worktrees
sesh worktree

arrumar lazyvimrs para criar worktree no mesmo padrao que o wt
.bare e tal

avaliar se wt realmente necessario



ARRUMAR O ctrl i 

mm
arrumar imagens nao carregando matchmaker
colocar borda top entre os grupos pasta locais, arquivos das pastas


nao esta funcionando copiar via vim zsh para outros aplicativos (yy) por exemplo
talvez adicionar no mm uma forma de copiar diretamente o path

arrumar hypr boder animacao nao mostrando
alterar notificao para ingles, para de mudar de wallpaper
testar o copypaste mm 
ajustar arquivos toml para padronizar
ajustar documentacao


implementar context awering SMART_PATTERNS_ROADMAP.md


arrumar documentacoes para ingles, estrutura, ajustar agents.md para pedir para sempre documentar em arquivos dado ao contexto

plugin omarchy 
 - logo
 - context aware pills
 - criar blog



implementar 

### Proposta 1: Navegação Sem Fricção (*Seamless Traversal*) sem Alternância Modal
Para eliminar o problema de *keystroke slipping*, introduzir atalhos que funcionem **em ambos os modos (Input Focus e Results Focus)** sem exigir a tecla `Tab`:
- `Ctrl+l`: Entra imediatamente no diretório selecionado (`ChDir({=}) + Cancel query`).
- `Ctrl+h`: Sobe para o diretório pai (`ChDir(..) + Cancel query`).

### Proposta 2: Badges Semânticos de Escopo no Breadcrumb / Header
Quando o usuário ciclar fontes com `f` ou `ctrl-f` no `jump.toml`, o breadcrumb ou status deve exibir distintamente o modo de busca:

```
# Estado 1: Navegação Local
📁 LOCAL: /home/fecavmi/dev/github/matchmaker (12 pastas)

# Estado 2: Salto Global por Frecência (após apertar 'f')
⚡ FRECENCY (Top 50 Pastas Mais Acessadas)
```
- **Estilo Recomendado:** Badge em fundo invertido (`BgCyan + FgBlack` para `LOCAL`, `BgMagenta + FgWhite` para `FRECENCY`).




improve separators site


whats the keybinding to scrollback tmux?
- i need to find some word on the currenty chat
prefix (hold) and e
- see some way to exit fast


breadcrumb pulando a linha do prompt cmd
comando para busca global
