import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var timer: Timer?
    private let batteryMonitor = BatteryMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let button = statusItem.button {
            button.title = "..."
        }

        setupMenu()
        updateBatteryStatus()
        startTimer()
    }

    private func setupMenu() {
        let menu = NSMenu()
        statusItem.menu = menu
    }

    private func updateMenu(_ status: BatteryStatus) {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        let batteryItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        batteryItem.isEnabled = false
        let batteryView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 28))
        let titleLabel = NSTextField(labelWithString: "Battery")
        titleLabel.frame = NSRect(x: 14, y: 4, width: 100, height: 20)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let percentLabel = NSTextField(labelWithString: "\(status.percentage) %")
        percentLabel.frame = NSRect(x: 180, y: 4, width: 55, height: 20)
        percentLabel.font = NSFont.systemFont(ofSize: 13)
        percentLabel.alignment = .right
        batteryView.addSubview(titleLabel)
        batteryView.addSubview(percentLabel)
        batteryItem.view = batteryView

        menu.addItem(batteryItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Battery Settings...", action: #selector(openBatterySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    }

    @objc private func openBatterySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.battery") else { return }
        NSWorkspace.shared.open(url)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateBatteryStatus()
            }
        }
    }

    private func updateBatteryStatus() {
        let status = batteryMonitor.getStatus()

        let displayText =
            if status.isFullyCharged {
                "⚡"
            } else if status.isCharging {
                "⚡\(status.timeString)"
            } else {
                "🔋\(status.timeString)"
            }

        statusItem.button?.title = displayText
        updateMenu(status)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
