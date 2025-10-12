// 短文・UIテキスト（ボタン、ラベル、タブ、リンクなど）
//
// 【使用ルール】
// - 文脈として英語が適切な文字列 → Copy.swift に定義
//   (技術用語、ブランド名、固有名詞、英語圏の慣用表現など)
// - 翻訳が必要な文字列 → NSLocalizedString を使用
//   (ユーザー向けメッセージ、ボタンラベル、説明文など)

import Foundation

enum Copy {
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
