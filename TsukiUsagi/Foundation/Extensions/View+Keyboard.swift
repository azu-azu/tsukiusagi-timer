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

// MARK: - UIApplication Extension for Editing
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Dismiss Keyboard Modifier
struct DismissKeyboardOnTap: ViewModifier {
    var isActivityFocused: FocusState<Bool>.Binding
    var isSubtitleFocused: FocusState<Bool>.Binding
    var isMemoFocused: FocusState<Bool>.Binding
    var isKeyboardVisible: Binding<Bool>

    func body(content: Content) -> some View {
        content.onTapGesture {
            // より確実なキーボード非表示
            withAnimation(.easeInOut(duration: 0.3)) {
                isActivityFocused.wrappedValue = false
                isSubtitleFocused.wrappedValue = false
                isMemoFocused.wrappedValue = false
                isKeyboardVisible.wrappedValue = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIApplication.shared.endEditing()
            }
        }
    }
}

// MARK: - Keyboard Height Modifier
struct KeyboardHeightModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillShowNotification
                )
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                    as? NSValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.cgRectValue.height
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
            .padding(.bottom, keyboardHeight)
    }
}

// MARK: - View Extension for Modifiers
extension View {
    /// キーボード高さ監視用のビューモディファイア
    func keyboardHeight() -> some View {
        self.modifier(KeyboardHeightModifier())
    }
}
