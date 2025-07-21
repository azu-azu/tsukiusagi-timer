import SwiftUI

struct WorkTimeSectionView: View {
    @AppStorage("workMinutes") private var workMinutes: Int = 25

    // workMinutesの選択肢: 1, 3, 5, 10, 15, ... 60
    private let workMinutesOptions: [Int] = [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))

    private let timeTitleWidth: CGFloat = 80 // WORK の文字の幅
    private let cardCornerRadius: CGFloat = 8

    var body: some View {
        section(title: "", isCompact: true) {
            HStack {
                Text("WORK")
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                    .frame(width: timeTitleWidth, alignment: .leading)

                Text(String(format: "%2d min", workMinutes))
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)

                Spacer()

                plusMinusButtons(
                    onMinus: {
                        let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                        if currentIndex > 0 {
                            workMinutes = workMinutesOptions[currentIndex - 1]
                        }
                    },
                    onPlus: {
                        let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                        if currentIndex < workMinutesOptions.count - 1 {
                            workMinutes = workMinutesOptions[currentIndex + 1]
                        }
                    }
                )
            }
        }
        .debugSection(String(describing: Self.self), position: .topLeading)
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
                    .fill(DesignTokens.Colors.cosmosCardBG)
            )
        }
    }
}

#if DEBUG
struct WorkTimeSectionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkTimeSectionView()
    }
}
#endif
