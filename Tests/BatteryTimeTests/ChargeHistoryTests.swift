import Foundation
import Testing

@testable import BatteryTime

struct ChargeHistoryTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A sample is kept at most every five minutes while nothing changes")
    func samplingInterval() {
        var history = ChargeHistory()
        history.record(onBattery(80), at: start)
        history.record(onBattery(80), at: minutes(4))
        history.record(onBattery(80), at: minutes(5))

        #expect(history.samples.map(\.date) == [start, minutes(5)])
    }

    @Test("A change of percentage or power source is recorded right away")
    func changesAreRecorded() {
        var history = ChargeHistory()
        history.record(onBattery(80), at: start)
        history.record(onBattery(79), at: minutes(1))
        history.record(charging(79), at: minutes(2))

        #expect(history.samples.count == 3)
    }

    @Test("Samples older than 24 hours are forgotten")
    func expiry() {
        var history = ChargeHistory()
        history.record(onBattery(80), at: start)
        history.record(onBattery(60), at: minutes(24 * 60 + 1))

        #expect(history.samples.map(\.percentage) == [60])
    }

    @Test("After a day without the app running, the curve is empty")
    func staleHistory() {
        var history = ChargeHistory()
        history.record(onBattery(80), at: start)

        #expect(history.segments(until: minutes(25 * 60)).isEmpty)
    }

    @Test("A Mac without battery records nothing")
    func noBattery() {
        var history = ChargeHistory()
        history.record(BatteryStatus(state: .noBattery, percentage: 0), at: start)

        #expect(history.samples.isEmpty)
    }

    @Test("The curve is cut where the app was not sampling, like during sleep or when it was not running")
    func gapsSplitTheCurve() {
        var history = ChargeHistory()
        history.record(onBattery(80), at: start)
        history.record(onBattery(78), at: minutes(10))
        history.record(onBattery(60), at: minutes(120))

        #expect(history.segments(until: minutes(120)).map { $0.map(\.percentage) } == [[80, 78], [60]])
    }

    @Test("Plugged-in periods span from plugging in to unplugging")
    func pluggedInPeriods() {
        var history = ChargeHistory()
        history.record(onBattery(30), at: start)
        history.record(charging(31), at: minutes(1))
        history.record(charging(35), at: minutes(6))
        history.record(onBattery(40), at: minutes(11))

        #expect(history.pluggedInPeriods(until: minutes(11)) == [minutes(1)...minutes(11)])
    }

    @Test("When the clock is set back, samples now in the future are forgotten and sampling goes on")
    func clockSetBack() {
        var history = ChargeHistory()
        history.record(charging(80), at: minutes(60))
        history.record(charging(80), at: minutes(0))
        history.record(charging(81), at: minutes(1))

        #expect(history.samples.map(\.date) == [minutes(0), minutes(1)])
        #expect(history.pluggedInPeriods(until: minutes(1)) == [minutes(0)...minutes(1)])
    }

    @Test("The history survives a restart of the app")
    func persistence() throws {
        let defaults = try #require(UserDefaults(suiteName: "ChargeHistoryTests"))
        defer { defaults.removePersistentDomain(forName: "ChargeHistoryTests") }
        var history = ChargeHistory()
        history.record(onBattery(80), at: start)
        history.save(to: defaults)

        #expect(ChargeHistory.load(from: defaults) == history)
    }

    private func minutes(_ count: Double) -> Date {
        start.addingTimeInterval(count * 60)
    }

    private func onBattery(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .discharging(remaining: "3:00"), percentage: percentage)
    }

    private func charging(_ percentage: Int) -> BatteryStatus {
        BatteryStatus(state: .charging(remaining: "1:00"), percentage: percentage)
    }
}
