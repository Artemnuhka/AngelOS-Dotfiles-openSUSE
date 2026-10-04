#!/usr/bin/env bash
# angelOS: update the dotfiles this system was installed from (Settings → Updates).
#
#   dotfiles-update.sh --find                 print the repository path, if any
#   dotfiles-update.sh --check REPO           fetch; print BRANCH/UPSTREAM/BEHIND/AHEAD/DIRTY/REMOTE and IN <commit> lines
#   dotfiles-update.sh --clone DEST [URL]     first-time download of the official repository
#   dotfiles-update.sh REPO                   fetch, snapshot, fast-forward, run the installer non-interactively,
#                                             wire niri, `niri validate`
#   dotfiles-update.sh --restore DIR [--dry-run]   undo the update that took snapshot DIR (scripts/update-txn.py)
#   dotfiles-update.sh --last                 the last attempt: LAST <status> <stage> <dir> <old> <new>
#
# An update prints "BACKUP <dir>" once its snapshot is taken and ends with exactly
# one of: "UPDATED <old> <new> <commits>" (exit 0, every step passed; the shell
# then offers a restart) or "FAILED <stage> <text>" (exit code ≠ 0). Stages:
# pull, snapshot (nothing changed), install, niri-integration, niri-validate,
# niri-missing (niri is not installed, so the config cannot be checked).
#
# Nothing is updated without a click. Before the installer runs, every file it
# may write is copied into ~/.local/state/angelos/backups/<stamp>-update and
# read back; without that copy nothing changes. A failed update can be undone
# from there (--restore): only what this update changed goes back, and files
# changed again since then stay as they are (reported as conflicts). The
# installer itself keeps the user's changed configs (kept-updates/) and the
# current keyboard layouts are passed through so they survive.
set -Eeuo pipefail
say() { printf '» %s\n' "$*"; }
OFFICIAL="https://github.com/MixaDoDs/AngelOS-Dotfiles"
# the name before 2026-09-30: installs cloned from it keep it as their origin (GitHub redirects)
LEGACY="https://github.com/MixaDoDs/PixelStreetArt_Dotfiles_Niri"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/angelos"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
TXN="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/update-txn.py"
NIRI_BIN="${NIRI_BIN:-niri}"   # tests point it elsewhere

# before the snapshot: nothing was changed
fail_early() { say "$2"; echo "FAILED $1 $2"; exit "${3:-1}"; }
# after it: write the failure into the snapshot and point at the way back
fail() {
  trap - ERR
  python3 "$TXN" finish "$B" --status failed --stage "$1" --message "$2" 2>&1 || say "не удалось записать итог в $B"
  say "$2"
  say "состояние до обновления сохранено: $B (Настройки → Обновления → «Вернуть как было»)"
  echo "BACKUP $B"
  echo "FAILED $1 $2"
  exit "${3:-1}"
}

is_repo() { [[ -d "$1/.git" && -f "$1/install.sh" ]]; }

# updates run the repository's installer, so only pull from where this system
# came from: the official repository or the remote recorded at install time
norm_url() { local u="${1%/}"; printf '%s' "${u%.git}"; }
trusted_remote() {
  local url rec=""
  url="$(git remote get-url origin 2>/dev/null || true)"
  [[ -f "$CONF/angelos/dotfiles-source" ]] && rec="$(sed -n 's/^remote=//p' "$CONF/angelos/dotfiles-source" | head -1)"
  [[ -n "$url" ]] || return 1
  [[ "$(norm_url "$url")" == "$(norm_url "$OFFICIAL")" || "$(norm_url "$url")" == "$(norm_url "$LEGACY")" ]] && return 0
  [[ -n "$rec" && "$(norm_url "$url")" == "$(norm_url "$rec")" ]]
}

find_repo() {
  local marker="$CONF/angelos/dotfiles-source" r
  if [[ -f "$marker" ]]; then
    r="$(sed -n 's/^repo=//p' "$marker" | head -1)"
    is_repo "$r" && { printf '%s\n' "$r"; return 0; }
  fi
  for r in "$HOME/AngelOS-Dotfiles" "$HOME/PixelStreetArt_Dotfiles_Niri" "${XDG_DATA_HOME:-$HOME/.local/share}/angelos/dotfiles" \
           "$HOME/Projects/AngelOS-Dotfiles" "$HOME/Projects/PixelStreetArt_Dotfiles_Niri" "$HOME/.dotfiles/PixelStreetArt_Dotfiles_Niri"; do
    is_repo "$r" && { printf '%s\n' "$r"; return 0; }
  done
  return 1
}

