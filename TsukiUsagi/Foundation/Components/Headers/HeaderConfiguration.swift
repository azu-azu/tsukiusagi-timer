import SwiftUI
import Foundation

// MARK: - ヘッダーボタンの設定
struct HeaderButton {
    let title: String
    let action: () -> Void
    let role: ButtonRole
    let isDisabled: Bool

    enum ButtonRole {
        case normal          // 通常のボタン（セカンダリカラー）
        case primary         // プライマリアクション（アクセントカラー）
        case destructive     // 破壊的アクション（赤系）
        case cancel          // キャンセル系（グレー系）
    }

    init(
        title: String,
        action: @escaping () -> Void,
        role: ButtonRole = .normal,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.action = action
        self.role = role
        self.isDisabled = isDisabled
    }

    var color: Color {
        if isDisabled {
            return .gray
        }

        switch role {
        case .normal, .cancel:
            return DesignTokens.Colors.moonTextSecondary
        case .primary:
            return DesignTokens.Colors.moonAccentBlue
        case .destructive:
            return .red
        }
    }
}

// MARK: - 共通ヘッダーの設定構造体
struct HeaderConfiguration {
    let title: String
    let leftButton: HeaderButton?
    let rightButton: HeaderButton?

    init(
        title: String,
        leftButton: HeaderButton? = nil,
        rightButton: HeaderButton? = nil
    ) {
        self.title = title
        self.leftButton = leftButton
        self.rightButton = rightButton
    }
}

// MARK: - HeaderConfiguration の便利なイニシャライザ
extension HeaderConfiguration {
    // 標準的な Close/Done パターン（dismissを自動処理）
    static func closeDone(
        title: String,
        dismiss: DismissAction? = nil,
        customClose: (() -> Void)? = nil,
        onDone: @escaping () -> Void,
        isDoneDisabled: Bool = false
    ) -> HeaderConfiguration {
        let closeAction = customClose ?? { dismiss?() }

        return HeaderConfiguration(
            title: title,
            leftButton: HeaderButton(
                title: "Close",
                action: closeAction,
                role: .cancel
            ),
            rightButton: HeaderButton(
                title: "Done",
                action: onDone,
                role: .primary,
                isDisabled: isDoneDisabled
            )
        )
    }

    // Cancel/Save パターン（dismissを自動処理）
    static func cancelSave(
        title: String,
        dismiss: DismissAction? = nil,
        customCancel: (() -> Void)? = nil,
        onSave: @escaping () -> Void,
        isSaveDisabled: Bool = false
    ) -> HeaderConfiguration {
        let cancelAction = customCancel ?? { dismiss?() }

        return HeaderConfiguration(
            title: title,
            leftButton: HeaderButton(
                title: "Cancel",
                action: cancelAction,
                role: .cancel
            ),
            rightButton: HeaderButton(
                title: "Save",
                action: onSave,
                role: .primary,
                isDisabled: isSaveDisabled
            )
        )
    }

    // シンプルなdismissのみのCloseボタン
    static func simpleClose(
        title: String,
        dismiss: DismissAction
    ) -> HeaderConfiguration {
        return HeaderConfiguration(
            title: title,
            leftButton: HeaderButton(
                title: "Close",
                action: { dismiss() },
                role: .cancel
            )
        )
    }

    // 右ボタンのみ（戻るナビゲーションがある場合など）
    static func rightButtonOnly(
        title: String,
        rightButtonTitle: String,
        rightButtonAction: @escaping () -> Void,
        rightButtonRole: HeaderButton.ButtonRole = .primary,
        isRightButtonDisabled: Bool = false
    ) -> HeaderConfiguration {
        return HeaderConfiguration(
            title: title,
            rightButton: HeaderButton(
                title: rightButtonTitle,
                action: rightButtonAction,
                role: rightButtonRole,
                isDisabled: isRightButtonDisabled
            )
        )
    }

    // 左ボタンのみ
    static func leftButtonOnly(
        title: String,
        leftButtonTitle: String,
        leftButtonAction: @escaping () -> Void,
        leftButtonRole: HeaderButton.ButtonRole = .cancel
    ) -> HeaderConfiguration {
        return HeaderConfiguration(
            title: title,
            leftButton: HeaderButton(
                title: leftButtonTitle,
                action: leftButtonAction,
                role: leftButtonRole
            )
        )
    }
}
