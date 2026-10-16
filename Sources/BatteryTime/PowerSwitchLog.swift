import Foundation

enum PowerSwitchLog {
    static func lastSwitch(to source: PowerSource, inPmsetLog log: String) -> Date? {
        let timestampFormatter = DateFormatter()
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        timestampFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        var switchDate: Date?
        for line in log.split(separator: "\n").reversed() {
            guard let entry = entry(from: line, timestampFormatter: timestampFormatter) else { continue }
            guard entry.source == source else { return switchDate }
            switchDate = entry.date
        }
        return nil
    }

    static func lastSwitch(to source: PowerSource) async -> Date? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: readPmsetLog().flatMap { lastSwitch(to: source, inPmsetLog: $0) })
            }
        }
    }

    private static let timestampLength = 25
    private static let kindLength = 20
    private static let kindsReportingSource: Set = ["Sleep", "Wake", "DarkWake"]

    private static func entry(
        from line: Substring,
        timestampFormatter: DateFormatter
    ) -> (date: Date, source: PowerSource)? {
        let record = line.dropFirst(timestampLength + 1)
        let kind = record.prefix(kindLength).trimmingCharacters(in: .whitespaces)
        let message = record.dropFirst(kindLength).trimmingCharacters(in: .whitespaces)
        guard kindsReportingSource.contains(kind) || (kind == "Assertions" && message.hasPrefix("Summary-")),
            let source = lastReportedSource(in: message),
            let date = timestampFormatter.date(from: String(line.prefix(timestampLength)))
        else { return nil }
        return (date, source)
    }

    private static func lastReportedSource(in message: String) -> PowerSource? {
        let options: String.CompareOptions = [.caseInsensitive, .backwards]
        let powerAdapter = message.range(of: "Using AC", options: options)
        let battery = message.range(of: "Using Batt", options: options)
        switch (powerAdapter, battery) {
        case (.some(let powerAdapter), .some(let battery)):
            return powerAdapter.lowerBound > battery.lowerBound ? .powerAdapter : .battery
        case (.some, nil): return .powerAdapter
        case (nil, .some): return .battery
        case (nil, nil): return nil
        }
    }

    private static func readPmsetLog() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "/usr/bin/pmset -g log | /usr/bin/grep -iE 'Using (AC|Batt)'"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }
}