case "${1:-}" in
  --find)
    find_repo || exit 1
    exit 0 ;;
  --check)
    cd "${2:?repo}"
    is_repo . || { echo "ERR not a dotfiles repository"; exit 2; }
    git fetch --quiet 2>&1 || { echo "ERR fetch"; exit 1; }
    echo "BRANCH $(git rev-parse --abbrev-ref HEAD)"
    echo "UPSTREAM $(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo none)"
    echo "BEHIND $(git rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)"
    echo "AHEAD $(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
    echo "DIRTY $(git status --porcelain | wc -l)"
    echo "REMOTE $(git remote get-url origin 2>/dev/null || echo none)"
    trusted_remote && echo "TRUSTED 1" || echo "TRUSTED 0"
    git log --format='IN %h %s' 'HEAD..@{u}' 2>/dev/null | head -40 || true
    exit 0 ;;
  --clone)
    DEST="${2:?destination}"
    URL="${3:-$OFFICIAL}"
    [[ "$URL" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]] || { say "адрес должен быть https://github.com/…"; exit 2; }
    [[ -e "$DEST" ]] && { say "папка уже существует: $DEST"; exit 2; }
    mkdir -p -- "$(dirname -- "$DEST")"
    say "git clone $URL"
    git clone --depth 50 -- "$URL" "$DEST" 2>&1
    mkdir -p -- "$CONF/angelos"
    printf 'repo=%s\nremote=%s\n' "$DEST" "$URL" >"$CONF/angelos/dotfiles-source"
    say "готово ♡"
    exit 0 ;;
  --restore)
    D="${2:?snapshot}"
    [[ -f "$D/meta.json" ]] || { echo "RESTORE-FAILED backup нет снимка: $D"; exit 2; }
    case "$(realpath -- "$D")" in
      "$(realpath -m -- "$STATE/backups")"/*) ;;
      *) echo "RESTORE-FAILED backup снимок не из $STATE/backups"; exit 2 ;;
    esac
    command -v python3 >/dev/null || { echo "RESTORE-FAILED python3 python3 не найден"; exit 5; }
    # the helper that took the snapshot also undoes it
    T="$D/update-txn.py"
    [[ -f "$T" ]] || T="$TXN"
    exec python3 "$T" restore "$D" "${@:3}" ;;
  --last)
    command -v python3 >/dev/null || exit 0
    exec python3 "$TXN" last --state "$STATE" ;;
esac

REPO="${1:?repo}"
cd "$REPO"
is_repo . || { say "это не репозиторий dotfiles: $REPO"; exit 2; }
if ! trusted_remote; then
  say "origin = $(git remote get-url origin 2>/dev/null || echo '?') — это не официальный репозиторий и не тот, из которого ставилась система; обновление отменено"
  exit 4
fi
if [[ -n "$(git status --porcelain)" ]]; then
  say "в репозитории есть свои изменения — обнови вручную (git stash; git pull) или откати их:"
  git status --short | head -20
  exit 3
fi
command -v python3 >/dev/null || fail_early snapshot "python3 не найден: снимок конфигов сделать нельзя, обновление не начато" 5

branch="$(git rev-parse --abbrev-ref HEAD)"
say "git fetch ($branch)"
git fetch --quiet 2>&1 || fail_early pull "git fetch не прошёл — сеть или доступ к репозиторию" 6
old="$(git rev-parse HEAD)"
new="$(git rev-parse '@{u}' 2>/dev/null)" || fail_early pull "у ветки $branch нет upstream" 6
# The original remote is an Arch installer. Never replace this Tumbleweed port
# with an upstream tree that does not contain the zypper manifests.
if [[ -f packages/zypper.txt ]] && ! git cat-file -e "$new:packages/zypper.txt" 2>/dev/null; then
  fail_early pull "upstream не содержит порт openSUSE: перенесите изменения вручную, установщик zypper сохранён" 6
fi
git merge-base --is-ancestor "$old" "$new" ||
  fail_early pull "локальная ветка разошлась с $(git rev-parse --abbrev-ref '@{u}') — обнови вручную" 6

# the snapshot, before anything is changed: every file the installer may write,
# copied and read back (scripts/update-txn.py); no snapshot, no update
STAMP="$(date +%Y%m%d-%H%M%S)"
B="$STATE/backups/$STAMP-update"
n=1
while [[ -e "$B" ]]; do n=$((n + 1)); STAMP="$(date +%Y%m%d-%H%M%S)-$n"; B="$STATE/backups/$STAMP-update"; done
python3 "$TXN" snapshot "$B" --home "$HOME" --state "$STATE" --repo "$PWD" --rev "$old" --rev "$new" --stamp "$STAMP" 2>&1 ||
  fail_early snapshot "резервная копия не создана ($B) — ничего не менялось" 5
TXN="$B/update-txn.py"                # the same helper finishes and restores this attempt
echo "BACKUP $B"
exec 9>"$B/.lock"
{ command -v flock >/dev/null && flock -n 9; } || true    # a restore waits for the update to end

STAGE=pull
trap 'fail "$STAGE" "неожиданная ошибка (строка $LINENO)" 13' ERR

say "git merge --ff-only ($branch)"
git merge --ff-only --quiet "$new" 2>&1 || fail pull "git merge не прошёл" 6

# keep the keyboard as it is now
input="$CONF/niri/cfg/input.kdl"
kb_env=()
if [[ -f "$input" ]]; then
  layouts="$(sed -n 's/^[[:space:]]*layout[[:space:]]*"\([^"]*\)".*/\1/p' "$input" | head -1)"
  options="$(sed -n 's/^[[:space:]]*options[[:space:]]*"\([^"]*\)".*/\1/p' "$input" | head -1)"
  [[ "$layouts" =~ ^[a-z,]+$ ]] && kb_env+=("KB_LAYOUTS=$layouts")
  [[ -n "$options" && "$options" =~ ^[a-z0-9_:,]+$ ]] && kb_env+=("KB_TOGGLE=$options")
fi

STAGE=install
say "запускаю установщик (без пакетов, SDDM и служб)"
# ANGELOS_RESTART=shell: the running shell asks about the restart itself (UpdatePrompt);
# DOTFILES_STAMP: its *.bak.<stamp> backups belong to this attempt; VALIDATE_NIRI=0:
# niri is validated once, below, after the wiring
env ANGELOS_RESTART=shell DOTFILES_MODE=full DESKTOP_SHELL=angelos SKIP_PACKAGES=1 INSTALL_SDDM=0 INSTALL_VOXTYPE=0 \
    DOWNLOAD_VOXTYPE_MODEL=0 INSTALL_WALLPAPERS=0 INSTALL_FLATPAK=0 ENABLE_SERVICES=0 DOTFILES_STAMP="$STAMP" VALIDATE_NIRI=0 \
    "${kb_env[@]}" bash ./install.sh </dev/null 2>&1 || fail install "установщик завершился с ошибкой (код $?)" 10

STAGE=niri-integration
if [[ -f "$CONF/angelos/active" ]]; then
  say "angelOS активен — перепроверяю интеграцию с niri"
  # --no-validate: no fallback to Noctalia here; a failure is undone with the snapshot
  python3 "$CONF/quickshell/angelos/scripts/switch.py" angelos --no-restart --no-validate 2>&1 ||
    fail niri-integration "switch.py не смог подключить angelOS к niri" 11
fi

STAGE=niri-validate
command -v "$NIRI_BIN" >/dev/null || fail niri-missing "niri не найден: конфиг проверить нельзя, обновление не подтверждено" 12
if ! vout="$("$NIRI_BIN" validate 2>&1)"; then
  printf '%s\n' "$vout" | tail -n 20 | sed 's/^/  /'
  fail niri-validate "конфиг niri не проходит niri validate" 12
fi
say "niri: конфиг валиден"

trap - ERR
python3 "$TXN" finish "$B" --status ok --stage "done" 2>&1 || say "не удалось записать итог в $B"
say "готово ♡"
printf 'UPDATED %s %s %s\n' "$old" "$new" "$(git rev-list --count "$old..$new" 2>/dev/null || echo 0)"
