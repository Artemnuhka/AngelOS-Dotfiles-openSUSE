#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
STAMP="$(date +%Y%m%d-%H%M%S)"
MODE="${DOTFILES_MODE:-}"
[[ -n "$MODE" ]] || { read -r -p 'Режим (1 полный стиль / 2 технологии): ' MODE; }
[[ "$MODE" == 1 || "$MODE" == full ]] && MODE=full || MODE=tech

ask_yes() { local a; read -r -p "$1 [д/Н] " a; [[ "$a" =~ ^([дДyY]|да|Да|yes)$ ]]; }
backup() { [[ -e "$1" && ! -L "$1" ]] && mv -- "$1" "$1.bak.$STAMP" || true; }

if ! command -v niri >/dev/null 2>&1; then
  command -v pacman >/dev/null && sudo pacman -S --needed niri
fi
if [[ "$MODE" == tech ]]; then
  CONFIG_MODE=tech
else
  CONFIG_MODE=full
fi
NOCTALIA=0
if command -v noctalia-shell >/dev/null 2>&1 || pacman -Q cachyos-niri-noctalia >/dev/null 2>&1; then NOCTALIA=1; elif ask_yes 'У вас Noctalia Shell отсутствует. Установить её?'; then sudo pacman -S --needed cachyos-niri-noctalia; NOCTALIA=1; fi

if command -v pacman >/dev/null 2>&1 && [[ "${SKIP_PACKAGES:-0}" != 1 ]]; then
  mapfile -t pkgs < <(grep -Ev '^(#|$)' "$ROOT/packages/pacman-explicit.txt" | grep -Ev '^(linux|cachyos-kernel|amd-ucode|nvidia|lib32-nvidia|opencl-nvidia|mesa|cachyos-|grok-bot-bin|lrc_tty|millennium|nexusmods-app-bin|openai-codex-bin|throne-bin)$' || true)
  ((${#pkgs[@]})) && sudo pacman -S --needed "${pkgs[@]}"
  if ask_yes 'Установить найденные AUR-пакеты?'; then command -v yay >/dev/null && yay -S --needed - < "$ROOT/packages/aur-packages.txt" || echo 'Установите yay/paru и повторите AUR отдельно.'; fi
fi

while IFS= read -r -d '' src; do
  rel="${src#"$ROOT/"}"; [[ "$CONFIG_MODE" == tech && "$rel" == .config/niri/noctalia.kdl ]] && continue
  dst="$HOME_DIR/${rel#./}"; mkdir -p "$(dirname -- "$dst")"; backup "$dst"
  if [[ -f "$src" ]]; then
    content=$(<"$src")
    if [[ "$CONFIG_MODE" == tech && "$rel" == .config/niri/cfg/keybinds.kdl ]]; then content="${content//@HOME@\/.local\/bin\/niri-screenshot-region/@HOME@/.local/bin/niri-screenshot-tech}"; content="${content//@HOME@\/.local\/bin\/niri-record-region/@HOME@/.local/bin/niri-record-tech}"; fi
    if [[ "$NOCTALIA" != 1 ]]; then content="${content//@HOME@\/\.local\/bin\/voxtype-indicator/true}"; fi
    printf '%s\n' "${content//@HOME@/$HOME_DIR}" > "$dst"
  else cp -a "$src" "$dst"; fi
  chmod +x "$dst" 2>/dev/null || true
done < <(find "$ROOT/.config" "$ROOT/.local/bin" -type f -print0)

mkdir -p "$HOME_DIR/Pictures/Screenshots" "$HOME_DIR/Videos"
[[ "$MODE" == full ]] && cp -an "$ROOT/Pictures/wallpapers/." "$HOME_DIR/Pictures/" 2>/dev/null || true
if command -v flatpak >/dev/null 2>&1 && [[ "${SKIP_FLATPAK:-0}" != 1 ]] && ask_yes 'Установить Flatpak-приложения из списка?'; then flatpak install -y flathub $(grep -Ev '^(#|$)' "$ROOT/packages/flatpak-apps.txt"); fi
printf '[dotfiles] Готово: режим %s, Noctalia=%s\n' "$MODE" "$NOCTALIA"
