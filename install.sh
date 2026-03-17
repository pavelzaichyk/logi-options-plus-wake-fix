#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_DIR="$HOME/.local/bin"
BINARY="$BINARY_DIR/logi-wake-watcher"
PLIST_LABEL="com.user.logi-wake-watcher"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

echo "==> Compiling logi-wake-watcher..."
mkdir -p "$BINARY_DIR"
swiftc "$SCRIPT_DIR/src/logi-wake-watcher.swift" -o "$BINARY"
echo "    Binary: $BINARY"

echo "==> Installing LaunchAgent plist..."
sed "s|BINARY_PATH|$BINARY|g" "$SCRIPT_DIR/com.user.logi-wake-watcher.plist" > "$PLIST_DST"
echo "    Plist:  $PLIST_DST"

echo "==> Loading LaunchAgent..."
launchctl unload "$PLIST_DST" 2>/dev/null || true
launchctl load "$PLIST_DST"

echo "==> Done. Watching for wake/user-switch events."
echo "    Logs: /tmp/logi-wake-watcher.log"
echo "    Run 'launchctl list | grep logi-wake' to confirm it's running."
