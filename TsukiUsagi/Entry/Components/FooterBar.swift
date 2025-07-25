import SwiftUI
import Foundation

struct FooterBar: View {
    let buttonHeight: CGFloat
    let buttonWidth: CGFloat
    let dateString: String
    let onGearTap: () -> Void
    let startPauseButton: AnyView

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack {
                Text(dateString)
                    .font(DesignTokens.Fonts.footerDate)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .frame(height: buttonHeight, alignment: .bottom)

                Spacer(minLength: 0)

                Button(action: onGearTap) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .frame(width: buttonHeight,
                                height: buttonHeight,
                                alignment: .bottom)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
            }
            startPauseButton
                .frame(height: buttonHeight, alignment: .bottom)
                .offset(y: 6)
        }
        .frame(height: buttonHeight)
        .background(Color.black.opacity(0.0001))
        .zIndex(AppConstants.overlayZIndex)
    }
}
