import Foundation
import IOKit

struct BatteryHealth {
    static let serviceCapacityThreshold = 0.8

    let cycleCount: Int
    let capacityRatio: Double
    let hasPermanentFailure: Bool

    var maximumCapacity: Int {
        min(100, Int((capacityRatio * 100).rounded()))
    }

    var needsService: Bool {
        hasPermanentFailure || capacityRatio < Self.serviceCapacityThreshold
    }

    static func read() -> Self? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
            let dictionary = properties?.takeRetainedValue() as? [String: Any]
        else { return nil }
        return Self(properties: dictionary)
    }

    init?(properties: [String: Any]) {
        guard let cycleCount = properties["CycleCount"] as? Int,
            let fullChargeCapacity = (properties["NominalChargeCapacity"] ?? properties["AppleRawMaxCapacity"]) as? Int,
            let designCapacity = properties["DesignCapacity"] as? Int,
            designCapacity > 0
        else { return nil }
        self.cycleCount = cycleCount
        capacityRatio = Double(fullChargeCapacity) / Double(designCapacity)
        hasPermanentFailure = (properties["PermanentFailureStatus"] as? Int ?? 0) != 0
    }
}
