// 文脈メッセージ：アクション語（OK, Delete…）／プレースホルダ／説明文／警告文など

// 詳細： _guide-copy-classification.md 参照

import Foundation

enum Messages {
    enum Reflection {
        static let placeholder = NSLocalizedString("reflection_placeholder", comment: "Reflection placeholder")
    }

    enum Placeholders {
        static let addReflection = NSLocalizedString(
            "history_memo_add_reflection_placeholder",
            comment: "Add reflection placeholder"
        )
    }
}
