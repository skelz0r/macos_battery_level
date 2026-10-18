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

    func panelLine(switchedAt switchDate: Date?, now: Date, calendar: Calendar = .current) -> String {
        guard let switchDate else { return panelLine }
        return "\(panelLine) · since \(Self.clockTime(of: switchDate, now: now, calendar: calendar))"
            + " (\(Self.elapsedTime(from: switchDate, to: now)))"
    }

    private static func clockTime(of date: Date, now: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let time = String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
        guard !calendar.isDate(date, inSameDayAs: now), let weekday = components.weekday else { return time }
        return "\(calendar.shortWeekdaySymbols[weekday - 1]) \(time)"
    }

    private static func elapsedTime(from start: Date, to end: Date) -> String {
        let minutes = max(0, Int(end.timeIntervalSince(start)) / 60)
        switch minutes {
        case ..<60: return "\(minutes)m"
        case ..<(24 * 60): return "\(minutes / 60)h \(minutes % 60)m"
        default: return "\(minutes / (24 * 60))d \(minutes / 60 % 24)h"
        }
    }
}

enum PowerSource: Equatable {
    case battery
    case powerAdapter
}

enum PowerMonitor {
    static func currentSource() -> PowerSource? {
        switch IOPSGetProvidingPowerSourceType(nil)?.takeUnretainedValue() as String? {
        case kIOPSBatteryPowerValue: .battery
        case kIOPSACPowerValue: .powerAdapter
        default: nil
        }
    }

    static func currentFlow() -> PowerFlow? {
        if let adapter = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any] {
            guard let watts = adapter[kIOPSPowerAdapterWattsKey] as? Int else { return nil }
            return .charger(watts: watts, port: chargingPort())
        }
        guard let battery = SmartBattery.properties(),
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
