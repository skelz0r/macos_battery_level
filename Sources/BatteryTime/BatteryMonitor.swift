import Foundation
import IOKit.ps

struct BatteryStatus {
    enum State {
        case discharging(remaining: String)
        case charging(remaining: String)
        case pluggedInNotCharging
        case charged
        case noBattery
        case unknown
    }

    let state: State
    let percentage: Int

    func menuBarTitle(showing display: TitleDisplay) -> String {
        switch state {
        case .discharging(let remaining):
            "🔋\(details(remaining: remaining, showing: display))"
        case .charging(let remaining):
            "⚡\(details(remaining: remaining, showing: display))"
        case .pluggedInNotCharging, .charged:
            display == .time ? "⚡" : "⚡\(percentage)%"
        case .noBattery:
            "No battery"
        case .unknown:
            "—"
        }
    }

    private func details(remaining: String, showing display: TitleDisplay) -> String {
        switch display {
        case .time:
            remaining
        case .percentage:
            "\(percentage)%"
        case .both:
            "\(remaining) \(percentage)%"
        }
    }
}

enum TitleDisplay: String {
    case time
    case percentage
    case both
}

@MainActor
final class BatteryMonitor {
    private let onChange: () -> Void
    private var runLoopSource: CFRunLoopSource?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        let context = Unmanaged.passUnretained(self).toOpaque()
        let notification = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context else { return }
                let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
                MainActor.assumeIsolated {
                    monitor.onChange()
                }
            }, context)
        guard let source = notification?.takeRetainedValue() else { return }
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }

    isolated deinit {
        if let runLoopSource {
            CFRunLoopSourceInvalidate(runLoopSource)
        }
    }

    nonisolated static func currentStatus() -> BatteryStatus {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return BatteryStatus(state: .unknown, percentage: 0)
        }
        let descriptions = sources.compactMap {
            IOPSGetPowerSourceDescription(snapshot, $0)?.takeUnretainedValue() as? [String: Any]
        }
        return status(fromPowerSources: descriptions)
    }

    nonisolated static func status(fromPowerSources descriptions: [[String: Any]]) -> BatteryStatus {
        guard
            let battery = descriptions.first(where: {
                $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
            })
        else {
            return BatteryStatus(state: .noBattery, percentage: 0)
        }

        let capacity = battery[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = battery[kIOPSMaxCapacityKey] as? Int ?? 100
        let percentage = maxCapacity > 0 ? capacity * 100 / maxCapacity : 0

        let state: BatteryStatus.State =
            switch battery[kIOPSPowerSourceStateKey] as? String {
            case kIOPSBatteryPowerValue:
                .discharging(remaining: timeString(fromMinutes: battery[kIOPSTimeToEmptyKey]))
            case kIOPSACPowerValue where battery[kIOPSIsChargedKey] as? Bool == true:
                .charged
            case kIOPSACPowerValue where battery[kIOPSIsChargingKey] as? Bool == true:
                .charging(remaining: timeString(fromMinutes: battery[kIOPSTimeToFullChargeKey]))
            case kIOPSACPowerValue:
                .pluggedInNotCharging
            default:
                .unknown
            }
        return BatteryStatus(state: state, percentage: percentage)
    }

    nonisolated private static func timeString(fromMinutes value: Any?) -> String {
        guard let minutes = value as? Int, minutes >= 0 else {
            return "..."
        }
        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}
