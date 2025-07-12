import SwiftUI

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
                    .titleWhite(size: 16, weight: .bold, design: .monospaced)
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
                        .foregroundColor(DesignTokens.Colors.textWhite)
                }
            }
            startPauseButton
                .frame(height: buttonHeight, alignment: .bottom)
                .offset(y: 6)
        }
        .frame(height: buttonHeight)
        .background(Color.black.opacity(0.0001))
        .zIndex(LayoutConstants.overlayZIndex)
    }
}