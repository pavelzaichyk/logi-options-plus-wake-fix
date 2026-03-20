#!/usr/bin/env bash
set -euo pipefail

PLIST_LABEL="com.user.logi-wake-watcher"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
BINARY="$HOME/.local/bin/logi-wake-watcher"

echo "==> Unloading LaunchAgent..."
launchctl unload "$PLIST_DST" 2>/dev/null || true

echo "==> Removing files..."
rm -f "$PLIST_DST" "$BINARY"
sudo rm -f /etc/sudoers.d/logi-wake-watcher

echo "==> Done."
