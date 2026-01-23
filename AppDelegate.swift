import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let batteryMonitor = BatteryMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "..."
        }

        setupMenu()
        updateBatteryStatus()
        startTimer()
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
    }

    private func updateBatteryStatus() {
        let status = batteryMonitor.getStatus()

        var displayText: String
        if status.isFullyCharged {
            displayText = "⚡"
        } else if status.isCharging {
            displayText = "⚡\(status.timeString)"
        } else {
            displayText = "🔋\(status.timeString)"
        }

        DispatchQueue.main.async {
            self.statusItem.button?.title = displayText
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
