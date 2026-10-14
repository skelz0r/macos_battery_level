import Foundation

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

final class BatteryMonitor {
    func getStatus() -> BatteryStatus {
        Self.parse(runPmset())
    }

    private func runPmset() -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func parse(_ output: String) -> BatteryStatus {
        guard let batteryLine = output.split(separator: "\n").first(where: { $0.contains("InternalBattery") }) else {
            return BatteryStatus(state: .noBattery, percentage: 0)
        }

        let fields = batteryLine.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        let percentage = firstCapture(of: #"(\d+)%"#, in: fields[0]).flatMap { Int($0) } ?? 0
        guard fields.count >= 3 else {
            return BatteryStatus(state: .unknown, percentage: percentage)
        }

        let state: BatteryStatus.State =
            switch fields[1] {
            case "charged":
                .charged
            case "AC attached":
                .pluggedInNotCharging
            case "charging", "finishing charge":
                .charging(remaining: timeString(from: fields[2]))
            case "discharging":
                .discharging(remaining: timeString(from: fields[2]))
            default:
                .unknown
            }
        return BatteryStatus(state: state, percentage: percentage)
    }

    private static func timeString(from estimate: String) -> String {
        if estimate.hasPrefix("(no estimate)") {
            return "..."
        }
        return firstCapture(of: #"^(\d+:\d+) (remaining|until full)"#, in: estimate) ?? "—"
    }

    private static func firstCapture(of pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[range])
    }
}
