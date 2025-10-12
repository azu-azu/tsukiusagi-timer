// ユーザーへのメッセージ・詩的文
//
// 【使用ルール】
// - 文脈として英語が適切な文字列 → Messages.swift に定義
//   (技術用語、ブランド名、固有名詞、英語圏の慣用表現など)
// - 翻訳が必要な文字列 → NSLocalizedString を使用
//   (ユーザー向けメッセージ、ボタンラベル、説明文など)

import Foundation

enum Messages {
    // このenumは非推奨です。新しい文字列はLocalizable.stringsに定義してください。
    @available(*, deprecated, message: "Use NSLocalizedString with keys from Localizable.strings instead")
    enum Reflection {
        static let title = NSLocalizedString("reflection_title", comment: "Reflection title")
        static let placeholder = NSLocalizedString("reflection_placeholder", comment: "Reflection placeholder")
    }
}
