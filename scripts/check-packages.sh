#!/usr/bin/env bash
# Check resolved installation manifests against the configured Tumbleweed repositories.
# Run on the target system after refresh and adding the shell repositories.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
flavour="$(python3 -c 'import sys; print("python%d%d" % sys.version_info[:2])')"
mapfile -t packages < <(cat "$ROOT/packages/zypper.txt" "$ROOT/packages/angelos-zypper.txt" \
  "$ROOT/packages/sddm-zypper.txt" "$ROOT/packages/tools-zypper.txt" | \
  grep -Ev '^[[:space:]]*(#|$)' | sed "s/@PYTHON@/$flavour/g" | sort -u)
packages+=(noctalia tesseract-ocr-traineddata-rus)
# A solver dry run verifies names AND dependencies together, without installing anything.
sudo zypper --non-interactive --no-refresh install --dry-run --no-recommends "${packages[@]}"
