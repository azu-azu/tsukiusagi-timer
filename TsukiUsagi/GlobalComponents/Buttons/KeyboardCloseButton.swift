import SwiftUI

/// キーボードを閉じるボタン
/// 配置は呼び出し側で `overlay(alignment:)` を使用
struct KeyboardCloseButton: View {
    let action: () -> Void
    var isCompact: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(isCompact ? DesignTokens.Fonts.caption : DesignTokens.Fonts.label)
        }
        .foregroundColor(DesignTokens.MoonColors.textPrimary)
        .padding(isCompact ? DesignTokens.Padding.extraSmall : DesignTokens.Padding.small)
        .background(Circle().fill(DesignTokens.CosmosColors.background.opacity(0.8)))
    }
}

// MARK: - Keyboard Helper

struct KeyboardHelper {
    static func hideKeyboard(completion: (() -> Void)? = nil) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { completion?() }
    }
}
