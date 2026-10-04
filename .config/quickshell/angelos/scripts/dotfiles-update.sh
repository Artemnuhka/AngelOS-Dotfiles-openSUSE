#!/usr/bin/env bash
# angelOS: update the dotfiles this system was installed from (Settings → Updates).
#
#   dotfiles-update.sh --find                 print the repository path, if any
#   dotfiles-update.sh --check REPO           fetch; print BRANCH/UPSTREAM/BEHIND/AHEAD/DIRTY/REMOTE and IN <commit> lines
#                                             ("ERR fetch <git's reason>" when the repository can't be reached)
#   dotfiles-update.sh --clone DEST [URL]     first-time download of the official repository
#   dotfiles-update.sh REPO                   fetch, snapshot, fast-forward, run the installer non-interactively,
#                                             wire niri, `niri validate`
#   dotfiles-update.sh --restore DIR [--dry-run]   undo the update that took snapshot DIR (scripts/update-txn.py)
#   dotfiles-update.sh --last                 the last attempt: LAST <status> <stage> <dir> <old> <new>
#
# An update prints "BACKUP <dir>" once its snapshot is taken and ends with exactly
# one of: "UPDATED <old> <new> <commits>" (exit 0, every step passed; the shell
# then offers a restart) or "FAILED <stage> <text>" (exit code ≠ 0): the text says
# why and what to do next. Stopped before the snapshot, nothing changed: repo (2),
# local-changes (3, the clone has uncommitted edits), untrusted (4, origin is not
# where the system came from), local-commits (7, commits of its own: a fast-forward
# is impossible or there is nothing to take), pull (6, no network, no upstream),
# snapshot (5). After it (BACKUP given, --restore undoes it): pull (6), install
# (10, with the installer's own error line; its whole output is in <dir>/install.log),
# niri-integration (11), niri-validate / niri-missing (12, niri is not installed, so
# the config cannot be checked), anything unexpected (13).
# "CHANGED <files> <shell 0|1>" (from update-txn.py finish) says what the attempt changed.
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
# the messages in the shell's language (ANGELOS_LANG, Settings → Account), else the session's
case "${ANGELOS_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}" in ru*) UI=ru ;; *) UI=en ;; esac
_() { if [[ "$UI" == ru ]]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
OFFICIAL="https://github.com/MixaDoDs/AngelOS-Dotfiles"
# the name before 2026-09-30: installs cloned from it keep it as their origin (GitHub redirects)
LEGACY="https://github.com/MixaDoDs/PixelStreetArt_Dotfiles_Niri"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/angelos"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
TXN="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/update-txn.py"
NIRI_BIN="${NIRI_BIN:-niri}"   # tests point it elsewhere

# before the snapshot: nothing was changed
fail_early() { say "$2"; echo "FAILED $1 $2"; exit "${3:-1}"; }
# what git said, for a message: its first "fatal:"/"error:" line (the specific one), else its last line
git_reason() {
  local r
  r="$(sed -n 's/^\(fatal\|error\): //p' "$1" | head -n 1)"
  [[ -n "$r" ]] || r="$(grep -v '^[[:space:]]*$' "$1" | tail -n 1)"
  printf '%s' "$r"
}
# after it: write the failure into the snapshot and point at the way back
fail() {
  trap - ERR
  python3 "$TXN" finish "$B" --status failed --stage "$1" --message "$2" 2>&1 || say "$(_ "could not record the outcome in $B" "не удалось записать итог в $B")"
  say "$2"
  say "$(_ "the state before the update is kept: $B (Settings → Updates → \"Restore\")" "состояние до обновления сохранено: $B (Настройки → Обновления → «Вернуть как было»)")"
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
    err="$(mktemp)"
    if ! git fetch --quiet 2>"$err"; then
      echo "ERR fetch $(git_reason "$err")"
      rm -f "$err"
      exit 1
    fi
    rm -f "$err"
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
    [[ "$URL" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]] || { say "$(_ "the address must be https://github.com/…" "адрес должен быть https://github.com/…")"; exit 2; }
    [[ -e "$DEST" ]] && { say "$(_ "the folder already exists: $DEST" "папка уже существует: $DEST")"; exit 2; }
    mkdir -p -- "$(dirname -- "$DEST")"
    say "git clone $URL"
    err="$(mktemp)"
    if ! git clone --depth 50 -- "$URL" "$DEST" 2>"$err"; then
      sed 's/^/  /' "$err"
      why="$(git_reason "$err")"
      rm -f "$err"
      fail_early clone "$(_ "git clone failed (${why:-no answer}): no network, or GitHub can't be reached — try again later" \
                            "git clone не прошёл (${why:-нет ответа}): нет сети или GitHub недоступен — попробуй позже")" 6
    fi
    rm -f "$err"
    mkdir -p -- "$CONF/angelos"
    printf 'repo=%s\nremote=%s\n' "$DEST" "$URL" >"$CONF/angelos/dotfiles-source"
    say "$(_ "done ♡" "готово ♡")"
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
cd "$REPO" 2>/dev/null || fail_early repo "$(_ "the repository folder is gone: $REPO — download the dotfiles again (Settings → Updates)" \
                                               "папки репозитория нет: $REPO — скачай dotfiles заново (Настройки → Обновления)")" 2
is_repo . || fail_early repo "$(_ "not a dotfiles repository: $REPO (no .git or install.sh)" "это не репозиторий dotfiles: $REPO (нет .git или install.sh)")" 2
if ! trusted_remote; then
  url="$(git remote get-url origin 2>/dev/null || echo '?')"
  fail_early untrusted "$(_ "origin is $url — neither the official repository nor the one this system was installed from, and an update runs its installer. Nothing changed. Point origin back (git -C \"$REPO\" remote set-url origin $OFFICIAL) or update by hand" \
                            "origin = $url — это не официальный репозиторий и не тот, из которого ставилась система, а обновление запускает его установщик. Ничего не менялось. Верни origin (git -C \"$REPO\" remote set-url origin $OFFICIAL) или обнови вручную")" 4
fi
if [[ -n "$(git status --porcelain)" ]]; then
  n="$(git status --porcelain | wc -l)"
  git status --short | head -20 | sed 's/^/  /'
  fail_early local-changes "$(_ "the repository folder has edits of its own ($n files, listed above): the update would lose them, so it did not start. Commit or put them aside (git -C \"$REPO\" stash -u), or drop them, then update again" \
                                "в папке репозитория свои правки ($n файлов, список выше): обновление их бы потеряло, поэтому не начиналось. Закоммить или отложи их (git -C \"$REPO\" stash -u) либо откати, потом обнови снова")" 3
fi
command -v python3 >/dev/null || fail_early snapshot "$(_ "python3 is missing: the snapshot can't be taken, the update did not start (sudo pacman -S python)" \
                                                          "python3 не найден: снимок конфигов сделать нельзя, обновление не начато (sudo pacman -S python)")" 5

branch="$(git rev-parse --abbrev-ref HEAD)"
say "git fetch ($branch)"
err="$(mktemp)"
if ! git fetch --quiet 2>"$err"; then
  why="$(git_reason "$err")"
  sed 's/^/  /' "$err"
  rm -f "$err"
  fail_early pull "$(_ "git fetch failed (${why:-no answer}): no network, or the repository can't be reached. Nothing changed — check the connection and try again" \
                       "git fetch не прошёл (${why:-нет ответа}): нет сети или репозиторий недоступен. Ничего не менялось — проверь подключение и попробуй ещё раз")" 6
fi
rm -f "$err"
old="$(git rev-parse HEAD)"
new="$(git rev-parse '@{u}' 2>/dev/null)" ||
  fail_early pull "$(_ "branch $branch follows no remote branch (upstream) — switch to main (git -C \"$REPO\" switch main) and update again" \
                       "у ветки $branch нет upstream — переключись на main (git -C \"$REPO\" switch main) и обнови снова")" 6
up="$(git rev-parse --abbrev-ref '@{u}')"
# commits of the clone's own: a fast-forward would lose them (a developer's working clone)
ahead="$(git rev-list --count "$new..$old")" behind="$(git rev-list --count "$old..$new")"
if ((ahead > 0 && behind == 0)); then
  fail_early local-commits "$(_ "the repository has $ahead commit(s) of its own that $up doesn't have, and nothing new came: there is nothing to update. Nothing changed. Install your own version with its installer (./install.sh)" \
                                "в репозитории $ahead своих коммит(а/ов), которых нет в $up, а нового там нет — обновлять нечего. Ничего не менялось. Свою версию ставь её установщиком (./install.sh)")" 7
elif ((ahead > 0)); then
  fail_early local-commits "$(_ "the branch went its own way: $ahead commit(s) of its own and $behind new in $up, so it can't be fast-forwarded. Nothing changed. Put your commits on top of the new ones (git -C \"$REPO\" pull --rebase), then update again" \
                                "ветка разошлась с $up: $ahead своих коммит(а/ов) и $behind новых — перемотать нельзя. Ничего не менялось. Перенеси свои коммиты поверх новых (git -C \"$REPO\" pull --rebase), потом обнови снова")" 7
fi

# the snapshot, before anything is changed: every file the installer may write,
# copied and read back (scripts/update-txn.py); no snapshot, no update
STAMP="$(date +%Y%m%d-%H%M%S)"
B="$STATE/backups/$STAMP-update"
n=1
while [[ -e "$B" ]]; do n=$((n + 1)); STAMP="$(date +%Y%m%d-%H%M%S)-$n"; B="$STATE/backups/$STAMP-update"; done
python3 "$TXN" snapshot "$B" --home "$HOME" --state "$STATE" --repo "$PWD" --rev "$old" --rev "$new" --stamp "$STAMP" 2>&1 ||
  fail_early snapshot "$(_ "the snapshot was not taken ($B, see the line above) — nothing changed. Check free space and that ${STATE/#$HOME/\~} is writable" \
                           "резервная копия не создана ($B, причина строкой выше) — ничего не менялось. Проверь свободное место и права на ${STATE/#$HOME/\~}")" 5
TXN="$B/update-txn.py"                # the same helper finishes and restores this attempt
echo "BACKUP $B"
exec 9>"$B/.lock"
{ command -v flock >/dev/null && flock -n 9; } || true    # a restore waits for the update to end

STAGE=pull
trap 'fail "$STAGE" "$(_ "unexpected error (dotfiles-update.sh, line $LINENO)" "неожиданная ошибка (dotfiles-update.sh, строка $LINENO)")" 13' ERR

say "git merge --ff-only ($branch)"
err="$B/merge.log"
if ! git merge --ff-only --quiet "$new" >"$err" 2>&1; then
  sed 's/^/  /' "$err"
  fail pull "$(_ "git merge failed ($(git_reason "$err")) — the repository stayed on the old version" "git merge не прошёл ($(git_reason "$err")) — репозиторий остался на прежней версии")" 6
fi

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
say "$(_ "running the installer (no packages, SDDM or services)" "запускаю установщик (без пакетов, SDDM и служб)")"
# ANGELOS_RESTART=shell: the running shell asks about the restart itself (UpdatePrompt);
# DOTFILES_STAMP: its *.bak.<stamp> backups belong to this attempt; VALIDATE_NIRI=0:
# niri is validated once, below, after the wiring
# its output goes to the log as it comes, and into the snapshot for later (install.log)
ilog="$B/install.log"
if ! { env ANGELOS_RESTART=shell DOTFILES_MODE=full DESKTOP_SHELL=angelos SKIP_PACKAGES=1 INSTALL_SDDM=0 INSTALL_VOXTYPE=0 \
         DOWNLOAD_VOXTYPE_MODEL=0 INSTALL_WALLPAPERS=0 INSTALL_FLATPAK=0 ENABLE_SERVICES=0 DOTFILES_STAMP="$STAMP" VALIDATE_NIRI=0 \
         "${kb_env[@]}" bash ./install.sh </dev/null 2>&1; } | tee "$ilog"; then
  code="${PIPESTATUS[0]}"
  # the installer's own reason (its "ERROR:" line), else its last words
  why="$(sed -e $'s/\x1b\\[[0-9;]*m//g' "$ilog" | sed -n 's/^.*\[dotfiles\] ERROR:[[:space:]]*//p' | tail -n 1)"
  [[ -n "$why" ]] || why="$(sed -e $'s/\x1b\\[[0-9;]*m//g' -e 's/^\[dotfiles\][[:space:]]*//' "$ilog" | grep -v '^[[:space:]]*$' | tail -n 1)"
  say "$(_ "the installer's whole output: $ilog" "весь вывод установщика: $ilog")"
  fail install "$(_ "the installer stopped (code $code): ${why:-no message}" "установщик остановился (код $code): ${why:-без сообщения}")" 10
fi

STAGE=niri-integration
if [[ -f "$CONF/angelos/active" ]]; then
  say "$(_ "angelOS is active — wiring it into niri again" "angelOS активен — перепроверяю интеграцию с niri")"
  # --no-validate: no fallback to Noctalia here; a failure is undone with the snapshot
  python3 "$CONF/quickshell/angelos/scripts/switch.py" angelos --no-restart --no-validate 2>&1 ||
    fail niri-integration "$(_ "switch.py could not wire angelOS into niri (see the log above)" "switch.py не смог подключить angelOS к niri (подробности в журнале выше)")" 11
fi

STAGE=niri-validate
command -v "$NIRI_BIN" >/dev/null || fail niri-missing "$(_ "niri is not installed: the config can't be checked, so the update is not confirmed" "niri не найден: конфиг проверить нельзя, обновление не подтверждено")" 12
if ! vout="$("$NIRI_BIN" validate 2>&1)"; then
  printf '%s\n' "$vout" | tail -n 20 | sed 's/^/  /'
  why="$(printf '%s\n' "$vout" | grep -v '^[[:space:]]*$' | tail -n 1)"
  fail niri-validate "$(_ "the niri config fails niri validate: $why" "конфиг niri не проходит niri validate: $why")" 12
fi
say "$(_ "niri: the config is valid" "niri: конфиг валиден")"

trap - ERR
python3 "$TXN" finish "$B" --status ok --stage "done" 2>&1 || say "$(_ "could not record the outcome in $B" "не удалось записать итог в $B")"
say "$(_ "done ♡" "готово ♡")"
printf 'UPDATED %s %s %s\n' "$old" "$new" "$(git rev-list --count "$old..$new" 2>/dev/null || echo 0)"
