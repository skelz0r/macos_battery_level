import Foundation
import Testing

@testable import BatteryTime

struct MenuBarTitleTests {
    @Test("On battery shows a battery and the time remaining")
    func onBattery() throws {
        #expect(try title(forFixture: "on_battery") == "🔋5:12")
    }

    @Test("On battery while macOS is still estimating shows a battery and dots")
    func onBatteryWithoutEstimate() throws {
        #expect(try title(forFixture: "on_battery_no_estimate") == "🔋...")
    }

    @Test("Charging shows a bolt and the time until full")
    func charging() throws {
        #expect(try title(forFixture: "charging") == "⚡1:23")
    }

    @Test("Charging while macOS is still estimating shows a bolt and dots")
    func chargingWithoutEstimate() throws {
        #expect(try title(forFixture: "charging_no_estimate") == "⚡...")
    }

    @Test("Fully charged shows a bolt only")
    func charged() throws {
        #expect(try title(forFixture: "charged") == "⚡")
    }

    @Test("Plugged in but not charging shows a bolt only")
    func pluggedInNotCharging() throws {
        #expect(try title(forFixture: "ac_attached_not_charging") == "⚡")
    }

    @Test("A Mac without battery says so, without battery icon")
    func desktopWithoutBattery() throws {
        #expect(try title(forFixture: "desktop_no_battery") == "No battery")
    }

    private func title(forFixture name: String) throws -> String {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures"))
        let output = try String(contentsOf: url, encoding: .utf8)
        return BatteryMonitor.parse(output).menuBarTitle
    }
}
