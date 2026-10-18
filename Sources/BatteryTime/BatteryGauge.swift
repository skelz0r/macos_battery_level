import Foundation

struct BatteryGauge {
    let fullCapacity: Int
    let current: Int

    init(fullCapacity: Int, current: Int) {
        self.fullCapacity = fullCapacity
        self.current = current
    }

    init?(properties: [String: Any]) {
        guard let fullCapacity = properties["AppleRawMaxCapacity"] as? Int,
            let current = properties["Amperage"] as? Int
        else { return nil }
        self.init(fullCapacity: fullCapacity, current: current)
    }

    static func read() -> Self? {
        SmartBattery.properties().flatMap(Self.init(properties:))
    }

    func minutesToCharge(from percentage: Int, to target: Int) -> Int? {
        guard current > 0, target > percentage else { return nil }
        let missingCapacity = Double(fullCapacity * (target - percentage)) / 100
        return Int((missingCapacity / Double(current) * 60).rounded(.up))
    }
}
