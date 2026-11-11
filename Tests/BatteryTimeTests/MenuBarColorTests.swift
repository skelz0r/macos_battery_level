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

    @Test("In Low Power Mode the title keeps the menu bar color, a badge shows it instead")
    func lowPowerModeAboveTwentyPercent() {
        #expect(onBattery(percentage: 21, isLowPowerMode: true).menuBarColor == nil)
        #expect(BatteryStatus(state: .charged, percentage: 100, isLowPowerMode: true).menuBarColor == nil)
    }

    @Test("In Low Power Mode a low battery still turns orange or red")
    func lowPowerModeWithLowBattery() {
        #expect(onBattery(percentage: 20, isLowPowerMode: true).menuBarColor == .orange)
        #expect(onBattery(percentage: 10, isLowPowerMode: true).menuBarColor == .red)
    }

    private func onBattery(percentage: Int, isLowPowerMode: Bool = false) -> BatteryStatus {
        BatteryStatus(state: .discharging(remaining: "0:42"), percentage: percentage, isLowPowerMode: isLowPowerMode)
    }
}
