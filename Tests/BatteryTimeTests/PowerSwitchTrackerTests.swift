import Foundation
import Testing

@testable import BatteryTime

struct PowerSwitchTrackerTests {
    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("The power source found at launch has no known switch date")
    func sourceAtLaunch() {
        var tracker = PowerSwitchTracker()
        tracker.observe(.battery, at: launch)
        #expect(tracker.switchDate == nil)
    }

    @Test("Plugging in the charger dates the switch to the moment it is noticed")
    func pluggingIn() {
        var tracker = PowerSwitchTracker()
        tracker.observe(.battery, at: launch)
        tracker.observe(.powerAdapter, at: launch + 600)
        #expect(tracker.switchDate == launch + 600)
    }

    @Test("Seeing the same power source again keeps the switch date")
    func sameSource() {
        var tracker = PowerSwitchTracker()
        tracker.observe(.battery, at: launch)
        tracker.observe(.powerAdapter, at: launch + 600)
        tracker.observe(.powerAdapter, at: launch + 900)
        #expect(tracker.switchDate == launch + 600)
    }

    @Test("Losing track of the power source forgets the date, so another source never shows it")
    func unknownSource() {
        var tracker = PowerSwitchTracker()
        tracker.observe(.battery, at: launch)
        tracker.observe(.powerAdapter, at: launch + 600)
        tracker.observe(nil, at: launch + 900)
        tracker.observe(.battery, at: launch + 1200)
        #expect(tracker.switchDate == nil)
    }

    @Test("A switch read from the log dates the power source found at launch")
    func recalledFromLog() {
        var tracker = PowerSwitchTracker()
        tracker.observe(.battery, at: launch)
        tracker.recall(launch - 3600, loggedFor: .battery)
        #expect(tracker.switchDate == launch - 3600)
    }

    @Test("A switch noticed while the log was being read wins over the log")
    func noticedBeforeLogWasRead() {
        var tracker = PowerSwitchTracker()
        tracker.observe(.battery, at: launch)
        tracker.observe(.powerAdapter, at: launch + 2)
        tracker.observe(.battery, at: launch + 3)
        tracker.recall(launch - 3600, loggedFor: .battery)
        #expect(tracker.switchDate == launch + 3)
    }

    @Test("A switch read from the log for a source no longer providing power is ignored")
    func loggedForAnotherSource() {
        var tracker = PowerSwitchTracker()
        tracker.observe(.battery, at: launch)
        tracker.observe(nil, at: launch + 2)
        tracker.observe(.powerAdapter, at: launch + 3)
        tracker.recall(launch - 3600, loggedFor: .battery)
        #expect(tracker.switchDate == nil)
    }
}
