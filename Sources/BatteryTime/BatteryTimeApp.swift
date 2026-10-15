import AppKit
import ServiceManagement
import SwiftUI

@main
struct BatteryTimeApp: App {
    @State private var model = BatteryPanelModel()

    var body: some Scene {
        MenuBarExtra {
            BatteryPanel(model: model)
        } label: {
            MenuBarLabel(status: model.batteryStatus)
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

    private(set) var batteryStatus: BatteryStatus {
        didSet { thresholdNotifier.batteryStatusDidChange(batteryStatus) }
    }
    private(set) var powerFlow: PowerFlow?
    private(set) var energyUse = EnergyUse.notMeasured
    private(set) var batteryHealth: BatteryHealth?
    private(set) var chargeHistory = ChargeHistory.load()
    private(set) var opensAtLogin = SMAppService.mainApp.status == .enabled
    @ObservationIgnored private var batteryMonitor: BatteryMonitor?
    @ObservationIgnored private var chargeHistoryTimer: Timer?
    private let thresholdNotifier: BatteryThresholdNotifier
    private var energyMeasurement: Task<Void, Never>?

    init() {
        let initialStatus = BatteryStatus(state: .unknown, percentage: 0)
        batteryStatus = initialStatus
        thresholdNotifier = BatteryThresholdNotifier(initialStatus: initialStatus)
        batteryMonitor = BatteryMonitor { [weak self] in
            self?.updateBatteryStatus()
        }
        updateBatteryStatus()
        chargeHistoryTimer = Timer.scheduledTimer(
            withTimeInterval: ChargeHistory.samplingInterval,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateBatteryStatus()
            }
        }
    }

    func panelDidOpen() {
        updateBatteryStatus()
        opensAtLogin = SMAppService.mainApp.status == .enabled
        batteryHealth = BatteryHealth.read()
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

    func toggleOpensAtLogin() {
        let loginItem = SMAppService.mainApp
        if opensAtLogin {
            try? loginItem.unregister()
        } else {
            try? loginItem.register()
        }
        if loginItem.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        opensAtLogin = loginItem.status == .enabled
    }

    private func updateBatteryStatus() {
        batteryStatus = BatteryMonitor.currentStatus()
        powerFlow = PowerMonitor.currentFlow()
        recordChargeHistory()
    }

    private func recordChargeHistory() {
        if chargeHistory.record(batteryStatus, at: .now) {
            chargeHistory.save()
        }
    }
}
