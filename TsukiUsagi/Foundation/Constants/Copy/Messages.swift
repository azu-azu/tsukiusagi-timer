// 文脈メッセージ：アクション語（OK, Delete…）／プレースホルダ／説明文／警告文など

// 詳細： _guide-copy-classification.md 参照

import Foundation

enum Messages {
    enum Reflection {
        static let placeholder = "reflection_placeholder".localized
    }

    enum Placeholders {
        static let addReflection = "history_memo_add_reflection_placeholder".localized
    }
}
