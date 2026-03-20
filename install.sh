#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_DIR="$HOME/.local/bin"
BINARY="$BINARY_DIR/logi-wake-watcher"
PLIST_LABEL="com.user.logi-wake-watcher"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
LOG_DIR="$HOME/Library/Logs"
LOG_PATH="$LOG_DIR/logi-wake-watcher.log"
ERR_PATH="$LOG_DIR/logi-wake-watcher.err"

echo "==> Compiling logi-wake-watcher..."
mkdir -p "$BINARY_DIR"
swiftc "$SCRIPT_DIR/src/logi-wake-watcher.swift" -o "$BINARY"
echo "    Binary: $BINARY"

echo "==> Installing LaunchAgent plist..."
mkdir -p "$LOG_DIR"
sed -e "s|BINARY_PATH|$BINARY|g" \
    -e "s|LOG_PATH|$LOG_PATH|g" \
    -e "s|ERR_PATH|$ERR_PATH|g" \
    "$SCRIPT_DIR/com.user.logi-wake-watcher.plist" > "$PLIST_DST"
echo "    Plist:  $PLIST_DST"

echo "==> Configuring sudoers (allows daemon to restart the Logi updater service)..."
SUDOERS_FILE="/etc/sudoers.d/logi-wake-watcher"
echo "$(whoami) ALL=(root) NOPASSWD: /bin/launchctl kickstart -k system/com.logi.optionsplus.updater" \
    | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 440 "$SUDOERS_FILE"
echo "    Sudoers: $SUDOERS_FILE"

echo "==> Loading LaunchAgent..."
launchctl unload "$PLIST_DST" 2>/dev/null || true
launchctl load "$PLIST_DST"

echo "==> Done. Watching for wake/user-switch events."
echo "    Logs: $LOG_PATH"
echo "    Run 'launchctl list | grep logi-wake' to confirm it's running."
