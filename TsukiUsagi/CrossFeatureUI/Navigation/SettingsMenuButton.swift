import SwiftUI

struct SettingsMenuButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(DesignTokens.PureColors.textWhite)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Open Settings")
    }
}

#if DEBUG
struct SettingsMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMenuButton {
            print("Menu tapped")
        }
        .background(DesignTokens.BlackColors.primary)
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif
