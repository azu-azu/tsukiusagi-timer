import SwiftUI

public struct CollapseIconButton: View {
    private let accessibilityId: String?
    private let action: () -> Void

    public init(
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.accessibilityId = accessibilityIdentifier
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.accentBlue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copy.Button.close)
        .accessibilityIdentifier(accessibilityId ?? "")
    }
}
