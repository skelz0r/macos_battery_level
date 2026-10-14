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
}
