import Testing

@testable import BatteryTime

struct BatteryThresholdsTests {
    @Test("On battery, dropping to 20 % then to 10 % notifies once at each threshold")
    func dischargingThroughBothThresholds() {
        let crossings = crossings(from: discharging(25), through: (9...24).reversed().map(discharging))

        #expect(crossings == [.dischargedTo(20), .dischargedTo(10)])
    }

    @Test("While charging, reaching 80 % then 100 % notifies once at each threshold")
    func chargingThroughBothThresholds() {
        let crossings = crossings(from: charging(75), through: (76...99).map(charging) + [charged(100)])

        #expect(crossings == [.chargedTo(80), .chargedTo(100)])
    }

    @Test("Staying under 20 % on battery does not notify again")
    func stayingUnderLowThreshold() {
        let crossings = crossings(from: discharging(21), through: [discharging(20), discharging(19), discharging(20)])

        #expect(crossings == [.dischargedTo(20)])
    }

    @Test("Staying at 100 % on power does not notify again")
    func stayingFullyCharged() {
        let crossings = crossings(from: charging(99), through: [charged(100), charged(100), pluggedIn(100)])

        #expect(crossings == [.chargedTo(100)])
    }

    @Test("Charging back above 20 % then dropping under it again notifies again")
    func lowThresholdRearmsOnceRecrossed() {
        let crossings = crossings(
            from: discharging(21),
            through: [discharging(20), charging(20), charging(21), discharging(21), discharging(20)]
        )

        #expect(crossings == [.dischargedTo(20), .dischargedTo(20)])
    }

    @Test("Draining back under 80 % then charging past it again notifies again")
    func chargeThresholdRearmsOnceRecrossed() {
        let crossings = crossings(
            from: charging(79),
            through: [charging(80), discharging(80), discharging(79), charging(79), charging(80)]
        )

        #expect(crossings == [.chargedTo(80), .chargedTo(80)])
    }

    @Test("Launching the app already under a threshold does not notify")
    func launchingUnderThreshold() {
        let crossings = crossings(from: discharging(15), through: [discharging(15), discharging(14)])

        #expect(crossings.isEmpty)
    }

    @Test("Plugging in under 20 % does not notify for the low battery threshold")
    func pluggingInUnderLowThreshold() {
        let crossings = crossings(from: discharging(25), through: [charging(19)])

        #expect(crossings.isEmpty)
    }

    @Test("Skipping both low thresholds at once, after sleep, notifies only for 10 %")
    func skippingBothLowThresholds() {
        let crossings = crossings(from: discharging(25), through: [discharging(8)])

        #expect(crossings == [.dischargedTo(10)])
    }

    @Test("A failed battery reading neither notifies nor resets what was already notified")
    func failedReading() {
        let noReading = BatteryStatus(state: .noBattery, percentage: 0)
        let afterLowBattery = crossings(from: discharging(21), through: [discharging(20), noReading, discharging(19)])
        let whileCharged = crossings(from: charging(85), through: [noReading, charging(85)])

        #expect(afterLowBattery == [.dischargedTo(20)])
        #expect(whileCharged.isEmpty)
    }

    private func crossings(
        from initial: BatteryStatus,
        through statuses: [BatteryStatus]
    ) -> [BatteryThresholdCrossing] {
        var thresholds = BatteryThresholds(initialStatus: initial)
        return statuses.compactMap { thresholds.crossing(to: $0) }
    }

    private func discharging(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .discharging(remaining: "1:00"), percentage: percentage)
    }

    private func charging(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .charging(remaining: "1:00"), percentage: percentage)
    }

    private func charged(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .charged, percentage: percentage)
    }

    private func pluggedIn(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .pluggedInNotCharging, percentage: percentage)
    }
}
