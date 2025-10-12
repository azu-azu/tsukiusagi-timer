// 見出し・セクションタイトル
//
// 【使用ルール】
// - 文脈として英語が適切な文字列 → Labels.swift に定義
//   (技術用語、ブランド名、固有名詞、英語圏の慣用表現など)
// - 翻訳が必要な文字列 → NSLocalizedString を使用
//   (ユーザー向けメッセージ、ボタンラベル、説明文など)

import Foundation

enum Labels {
    // タイマー関連の見出し・フォーマット
    enum Timer {
        static let startFormat = "Start 🌕 %@"
        static let finalFormat = "Final 🌑 %@"
    }
}
