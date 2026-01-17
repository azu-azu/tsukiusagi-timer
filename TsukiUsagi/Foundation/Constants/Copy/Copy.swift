// マイクロコピー（操作要素の定型短文）
// ボタン、タブ、リンク、トグル、スナックの一語/二語表示、短いフォーマット

// 詳細： _guide-copy-classification.md 参照

import Foundation

enum Copy {
    // UI標準ボタン（英語圏の慣用表現）
    enum Button {
        static let cancel = "Cancel"
        static let save = "Save"
        static let close = "Close"
        static let reset = "Reset"
        static let expand = "Expand"
        static let ok = "OK"
        static let delete = "delete".localized
        static let create = "create".localized
        static let retry = "history_inline_reflection_retry_button".localized
        static let edit = "settings_session_edit".localized
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
        static let addCustomSession = "add_custom_session".localized
    }

    // quiet moon
    enum Timer {
        static let startFormat = "Start 🌕 %@"
        static let finalFormat = "Final 🌑 %@"
    }
}
