import SwiftUI
import Foundation

struct BreakTimeSectionView: View {
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    private let timeTitleWidth: CGFloat = 80 // BREAK の文字の幅
    private let cardCornerRadius: CGFloat = 8

    var body: some View {
        section(title: "", isCompact: true) {
            HStack {
                Text("BREAK")
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                    .frame(width: timeTitleWidth, alignment: .leading)

                Text(String(format: "%2d min", breakMinutes))
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)

                Spacer()

                plusMinusButtons(
                    onMinus: { if breakMinutes > 1 { breakMinutes -= 1 } },
                    onPlus: { if breakMinutes < 30 { breakMinutes += 1 } }
                )
            }
        }
    }

    // プラスマイナスボタンの共通化
    @ViewBuilder
    private func plusMinusButtons(
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        PlusMinusButtonPair(
            onMinus: onMinus,
            onPlus: onPlus,
            spacing: DesignTokens.Spacing.small
        )
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: isCompact
                ? DesignTokens.Spacing.extraSmall
                : DesignTokens.Spacing.small
        ) {
            if !title.isEmpty {
                Text(title)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(isCompact
                ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                : EdgeInsets())
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(DesignTokens.Colors.moonCardBG)
            )
        }
    }
}

#if DEBUG
struct BreakTimeSectionView_Previews: PreviewProvider {
    static var previews: some View {
        BreakTimeSectionView()
    }
}
#endif
