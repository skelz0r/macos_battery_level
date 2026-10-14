import AppKit
import SwiftUI

@main
struct BatteryTimeApp: App {
    @State private var model = BatteryPanelModel()
    @AppStorage(TitleDisplay.defaultsKey) private var titleDisplay = TitleDisplay.time

    var body: some Scene {
        MenuBarExtra {
            BatteryPanel(model: model)
        } label: {
            Text(model.batteryStatus.menuBarTitle(showing: titleDisplay))
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
    private(set) var powerFlow: PowerFlow?
    private(set) var energyUse = EnergyUse.notMeasured
    @ObservationIgnored private var batteryMonitor: BatteryMonitor?
    private var energyMeasurement: Task<Void, Never>?

    init() {
        batteryStatus = BatteryStatus(state: .unknown, percentage: 0)
        batteryMonitor = BatteryMonitor { [weak self] in
            self?.updateBatteryStatus()
        }
        updateBatteryStatus()
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
        batteryStatus = BatteryMonitor.currentStatus()
        powerFlow = PowerMonitor.currentFlow()
    }
}
