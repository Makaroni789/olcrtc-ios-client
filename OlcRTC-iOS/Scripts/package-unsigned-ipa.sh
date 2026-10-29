#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${1:-}"
OUTPUT_DIR="$ROOT_DIR/build/ipa"
IPA_PATH="$OUTPUT_DIR/OlcRTCClient-unsigned.ipa"

if [[ -z "$APP_PATH" ]]; then
  APP_PATH="$(find "$ROOT_DIR/build/DerivedData/Build/Products/Release-iphoneos" -maxdepth 1 -name "OlcRTCClient.app" -type d | head -n 1)"
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "OlcRTCClient.app not found. Build the iphoneos Release app first." >&2
  exit 1
fi

# iOS frameworks must be flat: no Versions/ dir, no symlinks.
flatten_frameworks() {
  local root="$1"
  find "$root" -type d -name "*.framework" | while read -r fw; do
    [[ -d "$fw/Versions" ]] || continue
    local cur="$fw/Versions/Current"
    [[ -L "$cur" || -d "$cur" ]] || cur="$(find "$fw/Versions" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    local tmp; tmp="$(mktemp -d)"
    cp -RL "$cur/." "$tmp/"
    if [[ -f "$tmp/Resources/Info.plist" ]]; then
      mv "$tmp/Resources/Info.plist" "$tmp/Info.plist"
      cp -R "$tmp/Resources/." "$tmp/" 2>/dev/null || true
      rm -rf "$tmp/Resources"
    fi
    rm -rf "$fw"
    mkdir -p "$fw"
    cp -R "$tmp/." "$fw/"
    rm -rf "$tmp"
    echo "Flattened $fw"
  done
}

rm -rf "$OUTPUT_DIR/Payload" "$IPA_PATH"
mkdir -p "$OUTPUT_DIR/Payload"
cp -R "$APP_PATH" "$OUTPUT_DIR/Payload/"

flatten_frameworks "$OUTPUT_DIR/Payload"
find "$OUTPUT_DIR/Payload" -name "_CodeSignature" -type d -prune -exec rm -rf {} +
echo "Symlinks left: $(find "$OUTPUT_DIR/Payload" -type l | wc -l)"

pushd "$OUTPUT_DIR" >/dev/null
zip -qr "$IPA_PATH" Payload
popd >/dev/null

echo "$IPA_PATH"
