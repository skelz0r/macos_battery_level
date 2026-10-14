import Foundation

struct EnergyHog: Equatable {
    let name: String
    let impact: Double
}

enum EnergyMonitor {
    private struct ProcessSample {
        let pid: Int32
        let name: String
        let impact: Double
    }

    static let impactThreshold = 20.0
    static let maximumCount = 5

    static func hogs(
        fromTopOutput output: String,
        executablePath: (Int32) -> String? = { _ in nil }
    ) -> [EnergyHog] {
        let impactByName = Dictionary(
            lastSample(of: output).map { sample in
                (executablePath(sample.pid).map(appName(forExecutablePath:)) ?? sample.name, sample.impact)
            },
            uniquingKeysWith: +
        )
        let hogs =
            impactByName
            .map { EnergyHog(name: $0.key, impact: $0.value) }
            .filter { $0.impact >= impactThreshold }
            .sorted { $0.impact > $1.impact }
        return Array(hogs.prefix(maximumCount))
    }

    private static func appName(forExecutablePath path: String) -> String {
        let components = path.split(separator: "/")
        if let appBundle = components.first(where: { $0.hasSuffix(".app") }) {
            return String(appBundle.dropLast(".app".count))
        }
        return components.last.map(String.init) ?? path
    }

    private static func lastSample(of output: String) -> [ProcessSample] {
        let lines = output.split(separator: "\n")
        guard let headerIndex = lines.lastIndex(where: { $0.hasPrefix("PID") }) else { return [] }

        return lines[(headerIndex + 1)...].compactMap { line in
            let columns = line.split(whereSeparator: \.isWhitespace)
            guard columns.count >= 3, let pid = Int32(columns[0]), let impact = columns.last.flatMap({ Double($0) })
            else { return nil }
            let name = columns.dropFirst().dropLast().joined(separator: " ")
            return ProcessSample(pid: pid, name: name, impact: impact)
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
                    let hogs = self.runTop().map {
                        EnergyMonitor.hogs(fromTopOutput: $0, executablePath: Self.executablePath(of:))
                    }
                    continuation.resume(returning: hogs)
                }
            }
        } onCancel: {
            cancel()
        }
    }

    private static func executablePath(of pid: Int32) -> String? {
        var buffer = [UInt8](repeating: 0, count: Int(MAXPATHLEN) * 4)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        return String(bytes: buffer.prefix(Int(length)), encoding: .utf8)
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
