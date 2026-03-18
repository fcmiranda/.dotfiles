# Configuração NVIDIA GT 750M (Kepler) — Dell Inspiron 14R

## Diagnóstico

| Item                | Valor                                          |
| ------------------- | ---------------------------------------------- |
| **Máquina**         | Dell Inspiron 14R                              |
| **GPU**             | NVIDIA GK107M [GeForce GT 750M] (Kepler)      |
| **GPU integrada**   | Intel Haswell-ULT (i915)                       |
| **Kernel**          | 6.19.6-arch1-1                                 |
| **Modo EnvyControl**| hybrid                                         |

### Problema encontrado

O pacote `nvidia-open-dkms` (driver open kernel modules) **não suporta GPUs Kepler** — ele só funciona com Turing (RTX 2000) e mais recentes. Por isso o `nvidia-smi` falhava e nenhum módulo nvidia era carregado.

**Solução:** Instalar o driver legacy **nvidia-470xx** do AUR.

---

## Passo 1 — Remover pacotes incompatíveis

```bash
sudo pacman -Rns nvidia-open-dkms nvidia-utils lib32-nvidia-utils libva-nvidia-driver --noconfirm
```

Pacotes residuais que também precisaram ser removidos:

```bash
sudo pacman -Rns nvidia-utils egl-gbm egl-wayland2 egl-x11 --noconfirm
```

> Se aparecer erro de lock do pacman:
> ```bash
> sudo rm /var/lib/pacman/db.lck
> ```

---

## Passo 2 — Instalar driver legacy NVIDIA 470xx (AUR)

```bash
yay -S nvidia-470xx-dkms nvidia-470xx-utils lib32-nvidia-470xx-utils --noconfirm
```

Pacotes instalados:
- `nvidia-470xx-dkms 470.256.02-8.01`
- `nvidia-470xx-utils 470.256.02-8.01`
- `lib32-nvidia-470xx-utils 470.256.02-1`

---

## Passo 3 — Blacklist do driver Nouveau

Criar arquivo para impedir o driver open-source nouveau de carregar (conflita com o proprietário):

```bash
sudo tee /etc/modprobe.d/blacklist-nouveau.conf <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
```

---

## Passo 4 — Configurar nvidia_drm modeset

```bash
sudo tee /etc/modprobe.d/nvidia.conf <<'EOF'
options nvidia_drm modeset=1
EOF
```

---

## Passo 5 — Regenerar initramfs

```bash
sudo mkinitcpio -P
```

> No caso do Limine (bootloader), o comando redireciona automaticamente para `limine-mkinitcpio`.

---

## Passo 6 — Verificar DKMS

```bash
sudo dkms status
```

Resultado esperado:
```
nvidia/470.256.02, 6.19.6-arch1-1, x86_64: installed
```

---

## Passo 7 — Reiniciar

```bash
sudo reboot
```

---

## Testes de validação (após reboot)

### 1. Verificar se o módulo nvidia está carregado

```bash
lsmod | grep nvidia
```

Esperado: `nvidia`, `nvidia_modeset`, `nvidia_drm`

### 2. Verificar se a GPU é reconhecida pelo driver

```bash
nvidia-smi
```

Esperado: Tabela mostrando GT 750M com temperatura e uso de memória.

### 3. Verificar renderizador OpenGL

```bash
# Instalar mesa-utils se necessário
sudo pacman -S mesa-utils

glxinfo | grep "OpenGL renderer"
```

Esperado: `OpenGL renderer string: GeForce GT 750M/PCIe/SSE2`

### 4. Teste de renderização 3D

```bash
glxgears -info
```

Esperado: ~60 FPS (limitado por vsync), sem travamentos.

---

## Gerenciamento Intel vs NVIDIA (EnvyControl)

```bash
# Instalar
yay -S envycontrol

# Modo NVIDIA (performance)
sudo envycontrol -s nvidia

# Modo Intel (economia de bateria)
sudo envycontrol -s integrated

# Modo híbrido
sudo envycontrol -s hybrid

# Consultar modo atual
envycontrol -q
```

> Reinicie após trocar de modo.

---

## Referência rápida de arquivos modificados

| Arquivo                                    | Conteúdo                              |
| ------------------------------------------ | ------------------------------------- |
| `/etc/modprobe.d/blacklist-nouveau.conf`   | Blacklist nouveau + modeset=0         |
| `/etc/modprobe.d/nvidia.conf`              | `options nvidia_drm modeset=1`        |

---

*Configuração realizada em 10/03/2026 — Arch Linux, kernel 6.19.6-arch1-1*
