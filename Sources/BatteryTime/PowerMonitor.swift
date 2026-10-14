import Foundation
import IOKit
import IOKit.ps

enum PowerFlow: Equatable {
    case drawingFromBattery(watts: Double)
    case charger(watts: Int, port: String?)

    var panelLine: String {
        switch self {
        case .drawingFromBattery(let watts):
            String(format: "Using %.1f W", watts)
        case .charger(let watts, let port):
            ["\(watts)W", port, "charger"].compactMap(\.self).joined(separator: " ")
        }
    }
}

enum PowerMonitor {
    static func currentFlow() -> PowerFlow? {
        if let adapter = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any] {
            guard let watts = adapter[kIOPSPowerAdapterWattsKey] as? Int else { return nil }
            return .charger(watts: watts, port: chargingPort())
        }
        let batteryService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("AppleSmartBattery"))
        guard let battery = properties(of: batteryService),
            let millivolts = battery["Voltage"] as? Int,
            let milliamps = battery["InstantAmperage"] as? Int,
            milliamps < 0
        else { return nil }
        return .drawingFromBattery(watts: Double(millivolts * -milliamps) / 1_000_000)
    }

    private static func chargingPort() -> String? {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOPortFeaturePowerSource")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        while case let service = IOIteratorNext(iterator), service != 0 {
            if let source = properties(of: service), source["WinningPowerSourceOption"] != nil {
                return source["ParentPortTypeDescription"] as? String
            }
        }
        return nil
    }

    private static func properties(of service: io_service_t) -> [String: Any]? {
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS else {
            return nil
        }
        return properties?.takeRetainedValue() as? [String: Any]
    }
}
