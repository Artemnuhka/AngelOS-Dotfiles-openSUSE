#!/usr/bin/env bash
# Settings → Updates end to end, offline and away from your session: a throw-away
# $HOME installed from this working tree, a local "origin" that publishes the next
# version, and stand-ins for niri (`niri validate` fails on a NIRI-INVALID line),
# qs, notify-send, pkill and systemctl. No network, no real settings touched.
#
#   scripts/test-update.sh             the update script and its restore
#   UPDATE_UI=0 scripts/test-update.sh skip the Settings → Updates UI part
#   REQUIRE_UI=1 …                     a missing quickshell is a failure, not a skip (CI)
#   KEEP_TEST_DIR=1 …                  keep the scratch folder for a look afterwards
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SHELL_SRC="$ROOT/.config/quickshell/angelos"
W="$(mktemp -d)"
if [[ -n "${KEEP_TEST_DIR:-}" ]]; then trap 'echo "[update] scratch kept: $W"' EXIT; else trap 'rm -rf -- "$W"' EXIT; fi
failures=0
pass() { printf '[update] OK   %s\n' "$*"; }
fail() { printf '[update] FAIL %s\n' "$*" >&2; failures=$((failures + 1)); }
skip() { printf '[update] SKIP %s\n' "$*"; }
check() { local what="$1"; shift; if "$@"; then pass "$what"; else fail "$what"; fi; }
G=(git -c user.name=test -c user.email=test@invalid -c init.defaultBranch=main -c commit.gpgsign=false -c advice.detachedHead=false)

# ── stand-ins ────────────────────────────────────────────────────────────────
STUBS="$W/stubs"
mkdir -p "$STUBS"
cat >"$STUBS/niri" <<'SH'
#!/bin/sh
# niri stand-in: `niri validate [-c FILE]` fails when the config folder has a NIRI-INVALID line
[ "$1" = validate ] || { echo "niri $*" >>"$HOME/stub-calls"; exit 0; }
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
[ "${2:-}" = -c ] && cfg="$3"
[ -f "$cfg" ] || { echo "Error: no config at $cfg" >&2; exit 1; }
if grep -rqs 'NIRI-INVALID' "$(dirname "$cfg")"; then
  echo "Error: unexpected node NIRI-INVALID" >&2
  exit 1
fi
exit 0
SH
for c in qs quickshell notify-send pkill systemctl setsid fc-cache xdg-user-dirs-update; do
  printf '#!/bin/sh\necho "%s $*" >>"$HOME/stub-calls"\nexit 0\n' "$c" >"$STUBS/$c"
