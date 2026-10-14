import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum EnergyUse {
        case notMeasured
        case measuring
        case measured([EnergyHog])
    }

    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var timer: Timer?
    private let batteryMonitor = BatteryMonitor()
    private var batteryStatus: BatteryStatus?
    private var energyUse = EnergyUse.notMeasured
    private var energyMeasurement: Task<Void, Never>?

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
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        energyUse = .measuring
        updateMenu()
        energyMeasurement = Task { [weak self] in
            let hogs = await EnergyMeasurement().hogs()
            guard !Task.isCancelled else { return }
            self?.energyUse = .measured(hogs ?? [])
            self?.updateMenu()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        energyMeasurement?.cancel()
        energyMeasurement = nil
        energyUse = .notMeasured
    }

    private func updateMenu() {
        guard let menu = statusItem.menu, let status = batteryStatus else { return }
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
        addEnergySection(to: menu)
        menu.addItem(
            NSMenuItem(title: "Battery Settings...", action: #selector(openBatterySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    }

    private func addEnergySection(to menu: NSMenu) {
        switch energyUse {
        case .notMeasured, .measured([]):
            return
        case .measuring:
            let measuringItem = NSMenuItem(title: "Measuring energy use...", action: nil, keyEquivalent: "")
            measuringItem.isEnabled = false
            menu.addItem(measuringItem)
        case .measured(let hogs):
            let headerItem = NSMenuItem(title: "Using Significant Energy", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            menu.addItem(headerItem)
            for hog in hogs {
                let hogItem = NSMenuItem(title: hog.name, action: #selector(openActivityMonitor), keyEquivalent: "")
                hogItem.attributedTitle = energyHogTitle(hog)
                menu.addItem(hogItem)
            }
        }
        menu.addItem(NSMenuItem.separator())
    }

    private func energyHogTitle(_ hog: EnergyHog) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: 220)]
        return NSAttributedString(
            string: "\(hog.name)\t\(Int(hog.impact.rounded()))",
            attributes: [.paragraphStyle: paragraphStyle, .font: NSFont.menuFont(ofSize: 0)]
        )
    }

    @objc private func openActivityMonitor() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor")
        else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
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

        statusItem.button?.title = status.menuBarTitle
        batteryStatus = status
        updateMenu()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
