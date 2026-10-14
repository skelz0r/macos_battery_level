import Foundation
import Testing

@testable import BatteryTime

struct EnergyHogsTests {
    @Test("A process keeping a CPU core busy is listed with its energy impact")
    func busyProcess() throws {
        let hogs = try hogs(forFixture: "top_power_with_load")
        #expect(hogs.contains(EnergyHog(name: "yes", impact: 45.4)))
    }

    @Test("Processes below an impact of 20 are left out")
    func belowThreshold() throws {
        let names = try hogs(forFixture: "top_power_without_load").map(\.name)
        #expect(names == ["fseventsd", "mds_stores", "PerfPowerService", "tailwindcss"])
    }

    @Test("At most five processes are listed, the most energy hungry first")
    func heaviestFive() throws {
        let names = try hogs(forFixture: "top_power_with_load").map(\.name)
        #expect(names == ["node", "fseventsd", "mds_stores", "PerfPowerService", "yes"])
    }

    @Test("Processes sharing a name add up their impact")
    func sameNameProcesses() throws {
        let node = try #require(try hogs(forFixture: "top_power_with_load").first { $0.name == "node" })
        #expect(abs(node.impact - 101.8) < 0.01)
    }

    private func hogs(forFixture name: String) throws -> [EnergyHog] {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures"))
        let output = try String(contentsOf: url, encoding: .utf8)
        return EnergyMonitor.hogs(fromTopOutput: output)
    }
}
