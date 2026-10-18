import Foundation

struct ChargeLimit: Codable, Equatable {
    static let settings = [80, 85, 90, 95, 100]
    static let plateauDuration: TimeInterval = 10 * 60
    static let historySize = 7
    static let tolerance = 3

    private struct Observation: Equatable {
        let date: Date
        let isCharging: Bool
    }

    private struct Plateau: Equatable {
        let percentage: Int
        let since: Date
    }

    private enum CodingKeys: String, CodingKey {
        case plateaus
    }

    private var plateaus: [Int] = []
    private var lastObservation: Observation?
    private var plateau: Plateau?

    var percentage: Int? {
        let sorted = plateaus.sorted()
        guard !sorted.isEmpty else { return nil }
        let median = Double(sorted[(sorted.count - 1) / 2] + sorted[sorted.count / 2]) / 2
        return Self.settings.min { abs(Double($0) - median) < abs(Double($1) - median) }
    }

    @discardableResult
    mutating func observe(_ status: BatteryStatus, at date: Date) -> Bool {
        let previous = lastObservation
        lastObservation = Observation(date: date, isCharging: status.isCharging)
        let isContinuous = previous.map { date.timeIntervalSince($0.date) <= ChargeHistory.maximumGap } ?? false

        if let limit = percentage, status.isFilling, status.percentage > limit + Self.tolerance {
            plateaus.removeAll()
            plateau = nil
            return true
        }
        guard case .pluggedInNotCharging = status.state, status.percentage < 100, isContinuous else {
            plateau = nil
            return false
        }
        if previous?.isCharging == true {
            plateau = Plateau(percentage: status.percentage, since: date)
            return false
        }
        guard let plateau, date.timeIntervalSince(plateau.since) >= Self.plateauDuration else { return false }
        plateaus = (plateaus + [plateau.percentage]).suffix(Self.historySize)
        self.plateau = nil
        return true
    }

    mutating func systemWillSleep() {
        lastObservation = nil
        plateau = nil
    }
}

extension ChargeLimit {
    private static let defaultsKey = "chargeLimit"

    static func load(from defaults: UserDefaults = .standard) -> ChargeLimit {
        defaults.data(forKey: defaultsKey).flatMap { try? JSONDecoder().decode(ChargeLimit.self, from: $0) }
            ?? ChargeLimit()
    }

    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}

extension BatteryStatus {
    fileprivate var isCharging: Bool {
        if case .charging = state { true } else { false }
    }

    fileprivate var isFilling: Bool {
        switch state {
        case .charging, .charged: true
        default: false
        }
    }
}
