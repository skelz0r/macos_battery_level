import Foundation

struct PowerSwitchTracker {
    private(set) var source: PowerSource?
    private(set) var switchDate: Date?

    mutating func observe(_ newSource: PowerSource?, at date: Date) {
        guard newSource != source else { return }
        switchDate = source != nil && newSource != nil ? date : nil
        source = newSource
    }
}
