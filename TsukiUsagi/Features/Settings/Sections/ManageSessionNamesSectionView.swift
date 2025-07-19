import SwiftUI

struct ManageSessionNamesSectionView: View {
    @EnvironmentObject private var sessionManagerV2: SessionManagerV2

    private let cardCornerRadius: CGFloat = 8

    var body: some View {
        section(title: "", isCompact: true) {
            NavigationLink(
                destination: SessionNameManagerView().environmentObject(sessionManagerV2)
            ) {
                HStack {
                    Text("Manage Session Names")
                        .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignTokens.Colors.moonTextMuted)
                }
                .padding(.vertical, 8)
            }
        }
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
struct ManageSessionNamesSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ManageSessionNamesSectionView()
            .environmentObject(SessionManagerV2())
    }
}
#endif
