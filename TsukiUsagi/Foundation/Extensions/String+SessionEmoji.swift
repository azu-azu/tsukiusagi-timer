//
//  String+SessionEmoji.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import Foundation

/// セッション名・タスク名に絵文字を付与するためのユーティリティ
enum SessionEmoji {
    /// セッション用絵文字
    static let session = "🔖"
    /// タスク用絵文字
    static let task = "📌"
}

extension String {
    /// セッション名に絵文字を付与して表示用文字列を返す
    var withSessionEmoji: String {
        guard !self.isEmpty else { return self }
        return "\(SessionEmoji.session) \(self)"
    }

    /// タスク名に絵文字を付与して表示用文字列を返す
    var withTaskEmoji: String {
        guard !self.isEmpty else { return self }
        return "\(SessionEmoji.task) \(self)"
    }
}
