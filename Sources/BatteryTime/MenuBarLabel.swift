import AppKit
import SwiftUI

struct MenuBarLabel: View {
    let status: BatteryStatus

    var body: some View {
        if let symbol = status.menuBarBatterySymbol {
            Image(nsImage: render(symbol: symbol))
        } else {
            Text(status.menuBarTitle)
        }
    }

    private var spacedTitle: String {
        status.menuBarTitle.isEmpty ? "" : " \(status.menuBarTitle)"
    }

    private func render(symbol: String) -> NSImage {
        let renderer = ImageRenderer(
            content:
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(Image(systemName: symbol))
                        .overlay(alignment: .topTrailing) {
                            if status.isLowPowerMode {
                                lowPowerBadge
                            }
                        }
                        .padding(.trailing, status.isLowPowerMode ? 3 : 0)
                    if !spacedTitle.isEmpty {
                        Text(spacedTitle)
                    }
                }
                .font(.system(size: NSFont.systemFontSize))
                .foregroundStyle(status.menuBarColor ?? .black)
        )
        renderer.scale = NSScreen.screens.map(\.backingScaleFactor).max() ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = status.menuBarColor == nil
        return image
    }

    private var lowPowerBadge: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 5))
            .offset(x: 3)
    }
}

extension BatteryStatus {
    var menuBarColor: Color? {
        guard case .discharging = state else { return nil }
        return lowLevelColor
    }
}
