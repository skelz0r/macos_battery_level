import Foundation
import Testing

@testable import BatteryTime

struct ChargeLimitTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Charge stopping at 79, 80, 80 then 83 % means an 80 % limit")
    func medianOfPlateaus() {
        var limit = ChargeLimit()
        for (day, percentage) in [79, 80, 80, 83].enumerated() {
            chargeStops(at: percentage, on: day, in: &limit)
        }

        #expect(limit.percentage == 80)
    }

    @Test("Charge stopping only a few minutes is not a plateau")
    func shortStop() {
        var limit = ChargeLimit()
        limit.observe(charging(84), at: start)
        limit.observe(pluggedInNotCharging(85), at: minutes(1))
        limit.observe(pluggedInNotCharging(85), at: minutes(6))
        limit.observe(charging(85), at: minutes(9))

        #expect(limit.percentage == nil)
    }

    @Test("A lone 83 % found when waking up, the app not running during sleep, does not change the limit")
    func valueFoundOnWake() {
        var limit = ChargeLimit()
        limit.observe(charging(60), at: start)
        limit.observe(pluggedInNotCharging(83), at: minutes(8 * 60))
        limit.observe(pluggedInNotCharging(83), at: minutes(8 * 60 + 5))
        limit.observe(pluggedInNotCharging(83), at: minutes(8 * 60 + 30))

        #expect(limit.percentage == nil)
    }

    @Test("A charge stop reached during a short sleep is not a plateau")
    func valueFoundAfterShortSleep() {
        var limit = ChargeLimit()
        limit.observe(charging(79), at: start)
        limit.systemWillSleep()
        limit.observe(pluggedInNotCharging(83), at: minutes(10))
        limit.observe(pluggedInNotCharging(83), at: minutes(15))
        limit.observe(pluggedInNotCharging(83), at: minutes(25))

        #expect(limit.percentage == nil)
    }

    @Test("Charging more than 3 points above the learned limit forgets it")
    func limitRaised() {
        var limit = ChargeLimit()
        chargeStops(at: 80, on: 0, in: &limit)
        limit.observe(charging(83), at: minutes(24 * 60))
        #expect(limit.percentage == 80)

        let aboveLimit = charging(84)
        limit.observe(aboveLimit, at: minutes(24 * 60 + 5))

        #expect(limit.percentage == nil)
    }

    private func chargeStops(at percentage: Int, on day: Int, in limit: inout ChargeLimit) {
        let morning = day * 24 * 60
        limit.observe(charging(percentage - 1), at: minutes(morning))
        limit.observe(pluggedInNotCharging(percentage), at: minutes(morning + 2))
        limit.observe(pluggedInNotCharging(percentage), at: minutes(morning + 7))
        limit.observe(pluggedInNotCharging(percentage), at: minutes(morning + 12))
    }

    private func charging(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .charging(remaining: "1:23"), percentage: percentage)
    }

    private func pluggedInNotCharging(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .pluggedInNotCharging, percentage: percentage)
    }

    private func minutes(_ count: Int) -> Date {
        start.addingTimeInterval(TimeInterval(count * 60))
    }
}
