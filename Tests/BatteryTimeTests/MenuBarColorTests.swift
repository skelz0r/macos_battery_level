import SwiftUI
import Testing

@testable import BatteryTime

struct MenuBarColorTests {
    @Test("On battery above 20 % the title keeps the menu bar color")
    func onBatteryAboveTwentyPercent() {
        #expect(onBattery(percentage: 21).menuBarColor == nil)
    }

    @Test("On battery at 20 % or less the title turns orange")
    func onBatteryAtTwentyPercent() {
        #expect(onBattery(percentage: 20).menuBarColor == .orange)
        #expect(onBattery(percentage: 11).menuBarColor == .orange)
    }

    @Test("On battery at 10 % or less the title turns red")
    func onBatteryAtTenPercent() {
        #expect(onBattery(percentage: 10).menuBarColor == .red)
    }

    @Test("Plugged in, a low battery keeps the menu bar color")
    func pluggedInWithLowBattery() {
        #expect(BatteryStatus(state: .charging(remaining: "1:23"), percentage: 5).menuBarColor == nil)
        #expect(BatteryStatus(state: .pluggedInNotCharging, percentage: 5).menuBarColor == nil)
    }

    private func onBattery(percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .discharging(remaining: "0:42"), percentage: percentage)
    }
}
