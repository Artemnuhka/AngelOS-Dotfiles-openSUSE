#!/usr/bin/env bash
# Repository bug-check. Safe to run anywhere: the installer test uses a
# throw-away $HOME and never touches your real configuration.
#
#   ./scripts/check.sh            everything
#   SKIP_INSTALL_TEST=1 ./scripts/check.sh   static checks only
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
failures=0
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT

pass() { printf '[check] OK   %s\n' "$*"; }
fail() { printf '[check] FAIL %s\n' "$*" >&2; failures=$((failures + 1)); }
skip() { printf '[check] SKIP %s\n' "$*"; }

check_file() {
  [[ -f "$ROOT/$1" ]] && pass "file: $1" || fail "missing file: $1"
}

# search REGEX [extra rg args…]: print matches in the repo, succeed when there are some.
search() {
  local regex="$1"; shift
  if command -v rg >/dev/null 2>&1; then
    rg -n --hidden -g '!.git/**' -g '!*.png' -g '!*.jpg' -g '!*.jpeg' -g '!*.webp' -g '!*.gif' \
       -g '!*.ttf' -g '!*.otb' -g '!*.svg' -g '!*.cache' "$@" -- "$regex" "$ROOT"
  else
    grep -rInE --exclude-dir=.git --exclude='*.png' --exclude='*.jpg' --exclude='*.gif' \
         --exclude='*.ttf' --exclude='*.otb' -- "$regex" "$ROOT"
  fi
}

# ── Syntax ───────────────────────────────────────────────────────────────────

while IFS= read -r -d '' file; do
  rel="${file#"$ROOT/"}"
  if bash -n "$file"; then pass "shell syntax: $rel"; else fail "shell syntax: $rel"; fi
done < <(find "$ROOT" -type f \( -name '*.sh' -o -path "$ROOT/.local/bin/*" -o -name .install \) \
           -not -path "$ROOT/.git/*" -print0 | while IFS= read -r -d '' f; do
             head -n1 "$f" | grep -qE '^#!.*(bash|sh)$' && printf '%s\0' "$f"; done)

if python3 - "$ROOT" <<'PY'
import ast, pathlib, sys
root = pathlib.Path(sys.argv[1])
for path in root.glob(".local/bin/*"):
    if path.is_file():
        text = path.read_text(errors="ignore")
        if text.startswith("#!") and "python" in text.splitlines()[0]:
            ast.parse(text, filename=str(path))
PY
then pass "Python syntax"; else fail "Python syntax"; fi

if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning "$ROOT/install.sh" "$ROOT/scripts/check.sh"; then
    pass "shellcheck"
  else
    fail "shellcheck"
  fi
else
  skip "shellcheck (not installed)"
fi

# ── Required files ───────────────────────────────────────────────────────────

for file in \
  install.sh .install \
  .config/niri/config.kdl .config/niri/config-no-noctalia.kdl .config/niri/noctalia.kdl \
  .config/niri/monitor.kdl .config/niri/cfg/input.kdl .config/niri/cfg/rules.kdl \
  .config/voxtype/config.toml \
  .config/gtk-3.0/bookmarks .config/gtk-4.0/bookmarks \
  .config/kitty/themes/noctalia.conf .config/alacritty/themes/noctalia.toml \
  .config/foot/themes/noctalia \
  .local/bin/niri-screenshot-region .local/bin/niri-record-region \
  .local/bin/niri-screenshot-region-simple .local/bin/niri-record-region-simple \
  .local/bin/niri-record-overlay .local/bin/niri-record-overlay-simple \
  .local/bin/niri-ocr .local/bin/voxtype-indicator \
  .config/systemd/user/niri-game-mode.service .config/systemd/user/voxtype.service \
  .config/systemd/user/voxtype-indicator.service; do
  check_file "$file"
done

# ── Niri config ──────────────────────────────────────────────────────────────

