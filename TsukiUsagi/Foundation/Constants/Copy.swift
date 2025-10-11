// アプリ全体のテキストコピー（文言定義）を一元管理する
//
// 【使用ルール】
// - 文脈として英語が適切な文字列 → Copy.swift に定義
//   (技術用語、ブランド名、固有名詞、英語圏の慣用表現など)
// - 翻訳が必要な文字列 → NSLocalizedString を使用
//   (ユーザー向けメッセージ、ボタンラベル、説明文など)
//
// 注意: Copy.swiftの定数は全てLocalizable.stringsに移行されました。
// 新しい文字列は直接NSLocalizedStringを使用してください。

import Foundation

enum Copy {
    // このenumは非推奨です。新しい文字列はLocalizable.stringsに定義してください。
    @available(*, deprecated, message: "Use NSLocalizedString with keys from Localizable.strings instead")
    enum Reflection {
        static let title = NSLocalizedString("reflection_title", comment: "Reflection title")
        static let placeholder = NSLocalizedString("reflection_placeholder", comment: "Reflection placeholder")
    }

    // 文脈として英語が適切な文字列（英語圏の慣用表現）
    enum Timer {
        static let startFormat = "Start 🌕 %@"
        static let finalFormat = "Final 🌑 %@"
    }

    // UI標準ボタン（英語圏の慣用表現）
    enum Button {
        static let cancel = "Cancel"
        static let save = "Save"
        static let close = "Close"
        static let reset = "Reset"
    }

    // UI標準ラベル（英語圏の慣用表現）
    enum Label {
        static let time = "Time:"
        static let total = "Total: %@"
        static let saved = "Saved"
    }

    // UI標準タブ（英語圏の慣用表現）
    enum Tab {
        static let daily = "Daily"
        static let monthly = "Monthly"
    }

    // UI標準リンク（英語圏の慣用表現）
    enum Link {
        static let openDaily = "Open Daily Reflection"
    }
}
