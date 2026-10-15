import IOKit.ps
import Testing

@testable import BatteryTime

struct MenuBarTitleTests {
    @Test("On battery shows the time remaining")
    func onBattery() {
        #expect(title(of: battery(on: kIOPSBatteryPowerValue, [kIOPSTimeToEmptyKey: 312])) == "5:12")
    }

    @Test("On battery while macOS is still estimating shows dots")
    func onBatteryWithoutEstimate() {
        #expect(title(of: battery(on: kIOPSBatteryPowerValue, [kIOPSTimeToEmptyKey: -1])) == "...")
    }

    @Test("Charging shows the time until full")
    func charging() {
        let charging = battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: true, kIOPSTimeToFullChargeKey: 83])
        #expect(title(of: charging) == "1:23")
    }

    @Test("Charging while macOS is still estimating shows dots")
    func chargingWithoutEstimate() {
        let charging = battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: true, kIOPSTimeToFullChargeKey: -1])
        #expect(title(of: charging) == "...")
    }

    @Test("Fully charged shows no text")
    func charged() {
        let charged = battery(on: kIOPSACPowerValue, [kIOPSIsChargedKey: true, kIOPSIsChargingKey: false])
        #expect(title(of: charged).isEmpty)
    }

    @Test("Plugged in but not charging shows no text")
    func pluggedInNotCharging() {
        #expect(title(of: battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: false])).isEmpty)
    }

    @Test("Plugged in, charging or not, shows a battery with a bolt")
    func pluggedInSymbol() {
        let pluggedIn = [
            battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: true, kIOPSTimeToFullChargeKey: 83]),
            battery(on: kIOPSACPowerValue, [kIOPSIsChargedKey: true, kIOPSIsChargingKey: false]),
            battery(on: kIOPSACPowerValue, [kIOPSIsChargingKey: false]),
        ]
        let symbols = pluggedIn.map { BatteryMonitor.status(fromPowerSources: [$0]).menuBarBatterySymbol }
        #expect(symbols == Array(repeating: "battery.100percent.bolt", count: 3))
    }

    @Test("A Mac without battery says so, without battery icon")
    func desktopWithoutBattery() {
        #expect(BatteryMonitor.status(fromPowerSources: []).menuBarTitle == "No battery")
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
        BatteryMonitor.status(fromPowerSources: [battery]).menuBarTitle
    }
}
