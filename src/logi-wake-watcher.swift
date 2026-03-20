import Cocoa
import Foundation

// Ensure stdout is unbuffered so logs appear immediately in the file
setbuf(stdout, nil)

let uid = getuid()
var lastRestartTime: Date = .distantPast
let minEventInterval: TimeInterval = 10

func run(_ executable: String, _ arguments: [String]) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: executable)
    task.arguments = arguments
    do {
        try task.run()
        task.waitUntilExit()
        return task.terminationStatus
    } catch {
        print("[\(Date())] Failed to run \(executable): \(error)")
        return -1
    }
}

func restartLogiAgent(reason: String) {
    let now = Date()
    guard now.timeIntervalSince(lastRestartTime) > minEventInterval else {
        print("[\(now)] Skipping restart (debounce): \(reason)")
        return
    }
    lastRestartTime = now
    print("[\(now)] Event: \(reason) — restarting Logi services...")

    // Wait for USB/Bluetooth stack to settle
    Thread.sleep(forTimeInterval: 3)

    // Restart the system-level updater first — its stale IPC state blocks agent startup
    let updaterExit = run("/usr/bin/sudo", ["launchctl", "kickstart", "-k", "system/com.logi.optionsplus.updater"])
    print("[\(Date())] Updater restart (exit code: \(updaterExit))")

    // Give the updater a moment to come up before the agent tries to connect to it
    Thread.sleep(forTimeInterval: 2)

    // Restart the user agent
    let agentExit = run("/bin/launchctl", ["kickstart", "-k", "gui/\(uid)/com.logi.cp-dev-mgr"])
    print("[\(Date())] Agent restart (exit code: \(agentExit))")
}

let workspace = NSWorkspace.shared
let nc = workspace.notificationCenter

// System woke from sleep
nc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in
    DispatchQueue.global().async { restartLogiAgent(reason: "wake from sleep") }
}

// User switched back to this session (fast user switching)
nc.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: nil) { _ in
    DispatchQueue.global().async { restartLogiAgent(reason: "session became active") }
}

print("[\(Date())] logi-wake-watcher started (uid=\(uid), pid=\(ProcessInfo.processInfo.processIdentifier))")
RunLoop.main.run()
