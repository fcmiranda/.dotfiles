# Correção de Crash do Hyprland (Tela Preta / Loop de Importação)

Este documento explica o motivo dos crashes repentinos do Hyprland (que resultavam em tela preta no login) e como prevenir/resolver o problema caso ele volte a ocorrer após alguma atualização ou reset de dotfiles.

---

## 1. O Problema
O arquivo de modelo (template) do tema do Hyprland:
`~/.dotfiles/main/hypr/.config/omarchy/themed-overrides/hyprland.conf.tpl`

Possuía a seguinte linha ativada no topo (linha 1):
```ini
source = ~/.config/omarchy/current/theme/hyprland.omarchy.conf
```

### O que acontecia na prática:
1. Quando você aplicava ou atualizava um tema, o gerenciador do Omarchy lia esse arquivo `.tpl` para gerar o arquivo final compilado:
   `~/.config/omarchy/current/theme/hyprland.omarchy.conf`
2. Como o template continha a instrução de importar o próprio arquivo compilado, o arquivo gerado acabava **importando a si mesmo**.
3. Ao iniciar o Hyprland, ele lia essa linha de `source`, tentava importar o arquivo, que por sua vez tentava importar ele mesmo, gerando uma **recursão infinita**.
4. Isso estourava a memória da pilha (Stack Overflow), resultando em um **Segmentation Fault (Segfault / Core Dump)**.
5. Como o Hyprland crashava instantaneamente, o sistema ficava preso em uma tela preta e o serviço de login automático (`omarchy-seamless-login.service`) falhava por estourar o limite de tentativas de reinício (`start-limit-hit`).

---

## 2. A Solução
A solução definitiva consiste em garantir que a linha de `source` esteja comentada tanto no **template** quanto no **arquivo gerado**:

### No arquivo de template (Corrigido):
`~/.dotfiles/main/hypr/.config/omarchy/themed-overrides/hyprland.conf.tpl`
```ini
# source = ~/.config/omarchy/current/theme/hyprland.omarchy.conf
```

### No arquivo final gerado (Corrigido):
`~/.config/omarchy/current/theme/hyprland.omarchy.conf`
```ini
# source = ~/.config/omarchy/current/theme/hyprland.omarchy.conf
```

---

## 3. Como evitar que o problema volte
Como você gerencia seus dotfiles via Git (worktree em `~/.dotfiles/main`), se você não salvar essa correção no seu histórico do Git, qualquer comando como `git checkout`, `git reset` ou `git pull` vai descartar a correção e trazer o erro de volta.

Para salvar permanentemente, execute os seguintes comandos no terminal:

```bash
# 1. Navegue até a pasta do repositório
cd ~/.dotfiles/main

# 2. Adicione a correção do template
git add hypr/.config/omarchy/themed-overrides/hyprland.conf.tpl

# 3. Commit as alterações
git commit -m "fix: remove circular source from hyprland theme template to prevent crashes"

# 4. (Opcional) Envie para o seu repositório remoto
git push
```

Se o ambiente travar de novo antes de você conseguir comitar, você pode restaurar o serviço rodando:
```bash
bash ~/restart-hyprland.sh
```
