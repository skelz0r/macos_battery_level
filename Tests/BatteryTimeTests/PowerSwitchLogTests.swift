import Foundation
import Testing

@testable import BatteryTime

struct PowerSwitchLogTests {
    @Test("The charger was plugged in when the system first logged running on AC after running on battery")
    func pluggedIn() throws {
        let log = try pmsetLog()
        #expect(PowerSwitchLog.lastSwitch(to: .powerAdapter, inPmsetLog: log) == date("2026-10-16T09:26:37+02:00"))
    }

    @Test("The charger was unplugged when the system first logged running on battery after running on AC")
    func unplugged() throws {
        let log = try pmsetLog(upTo: "2026-10-16 09:26:37")
        #expect(PowerSwitchLog.lastSwitch(to: .battery, inPmsetLog: log) == date("2026-10-16T00:50:01+02:00"))
    }

    @Test("A switch the system has not logged yet stays unknown")
    func notLoggedYet() throws {
        let log = try pmsetLog()
        #expect(PowerSwitchLog.lastSwitch(to: .battery, inPmsetLog: log) == nil)
    }

    @Test("A log without any switch leaves it unknown, since it happened before the log begins")
    func beforeLogBegins() throws {
        let log = try pmsetLog(upTo: "2026-10-16 00:50:01")
        #expect(PowerSwitchLog.lastSwitch(to: .powerAdapter, inPmsetLog: log) == nil)
    }

    @Test("An app naming its power assertion after a power source does not count as a switch")
    func assertionNamedAfterSource() throws {
        let assertion =
            "2026-10-16 09:30:00 +0200 Assertions          \tPID 123(SomeApp) Created "
            + "PreventUserIdleSystemSleep \"Using Batt\" 00:00:00  id:0x1 [System: PrevIdle kDisp]"
        let log = try pmsetLog() + "\n" + assertion
        #expect(PowerSwitchLog.lastSwitch(to: .powerAdapter, inPmsetLog: log) == date("2026-10-16T09:26:37+02:00"))
    }

    private func pmsetLog(upTo timestamp: String? = nil) throws -> String {
        let url = try #require(
            Bundle.module.url(forResource: "pmset_log", withExtension: "txt", subdirectory: "Fixtures")
        )
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
        guard let timestamp else { return lines.joined(separator: "\n") }
        return lines.prefix { !$0.hasPrefix(timestamp) }.joined(separator: "\n")
    }

    private func date(_ text: String) -> Date? {
        try? Date(text, strategy: .iso8601)
    }
}
