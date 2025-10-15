import SwiftUI

struct EditIconButton: View {
    let action: () -> Void
    let isEnabled: Bool
    let size: PencilIconSize

    init(isEnabled: Bool = true, size: PencilIconSize = .medium, action: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            PencilIcon(size: size)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minWidth: 44, minHeight: 44)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(Copy.Button.edit)
        .accessibilityAddTraits(.isButton)
        .disabled(!isEnabled)
    }
}
