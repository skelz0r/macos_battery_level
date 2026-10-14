import IOKit.ps
import Testing

@testable import BatteryTime

struct MenuBarTitleTests {
    @Test("On battery shows a battery and the time remaining")
    func onBattery() {
        #expect(title(of: battery(on: kIOPSBatteryPowerValue, [kIOPSTimeToEmptyKey: 312])) == "🔋5:12")
    }

    @Test("On battery while macOS is still estimating shows a battery and dots")
    func onBatteryWithoutEstimate() {
        #expect(title(of: battery(on: kIOPSBatteryPowerValue, [kIOPSTimeToEmptyKey: -1])) == "🔋...")
    }

    @Test("Charging shows a bolt and the time until full")
    func charging() {
        let charging = battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: true, kIOPSTimeToFullChargeKey: 83])
        #expect(title(of: charging) == "⚡1:23")
    }

    @Test("Charging while macOS is still estimating shows a bolt and dots")
    func chargingWithoutEstimate() {
        let charging = battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: true, kIOPSTimeToFullChargeKey: -1])
        #expect(title(of: charging) == "⚡...")
    }

    @Test("Fully charged shows a bolt only")
    func charged() {
        let charged = battery(on: kIOPSACPowerValue, [kIOPSIsChargedKey: true, kIOPSIsChargingKey: false])
        #expect(title(of: charged) == "⚡")
    }

    @Test("Plugged in but not charging shows a bolt only")
    func pluggedInNotCharging() {
        #expect(title(of: battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: false])) == "⚡")
    }

    @Test("A Mac without battery says so, without battery icon")
    func desktopWithoutBattery() {
        #expect(BatteryMonitor.status(fromPowerSources: []).menuBarTitle(showing: .time) == "No battery")
    }

    private func battery(on powerSource: String, _ details: [String: Any]) -> [String: Any] {
        [
            kIOPSTypeKey: kIOPSInternalBatteryType,
            kIOPSPowerSourceStateKey: powerSource,
            kIOPSCurrentCapacityKey: 54,
            kIOPSMaxCapacityKey: 100,
        ].merging(details) { _, detail in detail }
    }

    private func title(of battery: [String: Any]) -> String {
        BatteryMonitor.status(fromPowerSources: [battery]).menuBarTitle(showing: .time)
    }
}
