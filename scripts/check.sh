#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
failures=0

pass() { printf '[check] OK   %s\n' "$*"; }
fail() { printf '[check] FAIL %s\n' "$*" >&2; failures=$((failures + 1)); }

check_command() {
  command -v "$1" >/dev/null 2>&1 || { fail "missing command: $1"; return 1; }
}

check_file() {
  [[ -f "$ROOT/$1" ]] && pass "file: $1" || fail "missing file: $1"
}

check_command bash
check_command rg

if bash -n "$ROOT/install.sh"; then
  pass "shell syntax: install.sh"
else
  fail "shell syntax: install.sh"
fi

while IFS= read -r -d '' file; do
  if bash -n "$file"; then
    pass "shell syntax: ${file#"$ROOT/"}"
  else
    fail "shell syntax: ${file#"$ROOT/"}"
  fi
done < <(find "$ROOT" -type f -name '*.sh' -print0 -not -path "$ROOT/.git/*")

if python - "$ROOT" <<'PY'
import ast
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for path in root.glob(".local/bin/*"):
    if path.is_file() and path.read_text(errors="ignore").startswith("#!/usr/bin/env python"):
        ast.parse(path.read_text(), filename=str(path))
PY
then
  pass "Python syntax"
else
  fail "Python syntax"
fi

for file in \
  .config/niri/config.kdl \
  .config/niri/config-no-noctalia.kdl \
  .config/niri/noctalia.kdl \
  .config/voxtype/config.toml \
  .config/gtk-3.0/bookmarks \
  .config/gtk-4.0/bookmarks \
  .config/kitty/themes/noctalia.conf \
  .config/alacritty/themes/noctalia.toml \
  .config/foot/themes/noctalia \
  .local/bin/niri-screenshot-region \
  .local/bin/niri-record-region \
  .local/bin/niri-ocr \
  .local/bin/voxtype-indicator \
  .config/systemd/user/niri-game-mode.service \
  .config/systemd/user/voxtype.service \
  .config/systemd/user/voxtype-indicator.service; do
  check_file "$file"
done

if command -v niri >/dev/null 2>&1; then
  if niri validate -c "$ROOT/.config/niri/config.kdl" >/dev/null 2>&1 &&
     niri validate -c "$ROOT/.config/niri/config-no-noctalia.kdl" >/dev/null 2>&1; then
    pass "Niri KDL validation"
  else
    fail "Niri KDL validation"
  fi
else
  printf '[check] SKIP niri KDL validation (niri is not installed)\n'
fi

if rg -n --hidden \
  -g '!*.png' -g '!*.jpg' -g '!*.jpeg' -g '!*.webp' \
  -g '!*.ttf' -g '!*.otb' -g '!*.svg' -g '!*.cache' \
  -g '!.git/**' \
  -g '!scripts/check.sh' -g '!README.md' -g '!.gitignore' -g '!install.sh' \
  '/home/mixad|/home/[A-Za-z0-9_.-]+/\.config/gh/hosts\.yml|Cookies|Login Data|Bitwarden/data\.json|keyrings|voxtype/models' \
  "$ROOT" >/tmp/pixelstreetart-dotfiles-sensitive-matches 2>/dev/null; then
  cat /tmp/pixelstreetart-dotfiles-sensitive-matches >&2
  fail "personal path or secret-like data detected"
else
  pass "no personal paths or secret-like data"
fi
rm -f /tmp/pixelstreetart-dotfiles-sensitive-matches

if rg -n --hidden -g '!*.[pjw][np][ge]' -g '!*.svg' -g '!*.ttf' -g '!*.otb' -g '!.git/**' \
  -g '!scripts/check.sh' -g '!README.md' -g '!.gitignore' -g '!install.sh' \
  'DP-1|HDMI-A-1|WAYLAND_DISPLAY=wayland-[0-9]+|avatar_path' "$ROOT" >/tmp/pixelstreetart-dotfiles-machine-matches 2>/dev/null; then
  cat /tmp/pixelstreetart-dotfiles-machine-matches >&2
  fail "machine-specific monitor/runtime state detected"
else
  pass "no machine-specific monitor/runtime state"
fi
rm -f /tmp/pixelstreetart-dotfiles-machine-matches

if rg -n '^(bitwarden|discord|firefox|helium-browser-bin|telegram-desktop|steam|spotify-launcher|throne-bin|openai-codex-bin)$' \
  "$ROOT/packages/pacman.txt" "$ROOT/packages/aur.txt" >/tmp/pixelstreetart-dotfiles-extra-packages 2>/dev/null; then
  cat /tmp/pixelstreetart-dotfiles-extra-packages >&2
  fail "non-rice applications found in the default package manifests"
else
  pass "default package manifests stay rice-focused"
fi
rm -f /tmp/pixelstreetart-dotfiles-extra-packages

if ((failures)); then
  printf '[check] %d check(s) failed\n' "$failures" >&2
  exit 1
fi
printf '[check] all checks passed\n'
