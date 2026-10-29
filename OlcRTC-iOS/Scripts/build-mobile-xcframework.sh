#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor"
FRAMEWORK_DIR="$ROOT_DIR/Frameworks"
OLCRTC_DIR="$VENDOR_DIR/olcrtc"
OLCRTC_REPO="${OLCRTC_REPO:-https://github.com/alananisimov/olcrtc}"
OLCRTC_REF="${OLCRTC_REF:-bfa6d73}"

mkdir -p "$VENDOR_DIR" "$FRAMEWORK_DIR"

if [[ ! -d "$OLCRTC_DIR/.git" ]]; then
  git clone --branch refactor/universal-carrier "$OLCRTC_REPO" "$OLCRTC_DIR"
fi
git -C "$OLCRTC_DIR" checkout -f "$OLCRTC_REF"
git -C "$OLCRTC_DIR" submodule update --init --recursive

pushd "$OLCRTC_DIR" >/dev/null
echo "Using olcRTC $(git rev-parse --short HEAD) from $OLCRTC_REPO"
for patch_file in "$ROOT_DIR"/Patches/*.patch; do
  [[ -e "$patch_file" ]] || continue
  echo "Applying $(basename "$patch_file")"
  git apply --check "$patch_file"
  git apply "$patch_file"
done
gomobile bind -target=ios -o "$FRAMEWORK_DIR/Mobile.xcframework" ./mobile
popd >/dev/null

echo "Built $FRAMEWORK_DIR/Mobile.xcframework"
