import SwiftUI

// MARK: - 純粋なUI要素（改良版）
struct KeyboardCloseButton: View {
    let action: () -> Void
    var isCompact: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(isCompact ? .body : .title2)
        }
        .foregroundColor(.primary)
        .padding(isCompact ? 6 : 8)
        .background(
            Circle()
                .fill(Color.black.opacity(0.8))
        )
    }
}

// MARK: - 機能的な拡張（改良版）
extension View {
    /// キーボードクローズボタンを条件付きで表示
    ///
    /// - Note: このmodifierは対象Viewの右上角にボタンを固定配置します
    /// - Warning: ZStackベースの実装のため、親Viewは適切なレイアウトが必要です
    ///
    /// - Parameters:
    ///   - isVisible: ボタンの表示状態
    ///   - isCompact: コンパクト表示するかどうか
    ///   - topPadding: 上部からのパディング（デフォルト16）
    ///   - trailingPadding: 右端からのパディング（デフォルト16）
    ///   - action: ボタンタップ時のアクション
    func keyboardCloseButton(
        isVisible: Bool,
        isCompact: Bool = false,
        topPadding: CGFloat = 16,
        trailingPadding: CGFloat = 16,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            self

            if isVisible {
                VStack {
                    HStack {
                        Spacer()
                        KeyboardCloseButton(action: action, isCompact: isCompact)
                            .padding(.trailing, trailingPadding)
                            .padding(.top, topPadding)
                    }
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isVisible)
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
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .keyboardCloseButton(
            isVisible: isNameFocused || isSubtitleFocused,
            action: {
                KeyboardManager.hideKeyboard {
                    isNameFocused = false
                    isSubtitleFocused = false
                }
            }
        )
    }
}

// MARK: - 設計方針
/*
✅ 責務分離：
  - KeyboardCloseButton = 純粋なUI要素（円形デザインに改良）
  - keyboardCloseButton modifier = 固定配置の機能的な拡張

✅ 実用性：
  - 使用側はシンプル
  - キーボード表示時に右上角に固定配置
  - スクロール不要で常に見える位置

✅ 拡張性：
  - KeyboardCloseButtonは他でも使える
  - modifierも再利用可能
  - ZStackベースで柔軟な配置

✅ デザイン改良：
  - "Close"テキストを削除してアイコンのみ
  - 円形背景で視認性向上
  - 黒背景でキーボード上でも見やすく
*/
