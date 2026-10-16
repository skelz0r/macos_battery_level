import Foundation
import Testing

@testable import BatteryTime

struct PowerLineTests {
    @Test("On battery shows the power drawn, in watts with one decimal")
    func onBattery() {
        #expect(PowerFlow.drawingFromBattery(watts: 12.06).panelLine == "Using 12.1 W")
    }

    @Test("Plugged in shows the charger wattage and the port it is plugged into")
    func charger() {
        #expect(PowerFlow.charger(watts: 67, port: "USB-C").panelLine == "67W USB-C charger")
    }

    @Test("Plugged in on an unidentified port shows the charger wattage only")
    func chargerOnUnknownPort() {
        #expect(PowerFlow.charger(watts: 30, port: nil).panelLine == "30W charger")
    }

    @Test("After a switch to battery, shows when it happened and how long ago")
    func onBatterySinceSwitch() {
        let line = PowerFlow.drawingFromBattery(watts: 12.3)
            .panelLine(switchedAt: date("2026-10-16 14:32"), now: date("2026-10-16 15:44"), calendar: calendar)
        #expect(line == "Using 12.3 W · since 14:32 (1h 12m)")
    }

    @Test("After plugging in a charger, shows when it happened and how long ago")
    func chargerSinceSwitch() {
        let line = PowerFlow.charger(watts: 96, port: "USB-C")
            .panelLine(switchedAt: date("2026-10-16 15:30"), now: date("2026-10-16 15:44"), calendar: calendar)
        #expect(line == "96W USB-C charger · since 15:30 (14m)")
    }

    @Test("A switch on a previous day shows its weekday and the elapsed days and hours")
    func switchOnPreviousDay() {
        let line = PowerFlow.charger(watts: 96, port: nil)
            .panelLine(switchedAt: date("2026-10-14 09:05"), now: date("2026-10-16 15:44"), calendar: calendar)
        #expect(line == "96W charger · since Wed 09:05 (2d 6h)")
    }

    @Test("Without a known switch, the line only shows the power flow")
    func unknownSwitch() {
        let line = PowerFlow.drawingFromBattery(watts: 12.3).panelLine(switchedAt: nil, now: .now)
        #expect(line == "Using 12.3 W")
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .gmt
        return calendar
    }

    private func date(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text) ?? .distantPast
    }
}
