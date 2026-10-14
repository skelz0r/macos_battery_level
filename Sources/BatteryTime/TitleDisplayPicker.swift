import SwiftUI

struct TitleDisplayPicker: View {
    @AppStorage(TitleDisplay.defaultsKey) private var titleDisplay = TitleDisplay.time

    var body: some View {
        HStack {
            Text("Menu Bar")
            Spacer()
            Picker("Menu Bar", selection: $titleDisplay) {
                Text("Time").tag(TitleDisplay.time)
                Text("%").tag(TitleDisplay.percentage)
                Text("Both").tag(TitleDisplay.both)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        }
        .font(.system(size: 13))
        .padding(.horizontal, 14)
        .frame(minHeight: 28)
    }
}

extension TitleDisplay {
    static let defaultsKey = "titleDisplay"
}
