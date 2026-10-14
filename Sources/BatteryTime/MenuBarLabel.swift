import AppKit
import SwiftUI

struct MenuBarLabel: View {
    let status: BatteryStatus

    var body: some View {
        if let symbol = status.menuBarBatterySymbol {
            Image(nsImage: render(Text("\(Image(systemName: symbol)) \(status.menuBarTitle)")))
        } else {
            Text(status.menuBarTitle)
        }
    }

    private func render(_ title: Text) -> NSImage {
        let renderer = ImageRenderer(
            content:
                title
                .font(.system(size: NSFont.systemFontSize))
                .foregroundStyle(status.menuBarColor ?? .black)
        )
        renderer.scale = NSScreen.screens.map(\.backingScaleFactor).max() ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = status.menuBarColor == nil
        return image
    }
}

extension BatteryStatus {
    var menuBarColor: Color? {
        guard case .discharging = state else { return nil }
        return lowLevelColor
    }
}
