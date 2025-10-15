import SwiftUI

enum PencilIconSize {
    case small
    case medium
    case large
    case title
}

struct PencilIcon: View {
    let size: PencilIconSize

    init(size: PencilIconSize = .medium) {
        self.size = size
    }

    var body: some View {
        Image(systemName: "pencil")
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(DesignTokens.IconColors.pencil)
            .font(font)
            .accessibilityHidden(true)
    }

    private var font: Font {
        switch size {
        case .small: return DesignTokens.Fonts.symbolSmall
        case .medium: return DesignTokens.Fonts.symbolMedium
        case .large: return DesignTokens.Fonts.symbolLarge
        case .title: return DesignTokens.Fonts.title
        }
    }

}

struct PencilButton: View {
    let action: () -> Void
    let size: PencilIconSize

    init(size: PencilIconSize = .title, action: @escaping () -> Void) {
        self.action = action
        self.size = size
    }

    var body: some View {
        Button(action: action) {
            PencilIcon(size: size)
        }
        .accessibilityLabel(Copy.Button.edit)
    }
}
