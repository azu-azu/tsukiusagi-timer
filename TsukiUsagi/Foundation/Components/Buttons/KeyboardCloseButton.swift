import SwiftUI

// MARK: - 純粋なUI要素（案２のアプローチ）
struct KeyboardCloseButton: View {
    let action: () -> Void
    var isCompact: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "keyboard.chevron.compact.down")
                Text("Close")
            }
            .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.moonTextPrimary)
        .padding(.horizontal, isCompact ? 8 : 12)
        .padding(.vertical, isCompact ? 4 : 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.15))
        )
    }
}

// MARK: - 機能的な拡張（案２のアプローチ）
extension View {
    /// キーボードクローズボタンを条件付きで表示
    ///
    /// - Note: このmodifierは対象Viewの右側にボタンを追加します
    /// - Warning: .padding()や.frame(maxWidth:)の直後に適用してください
    ///
    /// - Parameters:
    ///   - isVisible: ボタンの表示状態
    ///   - isCompact: コンパクト表示するかどうか
    ///   - action: ボタンタップ時のアクション
    func keyboardCloseButton(
        isVisible: Bool,
        isCompact: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            self

            if isVisible {
                KeyboardCloseButton(action: action, isCompact: isCompact)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isVisible)
            } else {
                // レイアウト安定性のためのプレースホルダー（案１のアイデア）
                KeyboardCloseButton(action: {}, isCompact: isCompact)
                    .opacity(0)
                    .allowsHitTesting(false)  // 事故防止：見えないボタンを押せないように
            }
        }
    }
}

// MARK: - 使用例
struct ExampleUsage: View {
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool

    var body: some View {
        VStack {
            TextField("Name", text: .constant(""))
                .focused($isNameFocused)

            TextField("Subtitle", text: .constant(""))
                .focused($isSubtitleFocused)
        }
        .keyboardCloseButton(
            isVisible: isNameFocused || isSubtitleFocused,
            action: {
                isNameFocused = false
                isSubtitleFocused = false
            }
        )
    }
}

// MARK: - 設計方針
/*
✅ 責務分離：
  - KeyboardCloseButton = 純粋なUI要素
  - keyboardCloseButton modifier = 機能的な拡張

✅ 実用性：
  - 使用側はシンプル
  - レイアウト安定性も確保

✅ 拡張性：
  - KeyboardCloseButtonは他でも使える
  - modifierも再利用可能
*/