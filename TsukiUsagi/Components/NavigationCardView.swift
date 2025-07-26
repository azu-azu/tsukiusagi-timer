import SwiftUI

struct NavigationCardView<Destination: View>: View {
    let title: String
    let destination: Destination
    var isCompact: Bool = true

    var body: some View {
        CardContainer(isCompact: isCompact) {
            NavigationLink(destination: destination) {
                HStack {
                    Text(title)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                }
                .padding(.vertical, 8)
            }
        }
    }
}
