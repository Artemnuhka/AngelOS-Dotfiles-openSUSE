#!/usr/bin/env bash
set -Eeuo pipefail

# Portable installer for the PixelStreetArt Niri rice.
# Safe defaults:
#   DOTFILES_MODE=full|tech
#   NOCTALIA=auto|0|1
#   SKIP_PACKAGES=0|1
#   INSTALL_VOXTYPE=0|1
#   DOWNLOAD_VOXTYPE_MODEL=0|1
#   ENABLE_SERVICES=0|1
#   INSTALL_FLATPAK=0|1

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
HOME_DIR="${HOME:?HOME is not set}"
STAMP="$(date +%Y%m%d-%H%M%S)"
MODE="${DOTFILES_MODE:-}"
NOCTALIA="${NOCTALIA:-1}"
SKIP_PACKAGES="${SKIP_PACKAGES:-0}"
INSTALL_VOXTYPE="${INSTALL_VOXTYPE:-1}"
DOWNLOAD_VOXTYPE_MODEL="${DOWNLOAD_VOXTYPE_MODEL:-1}"
ENABLE_SERVICES="${ENABLE_SERVICES:-1}"
INSTALL_FLATPAK="${INSTALL_FLATPAK:-0}"
VOXTYPE_VERSION="${VOXTYPE_VERSION:-1.1.0}"
VOXTYPE_FORCE="${VOXTYPE_FORCE:-0}"

say() { printf '[dotfiles] %s\n' "$*"; }
warn() { printf '[dotfiles] WARNING: %s\n' "$*" >&2; }
die() { printf '[dotfiles] ERROR: %s\n' "$*" >&2; exit 1; }

if [[ -z "$MODE" && -t 0 ]]; then
  read -r -p 'Режим (1 полный стиль / 2 минимальный tech) [1]: ' answer || true
  case "${answer:-1}" in
    1|full) MODE=full ;;
    2|tech) MODE=tech ;;
    *) die "Неизвестный режим: $answer" ;;
  esac
fi
MODE="${MODE:-full}"
case "$MODE" in
  1|full) MODE=full ;;
  2|tech) MODE=tech ;;
  *) die "DOTFILES_MODE должен быть full или tech" ;;
esac

ask_yes() {
  local answer
  [[ -t 0 ]] || return 1
  read -r -p "$1 [д/Н] " answer || true
  [[ "$answer" =~ ^([дДyY]|да|Да|yes|YES)$ ]]
}

backup() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    mv -- "$target" "$target.bak.$STAMP"
    say "backup: ${target}.bak.${STAMP}"
  fi
}

