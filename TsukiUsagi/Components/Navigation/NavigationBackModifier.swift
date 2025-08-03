import SwiftUI

// MARK: - Navigation Back Button Modifier

struct NavigationBackModifier: ViewModifier {
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(DesignTokens.Fonts.label)
                            Text("Back")
                                .font(DesignTokens.Fonts.label)
                        }
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // 右向きのスワイプ（戻る動作）
                        if value.translation.width > 50 && abs(value.translation.height) < 100 {
                            onBack()
                        }
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    /// 共通のBackボタンとスワイプジェスチャーを追加
    /// - Parameter onBack: Backボタンまたはスワイプ時に実行されるアクション
    func navigationBackButton(onBack: @escaping () -> Void) -> some View {
        self.modifier(NavigationBackModifier(onBack: onBack))
    }
}
