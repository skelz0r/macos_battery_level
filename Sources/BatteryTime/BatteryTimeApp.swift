import AppKit
import SwiftUI

@main
struct BatteryTimeApp: App {
    @State private var model = BatteryPanelModel()

    var body: some Scene {
        MenuBarExtra {
            BatteryPanel(model: model)
        } label: {
            Text(model.batteryStatus.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
@Observable
final class BatteryPanelModel {
    enum EnergyUse {
        case notMeasured
        case measuring
        case measured([EnergyHog])
    }

    private(set) var batteryStatus: BatteryStatus
    private(set) var energyUse = EnergyUse.notMeasured
    private let batteryMonitor = BatteryMonitor()
    private var timer: Timer?
    private var energyMeasurement: Task<Void, Never>?

    init() {
        batteryStatus = batteryMonitor.getStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateBatteryStatus()
            }
        }
    }

    func panelDidOpen() {
        updateBatteryStatus()
        energyUse = .measuring
        energyMeasurement?.cancel()
        energyMeasurement = Task { [weak self] in
            let hogs = await EnergyMeasurement().hogs()
            guard !Task.isCancelled else { return }
            self?.energyUse = .measured(hogs ?? [])
        }
    }

    func panelDidClose() {
        energyMeasurement?.cancel()
        energyMeasurement = nil
        energyUse = .notMeasured
    }

    private func updateBatteryStatus() {
        batteryStatus = batteryMonitor.getStatus()
    }
}