done
chmod +x "$STUBS"/*

# ── the repository as v1, its origin, one real install ───────────────────────
SRC="$W/src"
mkdir -p "$SRC"
(cd "$ROOT" && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do
   [[ -e "$f" || -L "$f" ]] && printf '%s\0' "$f"; done | tar --null -T - -cf -) | tar -C "$SRC" -xf -
"${G[@]}" -C "$SRC" init -q
"${G[@]}" -C "$SRC" add -A
"${G[@]}" -C "$SRC" commit -qm v1
V1="$(git -C "$SRC" rev-parse HEAD)"
"${G[@]}" clone -q --bare "$SRC" "$W/origin.git"

H="$W/home"                     # always this path: installed files hold it (@HOME@)
REPO="$H/AngelOS-Dotfiles"
ENVS=(env -i HOME="$H" PATH="$STUBS:$PATH" LANG=C USER=test)
"${ENVS[@]}" git clone -q "$W/origin.git" "$REPO"
if ! "${ENVS[@]}" SKIP_PACKAGES=1 INSTALL_VOXTYPE=0 DOWNLOAD_VOXTYPE_MODEL=0 ENABLE_SERVICES=0 INSTALL_WALLPAPERS=0 \
     INSTALL_SDDM=0 DESKTOP_SHELL=angelos bash "$REPO/install.sh" </dev/null >"$W/install.log" 2>&1; then
  sed 's/^/    /' "$W/install.log" >&2
  fail "first install of the fixture"
  exit 1
fi
printf '{"setup":{"complete":true},"mine":1}\n' >"$H/.config/angelos/settings.json"
cp -a "$H" "$W/home.tpl"
cp -a "$W/origin.git" "$W/origin.tpl"

STATE="$H/.local/state/angelos"
SCRIPT="$H/.config/quickshell/angelos/scripts/dotfiles-update.sh"
QML_FILE=".config/quickshell/angelos/services/Updates.qml"
NEW_FILE=".config/quickshell/angelos/tests/update-fixture.txt"
LAYOUT=".config/niri/cfg/layout.kdl"

new_case() {
  CASE="$1"
  rm -rf -- "$H" "$W/origin.git" "$W/work"
  cp -a "$W/home.tpl" "$H"
  cp -a "$W/origin.tpl" "$W/origin.git"
  "${G[@]}" clone -q "$W/origin.git" "$W/work"
}
# the next version in origin: a shell file changed, a new one, a niri file changed
v2_edits() {
  echo '// v2' >>"$W/work/$QML_FILE"
  mkdir -p "$(dirname "$W/work/$NEW_FILE")"
  echo 'new in v2' >"$W/work/$NEW_FILE"
  echo '// v2 layout' >>"$W/work/$LAYOUT"
}
publish() { (cd "$W/work" && "${G[@]}" add -A && "${G[@]}" commit -qm "$1" && "${G[@]}" push -q origin HEAD:main); }
update() { # [VAR=value…]
  "${ENVS[@]}" "$@" bash "$SCRIPT" "$REPO" >"$W/$CASE.out" 2>&1
  RC=$?
  BACKUP="$(sed -n 's/^BACKUP //p' "$W/$CASE.out" | tail -n 1)"
}
restore() { # DIR [VAR=value…]
  local dir="$1"; shift
  "${ENVS[@]}" "$@" bash "$SCRIPT" --restore "$dir" >"$W/$CASE.restore.out" 2>&1
  RC=$?
}
# every installed file (sha or link target), the snapshots themselves left out
fingerprint() {
  python3 - "$H" <<'PY'
import hashlib, os, sys
home = sys.argv[1]
# not installed files: the snapshots, the repository, caches (gsettings in the theme hooks)
skip = {os.path.join(home, ".local/state/angelos/backups"), os.path.join(home, "AngelOS-Dotfiles"), os.path.join(home, ".cache")}
for base, dirs, files in os.walk(home):
    dirs[:] = sorted(d for d in dirs if os.path.join(base, d) not in skip)
    for f in sorted(files):
        p = os.path.join(base, f)
        if f in ("update-last", "stub-calls"):
            continue
        if os.path.islink(p):
            print("L", os.readlink(p), os.path.relpath(p, home))
        else:
            print(hashlib.sha256(open(p, "rb").read()).hexdigest(), os.path.relpath(p, home))
PY
}
# a field of a snapshot's meta.json ("" when there is none: the checks then fail, the run goes on)
meta() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1/meta.json" "$2" 2>/dev/null || true; }
show() { sed 's/^/    | /' "$1" >&2; }
has_line() { grep -q -- "$2" "$W/$1"; }
no_updated() { ! grep -q '^UPDATED ' "$W/$CASE.out"; }
head_is() { [[ "$(git -C "$REPO" rev-parse HEAD)" == "$1" ]]; }
only_changed() { # FILE_A FILE_B PATH… : the two fingerprints differ in exactly these paths
  local a="$1" b="$2"; shift 2
  diff <(sort -k2 "$a") <(sort -k2 "$b") | sed -n 's/^[<>] [^ ]* //p' | sort -u >"$W/delta"
  diff -q <(printf '%s\n' "$@" | sort -u) "$W/delta" >/dev/null
}

# from here on every check reports and the run goes on, whatever state a broken
# update leaves behind
set +e

# ── 1. a successful update ───────────────────────────────────────────────────
new_case success
v2_edits
echo '// v2 binds' >>"$W/work/.config/niri/cfg/keybinds.kdl"
publish v2
V2="$(git -C "$W/work" rev-parse HEAD)"
echo '// my own binds' >>"$H/.config/niri/cfg/keybinds.kdl"     # the user's change before the update
update
if ((RC == 0)); then pass "success: exit 0"; else fail "success: exit $RC"; show "$W/$CASE.out"; fi
check "success: UPDATED is the last line, with old/new commits" \
  test "$(tail -n 1 "$W/$CASE.out")" = "UPDATED $V1 $V2 1"
check "success: no FAILED line" bash -c "! grep -q '^FAILED ' '$W/$CASE.out'"
check "success: repository fast-forwarded" head_is "$V2"
check "success: shell code updated, new file installed" \
  bash -c "grep -q '// v2' '$H/$QML_FILE' && [[ -f '$H/$NEW_FILE' ]] && grep -q 'v2 layout' '$H/$LAYOUT'"
check "success: the user's binds kept, the new version parked in kept-updates" \
  bash -c "grep -q 'my own binds' '$H/.config/niri/cfg/keybinds.kdl' && ! grep -q 'v2 binds' '$H/.config/niri/cfg/keybinds.kdl' &&
           grep -q 'v2 binds' '$STATE/kept-updates/.config/niri/cfg/keybinds.kdl'"
check "success: settings.json untouched" grep -qx '{"setup":{"complete":true},"mine":1}' "$H/.config/angelos/settings.json"
check "success: snapshot recorded as ok" test "$(meta "$BACKUP" status)" = ok
"${ENVS[@]}" bash "$SCRIPT" --last >"$W/last" 2>&1 || true
check "success: --last reports it" grep -q "^LAST ok done $BACKUP $V1 $V2" "$W/last"

# ── 2. the installer fails halfway; restore, with a change made after the update ──
new_case install-fails
v2_edits
python3 - "$W/work/install.sh" <<'PY'
import sys
p = sys.argv[1]
t = open(p).read()
assert "install_configs\ninstall_shell\n" in t
open(p, "w").write(t.replace("install_configs\ninstall_shell\n", "install_configs\nfalse  # the test's broken step\ninstall_shell\n"))
PY
publish "v2 with a broken installer"
fingerprint >"$W/before"
update
if ((RC == 10)); then pass "installer failure: exit 10"; else fail "installer failure: exit $RC (want 10)"; show "$W/$CASE.out"; fi
check "installer failure: no UPDATED" no_updated
check "installer failure: FAILED install, BACKUP given" \
  bash -c "grep -q '^FAILED install ' '$W/$CASE.out' && [[ -d '$BACKUP' ]]"
check "installer failure: snapshot recorded as failed (stage install)" \
  test "$(meta "$BACKUP" status)/$(meta "$BACKUP" stage)" = failed/install
check "installer failure: files were half-installed (so there is something to undo)" grep -q '// v2' "$H/$QML_FILE"
"${ENVS[@]}" bash "$SCRIPT" --last >"$W/last" 2>&1 || true
check "installer failure: --last offers the snapshot" grep -q "^LAST failed install $BACKUP $V1 " "$W/last"
echo '// mine, after the update' >>"$H/$LAYOUT"                  # changed again by the user
STAMP="$(meta "$BACKUP" stamp)"
restore "$BACKUP"
if ((RC == 0)); then pass "restore: exit 0"; else fail "restore: exit $RC"; show "$W/$CASE.restore.out"; fi
check "restore: RESTORED with one conflict" grep -qE '^RESTORED [0-9]+ 1 1$' "$W/$CASE.restore.out"
check "restore: the conflict is the file changed after the update" grep -qx "CONFLICT $H/$LAYOUT" "$W/$CASE.restore.out"
check "restore: that file keeps the user's change" grep -q 'mine, after the update' "$H/$LAYOUT"
check "restore: shell code back to v1, the created file removed" \
  bash -c "! grep -q '// v2' '$H/$QML_FILE' && [[ ! -e '$H/$NEW_FILE' ]]"
check "restore: the installer's *.bak.$STAMP backups of this attempt removed" \
  test -z "$(find "$H" \( -path "$H/AngelOS-Dotfiles" -o -path "$STATE/backups" \) -prune -o -name "*.bak.$STAMP" -print)"
fingerprint >"$W/after"
check "restore: everything else is exactly as before the update (manifest keeps only the conflict's entry)" \
  only_changed "$W/before" "$W/after" "$LAYOUT" .local/state/angelos/installed-files.sha256
want="$(sed -n "s|^\([0-9a-f]*\)  $LAYOUT\$|\1|p" "$BACKUP/manifest.after")"
check "restore: manifest entry of the conflict is the update's, so the next update keeps the user's file" \
  grep -qx "$want  $LAYOUT" "$STATE/installed-files.sha256"
check "restore: repository back on v1 (the update is offered again)" head_is "$V1"
check "restore: recorded as restored" test "$(meta "$BACKUP" status)" = restored
restore "$BACKUP"
check "restore: a second restore is refused" test "$RC" -ne 0

# ── 3. the new version leaves niri with a config it refuses ──────────────────
new_case niri-invalid
v2_edits
echo '// NIRI-INVALID' >>"$W/work/$LAYOUT"
publish "v2 with a broken niri config"
fingerprint >"$W/before"
update
if ((RC == 12)); then pass "invalid niri: exit 12"; else fail "invalid niri: exit $RC (want 12)"; show "$W/$CASE.out"; fi
check "invalid niri: no UPDATED, FAILED niri-validate" \
  bash -c "! grep -q '^UPDATED ' '$W/$CASE.out' && grep -q '^FAILED niri-validate ' '$W/$CASE.out'"
check "invalid niri: niri's own error is shown" grep -q 'unexpected node NIRI-INVALID' "$W/$CASE.out"
restore "$BACKUP"
if ((RC == 0)); then pass "invalid niri: restore exit 0"; else fail "invalid niri: restore exit $RC"; show "$W/$CASE.restore.out"; fi
fingerprint >"$W/after"
check "invalid niri: after the restore every file is as before the update" diff -u "$W/before" "$W/after"
check "invalid niri: repository back on v1" head_is "$V1"

# ── 4. niri is not installed: the update cannot be confirmed ─────────────────
new_case niri-missing
v2_edits
publish v2
update NIRI_BIN=/nonexistent/niri
check "niri missing: exit 12, FAILED niri-missing, no UPDATED" \
  bash -c "[[ $RC == 12 ]] && grep -q '^FAILED niri-missing ' '$W/$CASE.out' && ! grep -q '^UPDATED ' '$W/$CASE.out'"

# ── 5. the snapshot cannot be written: nothing may change ────────────────────
new_case snapshot-fails
v2_edits
publish v2
rm -rf -- "$STATE/backups"
echo 'not a folder' >"$STATE/backups"
fingerprint >"$W/before"
update
if ((RC == 5)); then pass "snapshot failure: exit 5"; else fail "snapshot failure: exit $RC (want 5)"; show "$W/$CASE.out"; fi
check "snapshot failure: FAILED snapshot, no UPDATED, no BACKUP" \
  bash -c "grep -q '^FAILED snapshot ' '$W/$CASE.out' && ! grep -q '^UPDATED ' '$W/$CASE.out' && ! grep -q '^BACKUP ' '$W/$CASE.out'"
fingerprint >"$W/after"
check "snapshot failure: no installed file changed" diff -q "$W/before" "$W/after"
check "snapshot failure: repository not moved" head_is "$V1"

# ── 6. restores that fail keep the snapshot ──────────────────────────────────
new_case restore-fails
v2_edits
sed -i 's/^install_configs$/install_configs\nfalse/' "$W/work/install.sh"
publish "v2 with a broken installer"
update
copy="$BACKUP/files$H/$QML_FILE"
mv "$copy" "$W/saved-copy"
fingerprint >"$W/mid"
restore "$BACKUP"
check "damaged snapshot: restore refused (exit 4, RESTORE-FAILED backup-corrupt)" \
  bash -c "[[ $RC == 4 ]] && grep -q '^RESTORE-FAILED backup-corrupt ' '$W/$CASE.restore.out'"
fingerprint >"$W/after"
check "damaged snapshot: nothing touched, snapshot still there" \
  bash -c "diff -q '$W/mid' '$W/after' >/dev/null && [[ -f '$BACKUP/meta.json' ]] && [[ \$(python3 -c 'import json;print(json.load(open(\"$BACKUP/meta.json\"))[\"status\"])') == failed ]]"
mv "$W/saved-copy" "$copy"
echo '// NIRI-INVALID' >>"$H/.config/niri/cfg/input.kdl"     # broken by hand, not by the update
restore "$BACKUP"
check "niri broken after restore: exit 6, RESTORE-FAILED niri" \
  bash -c "[[ $RC == 6 ]] && grep -q '^RESTORE-FAILED niri ' '$W/$CASE.restore.out'"
check "niri broken after restore: snapshot and the pre-restore copy kept, status restore-failed" \
  bash -c "[[ -f '$BACKUP/meta.json' ]] && compgen -G '$BACKUP/restore-*/plan.json' >/dev/null &&
           [[ \$(python3 -c 'import json;print(json.load(open(\"$BACKUP/meta.json\"))[\"status\"])') == restore-failed ]]"
sed -i '/NIRI-INVALID/d' "$H/.config/niri/cfg/input.kdl"
restore "$BACKUP"
check "restore after fixing niri: exit 0, repository back on v1" bash -c "[[ $RC == 0 ]] && [[ \$(git -C '$REPO' rev-parse HEAD) == $V1 ]]"

# ── 7. Settings → Updates reads the results right ────────────────────────────
if [[ "${UPDATE_UI:-1}" == 0 ]]; then
  skip "UI (UPDATE_UI=0)"
elif bash "$SHELL_SRC/tests/updates/run.sh" "$SHELL_SRC" >"$W/ui.out" 2>&1; then
  sed 's/^/  /' "$W/ui.out"
  pass "UI: Settings → Updates handles failure, restore and success"
else
  code=$?
  sed 's/^/  /' "$W/ui.out"
  if ((code == 77)) && [[ "${REQUIRE_UI:-0}" != 1 ]]; then skip "UI (quickshell is not installed)"; else fail "UI: Settings → Updates (exit $code)"; fi
fi

if ((failures)); then
  printf '[update] %d check(s) failed\n' "$failures" >&2
  exit 1
fi
printf '[update] all checks passed\n'