copy_file() {
  local src rel dst content
  src="$1"
  rel="$2"
  dst="$HOME_DIR/$rel"
  mkdir -p -- "$(dirname -- "$dst")"
  backup "$dst"

  if [[ "$src" == *.kdl || "$src" == *.toml || "$src" == *.ini || "$src" == *.conf ||
        "$src" == *.list || "$src" == *.dirs || "$src" == *.locale || "$src" == *.service ||
        "$src" == *.jsonc || "$src" == *scripts-accels ]]; then
    content="$(<"$src")"
    content="${content//@HOME@/$HOME_DIR}"
    printf '%s\n' "$content" > "$dst"
  else
    cp -a -- "$src" "$dst"
  fi
  case "$rel" in
    .local/bin/*) chmod +x "$dst" 2>/dev/null || true ;;
  esac
}

pacman_install() {
  local list="$ROOT/packages/pacman.txt"
  command -v pacman >/dev/null 2>&1 || { warn "pacman не найден; пропускаю системные пакеты"; return 0; }
  [[ "$SKIP_PACKAGES" == 1 ]] && { say "SKIP_PACKAGES=1: пакеты пропущены"; return 0; }
  command -v sudo >/dev/null 2>&1 || die "Для установки pacman-пакетов нужен sudo"
  mapfile -t packages < <(grep -Ev '^[[:space:]]*(#|$)' "$list")
  if [[ "$NOCTALIA" == 0 ]]; then
    mapfile -t packages < <(printf '%s\n' "${packages[@]}" | grep -Ev '^noctalia$')
  fi
  ((${#packages[@]})) && sudo pacman -S --needed "${packages[@]}"
}

install_noctalia() {
  [[ "$NOCTALIA" == 0 ]] && return 0
  if command -v noctalia >/dev/null 2>&1 || command -v noctalia-shell >/dev/null 2>&1 ||
     (command -v pacman >/dev/null 2>&1 && pacman -Q cachyos-niri-noctalia >/dev/null 2>&1); then
    NOCTALIA=1
    return 0
  fi
  local install_requested=0
  if [[ "$NOCTALIA" == 1 ]]; then
    install_requested=1
  elif [[ "$NOCTALIA" == auto ]] && ask_yes 'Noctalia Shell отсутствует. Установить её?'; then
    install_requested=1
  fi
  if ((install_requested)); then
    command -v pacman >/dev/null 2>&1 || die "Noctalia требует pacman"
    command -v sudo >/dev/null 2>&1 || die "Для установки Noctalia нужен sudo"
    if ! sudo pacman -S --needed noctalia; then
      sudo pacman -S --needed cachyos-niri-noctalia
    fi
    NOCTALIA=1
  else
    NOCTALIA=0
    warn "Noctalia не установлена; будет использован tech-конфиг"
  fi
}

install_voxtype() {
  [[ "$INSTALL_VOXTYPE" == 1 ]] || { say "Voxtype binary пропущен"; return 0; }
  mkdir -p -- "$HOME_DIR/.local/bin"

  local arch variant url sha actual tmp
  arch="$(uname -m)"
  [[ "$arch" == x86_64 ]] || { warn "Автозагрузка Voxtype поддерживает только x86_64"; return 0; }
  variant=baseline
  if grep -qE '(^|[[:space:]])avx512f([[:space:]]|$)' /proc/cpuinfo 2>/dev/null; then
    variant=avx512
  elif grep -qE '(^|[[:space:]])avx2([[:space:]]|$)' /proc/cpuinfo 2>/dev/null; then
    variant=avx2
  fi

  case "$variant" in
    baseline) sha=1c9d78b4f6805e4f12ba3670949d3c22788269bdbc54215afffa42cafd0b4a7a ;;
    avx2) sha=e7d5de68cc8fc610c3c961c47f879451db9bee4a2df152e9a66f1078072e7f28 ;;
    avx512) sha=bb2da45c7676bc128da998da928cb239ab6eef9fe53c31c9b4a77e819e521715 ;;
  esac
  url="https://github.com/peteonrails/voxtype/releases/download/v${VOXTYPE_VERSION}/voxtype-${VOXTYPE_VERSION}-linux-x86_64-${variant}"
  tmp="$(mktemp)"

  if [[ -x "$HOME_DIR/.local/bin/voxtype" && "$VOXTYPE_FORCE" != 1 &&
        "$("$HOME_DIR/.local/bin/voxtype" --version 2>/dev/null || true)" == *"voxtype ${VOXTYPE_VERSION}"* ]]; then
    say "Voxtype уже установлен: $("$HOME_DIR/.local/bin/voxtype" --version 2>/dev/null || true)"
  else
    command -v curl >/dev/null 2>&1 || die "Для установки Voxtype нужен curl"
    say "Загрузка Voxtype ${VOXTYPE_VERSION} (${variant})"
    curl --fail --location --retry 3 --output "$tmp" "$url"
    actual="$(sha256sum "$tmp" | awk '{print $1}')"
    [[ "$actual" == "$sha" ]] || die "SHA256 Voxtype не совпал: ожидался $sha, получен $actual"
    install -m 0755 "$tmp" "$HOME_DIR/.local/bin/voxtype"
  fi
  rm -f -- "$tmp"
}

install_voxtype_model() {
  [[ "$DOWNLOAD_VOXTYPE_MODEL" == 1 ]] || { say "Модель Voxtype пропущена"; return 0; }
  [[ -x "$HOME_DIR/.local/bin/voxtype" ]] || { warn "Модель пропущена: Voxtype binary не установлен"; return 0; }
  if "$HOME_DIR/.local/bin/voxtype" setup --download --model large-v3-turbo --activate --no-post-install; then
    say "Модель Voxtype large-v3-turbo готова"
  else
    warn "Не удалось скачать модель Voxtype; повторите позже командой:"
    warn "voxtype setup --download --model large-v3-turbo --activate --no-post-install"
  fi
}

install_configs() {
  local src rel
  mkdir -p -- "$HOME_DIR/.config" "$HOME_DIR/.local/bin"

  while IFS= read -r -d '' src; do
    rel="${src#"$ROOT/"}"
    case "$rel" in
      .config/niri/config-no-noctalia.kdl|.config/niri/cfg/autostart-no-noctalia.kdl|.config/niri/cfg/keybinds-no-noctalia.kdl)
        continue ;;
      .config/niri/config.kdl|.config/niri/cfg/autostart.kdl|.config/niri/cfg/keybinds.kdl)
        [[ "$NOCTALIA" == 1 ]] || continue ;;
      .config/noctalia/*)
        [[ "$NOCTALIA" == 1 ]] || continue ;;
      .config/systemd/user/*)
        [[ "$ENABLE_SERVICES" == 1 ]] || continue ;;
      .local/share/*|Pictures/*)
        [[ "$MODE" == full ]] || continue ;;
    esac
    copy_file "$src" "$rel"
  done < <(find "$ROOT/.config" "$ROOT/.local/bin" -type f -print0 | sort -z)

  if [[ "$NOCTALIA" == 0 ]]; then
    copy_file "$ROOT/.config/niri/config-no-noctalia.kdl" ".config/niri/config.kdl"
    copy_file "$ROOT/.config/niri/cfg/autostart-no-noctalia.kdl" ".config/niri/cfg/autostart.kdl"
    copy_file "$ROOT/.config/niri/cfg/keybinds-no-noctalia.kdl" ".config/niri/cfg/keybinds.kdl"
    backup "$HOME_DIR/.config/niri/noctalia.kdl"
    rm -f -- "$HOME_DIR/.config/niri/noctalia.kdl"
  fi

  if [[ "$MODE" == tech ]]; then
    copy_file "$ROOT/.local/bin/niri-screenshot-region-simple" ".local/bin/niri-screenshot-region"
    copy_file "$ROOT/.local/bin/niri-record-region-simple" ".local/bin/niri-record-region"
  fi
}

install_assets() {
  [[ "$MODE" == full ]] || return 0
  if [[ -d "$ROOT/.local/share" ]]; then
    mkdir -p -- "$HOME_DIR/.local/share"
    rsync -a \
      --exclude 'voxtype/models' \
      --exclude 'nautilus/tags' \
      "$ROOT/.local/share/" "$HOME_DIR/.local/share/"
  fi
  mkdir -p -- "$HOME_DIR/Pictures"
  if [[ -d "$ROOT/Pictures" ]]; then
    rsync -a --exclude 'Screenshots' "$ROOT/Pictures/" "$HOME_DIR/Pictures/"
  fi
  if command -v fc-cache >/dev/null 2>&1; then fc-cache -f "$HOME_DIR/.local/share/fonts" >/dev/null 2>&1 || true; fi
  command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update || true
}

enable_services() {
  [[ "$ENABLE_SERVICES" == 1 ]] || return 0
  command -v systemctl >/dev/null 2>&1 || { warn "systemctl не найден; user services не включены"; return 0; }
  systemctl --user daemon-reload || true
  systemctl --user enable niri-game-mode.service || true
  if [[ -x "$HOME_DIR/.local/bin/voxtype" ]]; then
    systemctl --user enable voxtype.service voxtype-indicator.service || true
  fi
}

install_flatpak() {
  [[ "$INSTALL_FLATPAK" == 1 ]] || return 0
  command -v flatpak >/dev/null 2>&1 || { warn "flatpak не найден"; return 0; }
  [[ -f "$ROOT/packages/flatpak-apps.txt" ]] || return 0
  mapfile -t apps < <(grep -Ev '^[[:space:]]*(#|$)' "$ROOT/packages/flatpak-apps.txt")
  ((${#apps[@]})) && flatpak install -y flathub "${apps[@]}"
}

pacman_install
install_noctalia
install_voxtype
install_voxtype_model
install_configs
install_assets
install_flatpak
enable_services

if command -v niri >/dev/null 2>&1; then
  if niri validate -c "$HOME_DIR/.config/niri/config.kdl" >/dev/null 2>&1; then
    say "Niri config valid"
  else
    warn "Niri config не прошёл validate; проверьте вывод: niri validate -c ~/.config/niri/config.kdl"
  fi
fi

say "Готово: mode=${MODE}, noctalia=${NOCTALIA}, home=${HOME_DIR}"
