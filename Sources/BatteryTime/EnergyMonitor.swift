import Foundation

struct EnergyHog: Equatable {
    let name: String
    let impact: Double
}

enum EnergyMonitor {
    static let impactThreshold = 20.0
    static let maximumCount = 5

    static func hogs(fromTopOutput output: String) -> [EnergyHog] {
        let impactByName = Dictionary(
            lastSample(of: output).map { ($0.name, $0.impact) },
            uniquingKeysWith: +
        )
        let hogs =
            impactByName
            .map { EnergyHog(name: $0.key, impact: $0.value) }
            .filter { $0.impact >= impactThreshold }
            .sorted { $0.impact > $1.impact }
        return Array(hogs.prefix(maximumCount))
    }

    private static func lastSample(of output: String) -> [EnergyHog] {
        let lines = output.split(separator: "\n")
        guard let headerIndex = lines.lastIndex(where: { $0.hasPrefix("PID") }) else { return [] }

        return lines[(headerIndex + 1)...].compactMap { line in
            let columns = line.split(whereSeparator: \.isWhitespace)
            guard columns.count >= 3, Int32(columns[0]) != nil, let impact = columns.last.flatMap({ Double($0) })
            else { return nil }
            let name = columns.dropFirst().dropLast().joined(separator: " ")
            return EnergyHog(name: name, impact: impact)
        }
    }
}

final class EnergyMeasurement: @unchecked Sendable {
    private let process = Process()
    private let lock = NSLock()
    private var isCancelled = false

    init() {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        process.arguments = ["-l", "2", "-s", "1", "-o", "power", "-stats", "pid,command,power"]
    }

    func hogs() async -> [EnergyHog]? {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    continuation.resume(returning: self.runTop().map(EnergyMonitor.hogs(fromTopOutput:)))
                }
            }
        } onCancel: {
            cancel()
        }
    }

    private func runTop() -> String? {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        lock.lock()
        guard !isCancelled, (try? process.run()) != nil else {
            lock.unlock()
            return nil
        }
        lock.unlock()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func cancel() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
        if process.isRunning {
            process.terminate()
        }
    }
}
