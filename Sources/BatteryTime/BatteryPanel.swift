import AppKit
import SwiftUI

struct BatteryPanel: View {
    let model: BatteryPanelModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.batteryStatus.hasBattery {
                BatteryHeader(
                    status: model.batteryStatus,
                    powerFlow: model.powerFlow,
                    powerSwitchDate: model.powerSwitch.switchDate,
                    health: model.batteryHealth
                )
                ChargeHistoryChart(history: model.chargeHistory)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                PanelDivider()
            }
            EnergySection(energyUse: model.energyUse)
            PanelDivider()
            PanelRow(action: openBatterySettings) {
                Text("Battery Settings...")
            }
            PanelRow(action: quit) {
                Text("Quit BatteryTime")
                Spacer()
                Text("⌘Q")
                    .foregroundStyle(.secondary)
            }
            .keyboardShortcut("q")
        }
        .padding(.vertical, 6)
        .frame(width: 290)
        .background {
            WindowVisibilityObserver { isVisible in
                if isVisible {
                    model.panelDidOpen()
                } else {
                    model.panelDidClose()
                }
            }
        }
    }

    private func openBatterySettings() {
        closePanel()
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.battery") else { return }
        NSWorkspace.shared.open(url)
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

private struct WindowVisibilityObserver: NSViewRepresentable {
    let onChange: @MainActor (Bool) -> Void

    func makeNSView(context: Context) -> ObservingView {
        ObservingView(onChange: onChange)
    }

    func updateNSView(_ nsView: ObservingView, context: Context) {}

    final class ObservingView: NSView {
        private let onChange: @MainActor (Bool) -> Void
        private var observer: NSObjectProtocol?
        private var isVisible = false

        init(onChange: @escaping @MainActor (Bool) -> Void) {
            self.onChange = onChange
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            nil
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observer.map(NotificationCenter.default.removeObserver)
            guard let window else { return }
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didChangeOcclusionStateNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.reportVisibility()
                }
            }
            reportVisibility()
        }

        private func reportVisibility() {
            let windowIsVisible = window?.occlusionState.contains(.visible) ?? false
            guard windowIsVisible != isVisible else { return }
            isVisible = windowIsVisible
            onChange(windowIsVisible)
        }
    }
}

@MainActor
private func closePanel() {
    NSApplication.shared.keyWindow?.close()
}

@MainActor
private func openActivityMonitor() {
    closePanel()
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor")
    else { return }
    NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
}

private struct BatteryHeader: View {
    let status: BatteryStatus
    let powerFlow: PowerFlow?
    let powerSwitchDate: Date?
    let health: BatteryHealth?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Battery")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text("\(status.percentage) %")
                    .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                Spacer()
                if let detail = status.panelDetail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            ChargeBar(fraction: Double(status.percentage) / 100, color: status.chargeColor)
            if let powerFlow {
                TimelineView(.everyMinute) { context in
                    Text(powerFlow.panelLine(switchedAt: powerSwitchDate, now: context.date))
                }
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
            }
            if let health {
                HealthLine(health: health)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}

private struct HealthLine: View {
    let health: BatteryHealth

    var body: some View {
        HStack(spacing: 4) {
            Text("\(health.cycleCount) cycles · \(health.maximumCapacity) % max capacity ·")
            Text(health.needsService ? "Service" : "Normal")
                .foregroundStyle(health.needsService ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
        }
        .font(.system(size: 11).monospacedDigit())
        .foregroundStyle(.secondary)
    }
}

private struct ChargeBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.35))
                            .frame(height: 2)
                            .padding(.horizontal, 3)
                            .padding(.top, 1)
                    }
                    .shadow(color: color.opacity(0.6), radius: 5)
                    .frame(width: max(8, geometry.size.width * fraction))
            }
        }
        .frame(height: 8)
    }
}

private struct EnergySection: View {
    let energyUse: BatteryPanelModel.EnergyUse
    @State private var isOptionPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Using Significant Energy")
                Spacer()
                if case .measured(let hogs) = energyUse, !hogs.isEmpty {
                    Text("Impact")
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            switch energyUse {
            case .notMeasured, .measuring:
                SectionNote {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Measuring energy use...")
                }
            case .measured([]):
                SectionNote {
                    Text("No app is using significant energy")
                }
            case .measured(let hogs):
                ForEach(hogs, id: \.name) { hog in
                    let app = runningApplication(atPath: hog.appBundlePath)
                    PanelRow {
                        if let app, NSApp.currentEvent?.modifierFlags.contains(.option) == true {
                            closePanel()
                            app.terminate()
                        } else {
                            openActivityMonitor()
                        }
                    } content: {
                        Image(nsImage: app?.icon ?? NSWorkspace.shared.icon(for: .unixExecutable))
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text(hog.name)
                            .lineLimit(1)
                        Spacer()
                        Text(isOptionPressed && app != nil ? "Quit" : "\(Int(hog.impact.rounded()))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .help(app == nil ? "Open Activity Monitor" : "Open Activity Monitor, Option-click to quit")
                }
                .onAppear {
                    isOptionPressed = NSEvent.modifierFlags.contains(.option)
                }
            }
        }
        .onModifierKeysChanged(mask: .option) { _, keys in
            isOptionPressed = keys.contains(.option)
        }
    }

    private func runningApplication(atPath appBundlePath: String?) -> NSRunningApplication? {
        guard let appBundlePath else { return nil }
        return NSWorkspace.shared.runningApplications.first { $0.bundleURL?.path == appBundlePath }
    }
}

private struct SectionNote<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 6) {
            content
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .frame(height: 24)
    }
}

private struct PanelRow<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                content
            }
            .font(.system(size: 13))
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .background {
                if isHovered {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.quaternary)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 5)
        .onHover { isHovered = $0 }
    }
}

private struct PanelDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
    }
}

extension BatteryStatus {
    var hasBattery: Bool {
        if case .noBattery = state { false } else { true }
    }

    var panelDetail: String? {
        switch state {
        case .discharging("..."), .charging("..."):
            "Calculating..."
        case .discharging(let remaining):
            "\(remaining) remaining"
        case .charging(let remaining):
            "Charging, \(remaining) until full"
        case .pluggedInNotCharging:
            "Plugged in, not charging"
        case .charged:
            "Fully charged"
        case .noBattery, .unknown:
            nil
        }
    }

    var chargeColor: Color {
        switch state {
        case .charging, .charged, .pluggedInNotCharging:
            .green
        default:
            lowLevelColor ?? (ProcessInfo.processInfo.isLowPowerModeEnabled ? .yellow : .green)
        }
    }

    var lowLevelColor: Color? {
        switch percentage {
        case ...10: .red
        case ...20: .orange
        default: nil
        }
    }
}