if command -v niri >/dev/null 2>&1; then
  if niri validate -c "$ROOT/.config/niri/config.kdl" >/dev/null 2>&1 &&
     niri validate -c "$ROOT/.config/niri/config-no-noctalia.kdl" >/dev/null 2>&1; then
    pass "Niri KDL validation (both variants)"
  else
    fail "Niri KDL validation"
  fi
else
  skip "Niri KDL validation (niri is not installed)"
fi

# The mouse must stay at libinput defaults: forcing a flat/slow profile is what
# made the pointer feel sluggish for other people.
if grep -Eq '^[[:space:]]*(accel-speed|accel-profile)' "$ROOT/.config/niri/cfg/input.kdl"; then
  fail "input.kdl sets a mouse acceleration profile/speed"
else
  pass "input.kdl leaves pointer speed at libinput defaults"
fi

# ── Installer, end to end ────────────────────────────────────────────────────

# install_case NAME [VAR=value…] runs the installer in a fresh fake $HOME.
install_case() {
  local name="$1"; shift
  local home="$WORK/$name"
  mkdir -p "$home"
  env -i HOME="$home" PATH="$PATH" LANG=C \
      SKIP_PACKAGES=1 INSTALL_VOXTYPE=0 DOWNLOAD_VOXTYPE_MODEL=0 \
      ENABLE_SERVICES=0 INSTALL_WALLPAPERS=0 "$@" \
      "$ROOT/install.sh" >"$WORK/$name.log" 2>&1 </dev/null
}

expect_line() { # NAME FILE REGEX DESCRIPTION
  if grep -Eq "$3" "$WORK/$1/$2"; then pass "$4"; else fail "$4"; fi
}

if [[ "${SKIP_INSTALL_TEST:-0}" == 1 ]]; then
  skip "installer tests (SKIP_INSTALL_TEST=1)"
else
  input=".config/niri/cfg/input.kdl"

  if install_case default; then
    pass "installer: default run"
    expect_line default "$input" '^[[:space:]]*layout "us,ru"$'                  "installer: default layouts us,ru"
    expect_line default "$input" '^[[:space:]]*options "grp:alt_shift_toggle"$'  "installer: default switch Alt+Shift"
    if grep -rq '@[A-Z_]*@' "$WORK/default/.config" "$WORK/default/.local/bin" 2>/dev/null; then
      fail "installer: unresolved @PLACEHOLDER@ left in installed files"
    else
      pass "installer: every placeholder resolved"
    fi
    if command -v niri >/dev/null 2>&1; then
      niri validate -c "$WORK/default/.config/niri/config.kdl" >/dev/null 2>&1 &&
        pass "installer: installed config validates" || fail "installer: installed config validates"
    fi
    # Second run must change nothing except what the user owns.
    if install_case default && grep -q 'Files: 0 installed' "$WORK/default.log"; then
      pass "installer: re-run is idempotent"
    else
      fail "installer: re-run is idempotent"
    fi
    echo 'output "X" { scale 2 }' >"$WORK/default/.config/niri/monitor.kdl"
    install_case default
    if grep -q 'scale 2' "$WORK/default/.config/niri/monitor.kdl"; then
      pass "installer: existing monitor.kdl is preserved"
    else
      fail "installer: existing monitor.kdl is preserved"
    fi
  else
    fail "installer: default run"; sed 's/^/    /' "$WORK/default.log" >&2
  fi

  if install_case layouts KB_LAYOUTS="us de ua" KB_TOGGLE=ctrl_shift; then
    expect_line layouts "$input" '^[[:space:]]*layout "us,de,ua"$'                  "installer: custom layouts (KB_LAYOUTS)"
    expect_line layouts "$input" '^[[:space:]]*options "grp:ctrl_shift_toggle"$'    "installer: custom switch (KB_TOGGLE)"
  else
    fail "installer: custom layouts"; sed 's/^/    /' "$WORK/layouts.log" >&2
  fi

  if install_case single KB_LAYOUTS=us; then
    expect_line single "$input" '^[[:space:]]*options ""$' "installer: single layout has no switch shortcut"
  else
    fail "installer: single layout"
  fi

  if install_case tech DOTFILES_MODE=tech; then
    if [[ ! -e "$WORK/tech/.local/share" && ! -e "$WORK/tech/.config/noctalia" ]] &&
       ! grep -q noctalia "$WORK/tech/.config/niri/config.kdl"; then
      pass "installer: tech profile is minimal"
    else
      fail "installer: tech profile is minimal"
    fi
  else
    fail "installer: tech profile"; sed 's/^/    /' "$WORK/tech.log" >&2
  fi

  if install_case nonoctalia NOCTALIA=0 && [[ ! -e "$WORK/nonoctalia/.config/noctalia" ]]; then
    pass "installer: NOCTALIA=0 skips Noctalia files"
  else
    fail "installer: NOCTALIA=0 skips Noctalia files"
  fi

  # Dictation language follows the layouts (fake binary, so nothing is downloaded).
  mkdir -p "$WORK/voice/.local/bin"
  printf '#!/bin/sh\necho "voxtype 1.1.0"\n' >"$WORK/voice/.local/bin/voxtype"
  chmod +x "$WORK/voice/.local/bin/voxtype"
  if install_case voice INSTALL_VOXTYPE=1 KB_LAYOUTS="us ua"; then
    expect_line voice .config/voxtype/config.toml '^language = "uk"$' "installer: Voxtype language follows layouts (ua -> uk)"
  else
    fail "installer: Voxtype config"; sed 's/^/    /' "$WORK/voice.log" >&2
  fi

  # Bad input must be refused, not written into the config.
  for bad in "KB_LAYOUTS=us zz9" "KB_TOGGLE=nonsense" "DOTFILES_MODE=nope" "NOCTALIA=2"; do
    if install_case bad "$bad"; then fail "installer rejects: $bad"; else pass "installer rejects: $bad"; fi
    rm -rf "${WORK:?}/bad"
  done
