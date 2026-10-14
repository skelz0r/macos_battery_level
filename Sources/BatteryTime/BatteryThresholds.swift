import Foundation
import UserNotifications

enum BatteryThresholdCrossing: Equatable {
    case dischargedTo(Int)
    case chargedTo(Int)
}

struct BatteryThresholds {
    static let discharging = [20, 10]
    static let charging = [80, 100]

    private var lastPercentage: Int?

    init(initialStatus: BatteryStatus) {
        lastPercentage = initialStatus.reportsPercentage ? initialStatus.percentage : nil
    }

    mutating func crossing(to status: BatteryStatus) -> BatteryThresholdCrossing? {
        guard status.reportsPercentage else { return nil }
        defer { lastPercentage = status.percentage }
        guard let previous = lastPercentage else { return nil }

        let current = status.percentage
        if status.isDischarging,
            let threshold = Self.discharging.last(where: { previous > $0 && current <= $0 })
        {
            return .dischargedTo(threshold)
        }
        if status.isOnPower,
            let threshold = Self.charging.last(where: { previous < $0 && current >= $0 })
        {
            return .chargedTo(threshold)
        }
        return nil
    }
}

extension BatteryStatus {
    fileprivate var reportsPercentage: Bool {
        switch state {
        case .discharging, .charging, .pluggedInNotCharging, .charged:
            true
        case .noBattery, .unknown:
            false
        }
    }

    fileprivate var isDischarging: Bool {
        if case .discharging = state { true } else { false }
    }

    fileprivate var isOnPower: Bool {
        switch state {
        case .charging, .pluggedInNotCharging, .charged:
            true
        case .discharging, .noBattery, .unknown:
            false
        }
    }
}

@MainActor
final class BatteryThresholdNotifier: NSObject, UNUserNotificationCenterDelegate {
    private var thresholds: BatteryThresholds

    init(initialStatus: BatteryStatus) {
        thresholds = BatteryThresholds(initialStatus: initialStatus)
        super.init()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func batteryStatusDidChange(_ status: BatteryStatus) {
        guard let crossing = thresholds.crossing(to: status) else { return }
        let content = UNMutableNotificationContent()
        switch crossing {
        case .dischargedTo(let percentage):
            content.title = "Battery at \(percentage) %"
            content.body = "Plug in your Mac soon."
            content.sound = .default
        case .chargedTo(100):
            content.title = "Battery fully charged"
        case .chargedTo(let percentage):
            content.title = "Battery charged to \(percentage) %"
        }
        let request = UNNotificationRequest(identifier: "battery-threshold", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
