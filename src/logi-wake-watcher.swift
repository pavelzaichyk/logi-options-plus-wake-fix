import Cocoa
import Foundation

// Ensure stdout is unbuffered so logs appear immediately in the file
setbuf(stdout, nil)

let uid = getuid()
var lastRestartTime: Date = .distantPast
let minEventInterval: TimeInterval = 10

func restartLogiAgent(reason: String) {
    let now = Date()
    guard now.timeIntervalSince(lastRestartTime) > minEventInterval else {
        print("[\(now)] Skipping restart (debounce): \(reason)")
        return
    }
    lastRestartTime = now
    print("[\(now)] Event: \(reason) — restarting logioptionsplus_agent in 3s...")

    // Wait for USB/Bluetooth stack to settle
    Thread.sleep(forTimeInterval: 3)

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    task.arguments = ["kickstart", "-k", "gui/\(uid)/com.logi.cp-dev-mgr"]
    do {
        try task.run()
        task.waitUntilExit()
        print("[\(Date())] Restart complete (exit code: \(task.terminationStatus))")
    } catch {
        print("[\(Date())] Restart failed: \(error)")
    }
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
