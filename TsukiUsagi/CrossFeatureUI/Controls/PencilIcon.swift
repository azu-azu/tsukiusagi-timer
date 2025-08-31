import SwiftUI

enum PencilIconStyle {
    case accent
    case muted
    case primary
}

enum PencilIconSize {
    case small
    case medium
    case large
    case title
}

struct PencilIcon: View {
    let style: PencilIconStyle
    let size: PencilIconSize

    init(style: PencilIconStyle = .accent, size: PencilIconSize = .medium) {
        self.style = style
        self.size = size
    }

    var body: some View {
        Image(systemName: "pencil")
            .font(font)
            .foregroundColor(color)
    }

    private var font: Font {
        switch size {
        case .small: return DesignTokens.Fonts.symbolSmall
        case .medium: return DesignTokens.Fonts.symbolMedium
        case .large: return DesignTokens.Fonts.symbolLarge
        case .title: return DesignTokens.Fonts.title
        }
    }

    private var color: Color {
        switch style {
        case .accent: return DesignTokens.MoonColors.accentBlue
        case .muted: return DesignTokens.MoonColors.textMuted
        case .primary: return DesignTokens.MoonColors.textPrimary
        }
    }
}

struct PencilButton: View {
    let action: () -> Void
    let style: PencilIconStyle
    let size: PencilIconSize

    init(style: PencilIconStyle = .accent, size: PencilIconSize = .title, action: @escaping () -> Void) {
        self.action = action
        self.style = style
        self.size = size
    }

    var body: some View {
        Button(action: action) {
            PencilIcon(style: style, size: size)
        }
        .accessibilityLabel("Edit")
    }
}
