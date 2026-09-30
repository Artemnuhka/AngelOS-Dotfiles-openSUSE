#!/usr/bin/env bash
# angelOS UI self-test, offscreen (no compositor, no windows on screen; runs in CI):
#   every settings page in the simple view and in Expert, every preview scene,
#   settings search speed, the helper's sprite rig, a right click into a window's
#   corner pixel (the Qt crash RightClickGuard works around), plus static checks:
#   every window has a RightClickGuard, no "X is not a type", binding loops, JS
#   errors or missing images in the log.
#
#   scripts/test-ui.sh [angelOS dir]      exit 0 = all good
#   ANGELOS_TEST_LOG=file keeps the full log
set -uo pipefail
DIR="$(cd "${1:-"$(dirname "$0")/.."}" && pwd)"
[[ -f "$DIR/shell.qml" && -f "$DIR/tests/ui/Driver.qml" ]] || { echo "no angelOS in $DIR"; exit 2; }
fail=0
ok()  { printf '  ✓ %s\n' "$*"; }
bad() { printf '  ✕ %s\n' "$*"; fail=1; }

# quickshell: the system one, else the local copy angelOS installs into ~/.local/opt
QS="$(command -v quickshell || true)"
LIB="${LD_LIBRARY_PATH:-}" QML="${QML_IMPORT_PATH:-}"
if [[ ! -x /usr/bin/quickshell && -x "$HOME/.local/opt/quickshell/usr/bin/quickshell" ]]; then
  QS="$HOME/.local/opt/quickshell/usr/bin/quickshell"
  LIB="$HOME/.local/opt/quickshell/usr/lib${LIB:+:$LIB}"
  QML="$HOME/.local/opt/quickshell/usr/lib/qt6/qml${QML:+:$QML}"
fi
[[ -x "$QS" ]] || { echo "quickshell not found"; exit 2; }

echo "» angelOS UI self-test: $DIR"

# every top-level window guards its corner pixel against Qt's right-click crash
while IFS= read -r f; do
  grep -q 'RightClickGuard' "$f" || bad "no RightClickGuard in ${f#"$DIR"/} (a right click into its corner can crash Qt)"
done < <(grep -rlE '^\s*(PanelWindow|FloatingWindow|PopupWindow)\s*\{' --include='*.qml' "$DIR" | grep -v '/tests/')
((fail)) || ok "every window has a RightClickGuard"

# python helpers at least compile
if out=$(python3 -m py_compile "$DIR"/scripts/*.py 2>&1); then ok "scripts/*.py compile"; else bad "python: $out"; fi
find "$DIR/scripts" -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null

# a short runtime dir: Quickshell's IPC socket path must fit in 108 bytes
T="$(mktemp -d /tmp/aos-test.XXXXXX)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/home/.config/angelos" "$T/rt" "$T/root" && chmod 700 "$T/rt"

# The real shell.qml minus its screen windows (layer-shell needs a compositor):
# same imports, type anchors and service start-up, plus the test driver.
for f in "$DIR"/*; do [[ "${f##*/}" == shell.qml ]] || ln -s "$f" "$T/root/"; done
python3 - "$DIR/shell.qml" >"$T/root/shell.qml" <<'PY'
import re, sys
lines = [l for l in open(sys.argv[1]).read().splitlines() if not re.match(r"^    [A-Z][A-Za-z0-9]* \{\}\s*$", l)]
text = "\n".join(lines).rstrip()
text = text.replace("import qs.widgets", "import qs.widgets\nimport qs.tests.ui", 1)
print(text[:text.rfind("}")] + "    Driver {}\n}")
PY
# quiet, offline settings: no OBS, no sounds, no first-run jobs
cat >"$T/home/.config/angelos/settings.json" <<'JSON'
{"setup": {"complete": true}, "stream": {"auto": false}, "y2k": {"sounds": false, "helper": false, "boot": false},
 "bar": {"metaTap": false}, "updates": {"autoCheck": false}, "system": {"nautilusDefaults": true}}
JSON
log="${ANGELOS_TEST_LOG:-$T/qs.log}"
runner=()
command -v dbus-run-session >/dev/null && runner=(dbus-run-session --)
env -i PATH="$PATH" LANG=C.UTF-8 HOME="$T/home" USER="${USER:-angel}" \
  XDG_CONFIG_HOME="$T/home/.config" XDG_STATE_HOME="$T/home/.local/state" \
  XDG_CACHE_HOME="$T/home/.cache" XDG_DATA_HOME="$T/home/.local/share" XDG_RUNTIME_DIR="$T/rt" \
  QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= LD_LIBRARY_PATH="$LIB" QML_IMPORT_PATH="$QML" \
  ANGELOS_DEV=1 ANGELOS_SCREENS=__none__ ANGELOS_TEST=1 QS_NO_RELOAD_POPUP=1 QS_DISABLE_CRASH_HANDLER=1 \
  "${runner[@]}" timeout 150 "$QS" -p "$T/root" >"$log" 2>&1
code=$?

# results of the driver
sed -n 's/.*\(TEST \(PASS\|FAIL\|[a-z].*\)\)/\1/p' "$log" | grep -E '^TEST [^ ]+ (PASS|FAIL)' | while read -r _ name res detail; do
  if [[ "$res" == PASS ]]; then printf '  ✓ %s %s\n' "$name" "$detail"; else printf '  ✕ %s %s\n' "$name" "$detail"; fi
done
grep -qE 'TEST [^ ]+ FAIL' "$log" && fail=1
grep -q 'TEST DONE' "$log" || bad "the self-test did not finish (crash or hang, exit $code): $(tail -3 "$log" | tr '\n' ' ' | cut -c1-300)"

# errors in the log, with the page that was loading
errs=$(awk '/TEST-PAGE /{sub(/.*TEST-PAGE /,""); page=$0; next}
  /is not a type|Binding loop detected|TypeError|ReferenceError|Cannot assign|Unable to assign|is not defined|Cannot read property|Cannot call method|failed to load component|Error loading|Cannot open: file/ {
    line=$0; gsub(/\033\[[0-9;]*m/,"",line); print "[" (page==""?"startup":page) "] " substr(line,1,220) }' "$log" | sort -u)
if [[ -n "$errs" ]]; then
  bad "errors in the log:"; printf '%s\n' "$errs" | head -30 | sed 's/^/      /'
else
  ok "no QML errors, binding loops, JS exceptions or missing images"
fi

if ((fail)); then echo "» UI SELF-TEST FAILED"; exit 1; fi
echo "» UI self-test passed ♡"
