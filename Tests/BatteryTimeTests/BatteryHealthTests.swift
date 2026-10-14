import Testing

@testable import BatteryTime

struct BatteryHealthTests {
    @Test("Maximum capacity matches System Settings on an Apple Silicon Mac")
    func appleSiliconCapacity() throws {
        let health = try #require(
            BatteryHealth(properties: [
                "CycleCount": 140, "DesignCapacity": 4629, "NominalChargeCapacity": 4484,
                "AppleRawMaxCapacity": 4357, "MaxCapacity": 100, "PermanentFailureStatus": 0,
            ])
        )
        #expect(health.cycleCount == 140)
        #expect(health.maximumCapacity == 97)
        #expect(!health.needsService)
    }

    @Test("An Intel Mac without nominal charge capacity still shows its health")
    func intelWithoutNominalCapacity() throws {
        let health = try #require(
            BatteryHealth(properties: [
                "CycleCount": 70, "DesignCapacity": 4315, "AppleRawMaxCapacity": 3814, "MaxCapacity": 3814,
            ])
        )
        #expect(health.maximumCapacity == 88)
    }

    @Test("A battery just under 80 % capacity needs service even if displayed as 80 %")
    func justUnderServiceThreshold() throws {
        let health = try #require(
            BatteryHealth(properties: ["CycleCount": 900, "DesignCapacity": 5000, "NominalChargeCapacity": 3980])
        )
        #expect(health.maximumCapacity == 80)
        #expect(health.needsService)
    }
}
