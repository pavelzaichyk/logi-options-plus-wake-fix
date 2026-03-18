import Cocoa
import Foundation

// Ensure stdout is unbuffered so logs appear immediately in the file
setbuf(stdout, nil)

let uid = getuid()
var lastRestartTime: Date = .distantPast
let minEventInterval: TimeInterval = 30

func kickAgent(label: String) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    task.arguments = ["kickstart", "-k", "gui/\(uid)/com.logi.cp-dev-mgr"]
    do {
        try task.run()
        task.waitUntilExit()
        print("[\(Date())] [\(label)] Restart complete (exit code: \(task.terminationStatus))")
    } catch {
        print("[\(Date())] [\(label)] Restart failed: \(error)")
    }
}

func restartLogiAgent(reason: String) {
    let now = Date()
    guard now.timeIntervalSince(lastRestartTime) > minEventInterval else {
        print("[\(now)] Skipping restart (debounce): \(reason)")
        return
    }
    lastRestartTime = now
    print("[\(now)] Event: \(reason) — starting two-phase restart...")

    // Phase 1: restart after 3s (lets USB/Bluetooth stack settle)
    Thread.sleep(forTimeInterval: 3)
    kickAgent(label: "1st")

    // Phase 2: restart again after 30s (safety net for full device re-initialization)
    Thread.sleep(forTimeInterval: 30)
    kickAgent(label: "2nd")
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
