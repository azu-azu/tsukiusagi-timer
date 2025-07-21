import SwiftUI

struct CardContainer<Content: View>: View {
    let title: String
    let isCompact: Bool
    let cardCornerRadius: CGFloat
    let content: () -> Content

    init(
        title: String = "",
        isCompact: Bool = false,
        cardCornerRadius: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isCompact = isCompact
        self.cardCornerRadius = cardCornerRadius
        self.content = content
    }

    var body: some View {
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
