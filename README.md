# Logi Options+ Wake Fix

Fixes a bug in **Logi Options+** on macOS where custom device settings (e.g. scroll direction override) revert to macOS defaults after:
- Waking the MacBook from sleep
- Switching back to your user via fast user switching

## The problem

After sleep/wake or a user switch, `logioptionsplus_agent` loses its connection to the hardware and stops applying your custom settings. Your mouse/keyboard falls back to macOS system defaults until you manually open the Logi Options+ app and wait for it to rediscover devices.

## The fix

A small background daemon (`logi-wake-watcher`) that listens for macOS workspace events and automatically restarts `logioptionsplus_agent` when needed:

- `NSWorkspace.didWakeNotification` — system woke from sleep
- `NSWorkspace.sessionDidBecomeActiveNotification` — user switched back to this session

The daemon is installed as a LaunchAgent so it starts automatically on login and stays running.

## Requirements

- macOS (tested on macOS 15 Sequoia)
- Logi Options+ installed
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
git clone https://github.com/pavelzaichyk/logi-options-plus-wake-fix.git
cd logi-options-wake-fix
bash install.sh
```

The script will:
1. Compile the Swift daemon with `swiftc`
2. Install the binary to `~/.local/bin/logi-wake-watcher`
3. Install and load the LaunchAgent from `~/Library/LaunchAgents/`

## Uninstall

```bash
bash uninstall.sh
```

## Verify it's working

Check that the daemon is running:
```bash
launchctl list | grep logi-wake
```

After your next sleep/wake or user switch, check the log:
```bash
cat ~/Library/Logs/logi-wake-watcher.log
```

You should see something like:
```
[2026-03-17 14:55:39 +0000] Event: session became active — restarting logioptionsplus_agent in 1s...
[2026-03-17 14:55:41 +0000] Restart complete (exit code: 0)
```

Logs are stored per-user in `~/Library/Logs/` and are also visible in **Console.app**.

## How it works

```
src/logi-wake-watcher.swift       — daemon source
com.user.logi-wake-watcher.plist  — LaunchAgent template
install.sh                        — compile + install
uninstall.sh                      — remove everything
```

The daemon calls `launchctl kickstart -k gui/<uid>/com.logi.cp-dev-mgr` which kills and restarts the Logi agent. A 1-second delay is added before the restart to let the session fully initialize. A 10-second debounce prevents double-restarts when multiple events fire at once.
