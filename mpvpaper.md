# mpvpaper Setup (Wallpaper Animado)

Para configurar o vídeo `/home/fecavmi/Videos/backgrounds/13415877_3840_2160_30fps.mp4` como papel de parede em tela cheia (Wayland/wlroots), utilize o seguinte comando:

```zsh
mpvpaper eDP-1 "/home/fecavmi/Videos/backgrounds/13415877_3840_2160_30fps.mp4" -o "loop --video-unscaled=no --panscan=1.0"
```

## Opções Utilizadas:
- `eDP-1`: Identificador do monitor (use `mpvpaper -d` para listar outros).
- `-o "..."`: Repassa as opções diretamente para o `mpv`.
- `--video-unscaled=no`: Garante que o vídeo seja escalonado.
- `--panscan=1.0`: Ajusta o vídeo para preencher toda a tela, cortando bordas se necessário (equivalente ao "fill").
- `loop`: Mantém o vídeo em loop infinito.