fi

# ── Hygiene ──────────────────────────────────────────────────────────────────

if search '/home/mixad|/home/[A-Za-z0-9_.-]+/\.config/gh/hosts\.yml|Cookies|Login Data|Bitwarden/data\.json|keyrings|voxtype/models' \
     -g '!scripts/check.sh' -g '!README.md' -g '!.gitignore' -g '!install.sh' >"$WORK/sensitive" 2>/dev/null; then
  cat "$WORK/sensitive" >&2
  fail "personal path or secret-like data detected"
else
  pass "no personal paths or secret-like data"
fi

if search 'DP-1|HDMI-A-1|eDP-[0-9]|WAYLAND_DISPLAY=wayland-[0-9]+|avatar_path' \
     -g '!scripts/check.sh' -g '!README.md' -g '!.gitignore' -g '!install.sh' >"$WORK/machine" 2>/dev/null; then
  cat "$WORK/machine" >&2
  fail "machine-specific monitor/runtime state detected"
else
  pass "no machine-specific monitor/runtime state"
fi

if grep -Eq '^(bitwarden|discord|firefox|helium-browser-bin|telegram-desktop|steam|spotify-launcher|throne-bin|openai-codex-bin)$' \
     "$ROOT/packages/pacman.txt" "$ROOT/packages/aur.txt" 2>/dev/null; then
  fail "non-rice applications found in the default package manifests"
else
  pass "default package manifests stay rice-focused"
fi

# Inline comments in a package list would be passed to pacman verbatim.
if grep -Ev '^[[:space:]]*(#|$)' "$ROOT/packages/pacman.txt" | grep -q '[[:space:]#]'; then
  fail "packages/pacman.txt: package lines must contain only the name"
else
  pass "packages/pacman.txt: one clean package name per line"
fi

if ((failures)); then
  printf '[check] %d check(s) failed\n' "$failures" >&2
  exit 1
fi
printf '[check] all checks passed\n'
