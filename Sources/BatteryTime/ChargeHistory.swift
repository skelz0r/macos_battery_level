import Foundation

struct ChargeSample: Codable, Equatable {
    let date: Date
    let percentage: Int
    let isPluggedIn: Bool
}

struct ChargeHistory: Codable, Equatable {
    static let window: TimeInterval = 24 * 60 * 60
    static let samplingInterval: TimeInterval = 5 * 60
    static let maximumGap: TimeInterval = 15 * 60

    private(set) var samples: [ChargeSample] = []

    @discardableResult
    mutating func record(_ status: BatteryStatus, at date: Date) -> Bool {
        guard let sample = status.chargeSample(at: date) else { return false }
        samples.removeAll { $0.date > date }
        if let last = samples.last,
            date.timeIntervalSince(last.date) < Self.samplingInterval,
            last.percentage == sample.percentage,
            last.isPluggedIn == sample.isPluggedIn
        {
            return false
        }
        samples.append(sample)
        samples.removeAll { date.timeIntervalSince($0.date) > Self.window }
        return true
    }

    func segments(until date: Date) -> [[ChargeSample]] {
        samples
            .filter { date.timeIntervalSince($0.date) <= Self.window }
            .reduce(into: [[ChargeSample]]()) { segments, sample in
                if let last = segments.last?.last, sample.date.timeIntervalSince(last.date) <= Self.maximumGap {
                    segments[segments.count - 1].append(sample)
                } else {
                    segments.append([sample])
                }
            }
    }

    func pluggedInPeriods(until date: Date) -> [ClosedRange<Date>] {
        segments(until: date).flatMap { segment in
            zip(segment, segment.dropFirst())
                .filter { $0.0.isPluggedIn }
                .map { $0.0.date...$0.1.date }
        }
        .reduce(into: [ClosedRange<Date>]()) { periods, period in
            if let last = periods.last, last.upperBound == period.lowerBound {
                periods[periods.count - 1] = last.lowerBound...period.upperBound
            } else {
                periods.append(period)
            }
        }
    }
}

extension ChargeHistory {
    private static let defaultsKey = "chargeHistory"

    static func load(from defaults: UserDefaults = .standard) -> ChargeHistory {
        defaults.data(forKey: defaultsKey).flatMap { try? JSONDecoder().decode(ChargeHistory.self, from: $0) }
            ?? ChargeHistory()
    }

    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}

extension BatteryStatus {
    fileprivate func chargeSample(at date: Date) -> ChargeSample? {
        switch state {
        case .discharging:
            ChargeSample(date: date, percentage: percentage, isPluggedIn: false)
        case .charging, .charged, .pluggedInNotCharging:
            ChargeSample(date: date, percentage: percentage, isPluggedIn: true)
        case .noBattery, .unknown:
            nil
        }
    }
}
