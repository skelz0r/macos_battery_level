import Foundation

struct BatteryStatus {
    let timeString: String
    let isCharging: Bool
    let isFullyCharged: Bool
    let percentage: Int
    let powerSource: String
    let lowPowerMode: Bool
}

class BatteryMonitor {
    func getStatus() -> BatteryStatus {
        let output = runPmset()
        let lowPower = isLowPowerModeEnabled()
        return parse(output, lowPower: lowPower)
    }

    private func isLowPowerModeEnabled() -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.contains("lowpowermode") && output.contains("1")
    }

    func toggleLowPowerMode(enable: Bool) {
        let script = "do shell script \"pmset -a lowpowermode \(enable ? 1 : 0)\" with administrator privileges"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
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

    private func parse(_ output: String, lowPower: Bool) -> BatteryStatus {
        let isCharging = output.contains("AC Power") || (output.contains("charging") && !output.contains("discharging"))
        let isFullyCharged = output.contains("charged") && !output.contains("discharging")

        var percentage = 0
        let percentPattern = #"(\d+)%"#
        if let regex = try? NSRegularExpression(pattern: percentPattern),
           let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 1), in: output) {
            percentage = Int(output[range]) ?? 0
        }

        let powerSource = output.contains("AC Power") ? "Power Adapter" : "Battery"

        if isFullyCharged {
            return BatteryStatus(timeString: "", isCharging: true, isFullyCharged: true, percentage: percentage, powerSource: powerSource, lowPowerMode: lowPower)
        }

        let pattern = #"(\d+:\d+) (remaining|until full)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 1), in: output) {
            return BatteryStatus(timeString: String(output[range]), isCharging: isCharging, isFullyCharged: false, percentage: percentage, powerSource: powerSource, lowPowerMode: lowPower)
        }

        if output.contains("(no estimate)") || output.contains("calculating") {
            return BatteryStatus(timeString: "...", isCharging: isCharging, isFullyCharged: false, percentage: percentage, powerSource: powerSource, lowPowerMode: lowPower)
        }

        if !output.contains("InternalBattery") {
            return BatteryStatus(timeString: "No battery", isCharging: false, isFullyCharged: false, percentage: 0, powerSource: "Unknown", lowPowerMode: lowPower)
        }

        return BatteryStatus(timeString: "—", isCharging: isCharging, isFullyCharged: false, percentage: percentage, powerSource: powerSource, lowPowerMode: lowPower)
    }
}
