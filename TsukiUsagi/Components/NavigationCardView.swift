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
                        .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignTokens.Colors.moonTextMuted)
                }
                .padding(.vertical, 8)
            }
        }
    }
}
