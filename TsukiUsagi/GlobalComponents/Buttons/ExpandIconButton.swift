import SwiftUI

public struct ExpandIconButton: View {
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
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.accentBlue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copy.Button.expand)
        .accessibilityIdentifier(accessibilityId ?? "")
    }
}


