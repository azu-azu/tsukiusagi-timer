import SwiftUI

// MARK: - UIApplication Extension
extension UIApplication {
    /// キーボードを強制的に非表示にする
    static func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - View Extension
extension View {
    /// キーボードを非表示にする
    func hideKeyboard() -> some View {
        UIApplication.hideKeyboard()
        return self
    }

    /// タップでキーボードを閉じる機能を追加
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.hideKeyboard()
        }
    }
}

// MARK: - KeyboardManager
struct KeyboardManager {
    /// キーボードを強制的に非表示
    static func hide() {
        UIApplication.hideKeyboard()
    }

    /// コールバック付きでキーボードを閉じる（FocusState管理は呼び出し側で行う）
    static func hideKeyboard(completion: @escaping () -> Void) {
        UIApplication.hideKeyboard()
        completion()
    }

    /// 単純にキーボードを閉じる
    static func hideKeyboard() {
        UIApplication.hideKeyboard()
    }
}
