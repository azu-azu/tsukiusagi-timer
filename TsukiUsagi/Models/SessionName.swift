import Foundation

/// サブタイトル（子）モデル
struct Subtitle: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String

    var internalKey: String {
        text.normalized.lowercased()
    }

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

/// セッション名（親）モデル
struct SessionName: Identifiable, Codable, Hashable {
    let id: UUID
    /// 表示用の元文字列
    var name: String
    /// 内部一意性判定用（lowercased）
    var internalKey: String { name.lowercased() }
    /// サブタイトル一覧
    var subtitles: [Subtitle] = []

    /// 表示用（displayName）
    var displayName: String { name }

    init(id: UUID = UUID(), name: String, subtitles: [Subtitle] = []) {
        self.id = id
        self.name = name
        self.subtitles = subtitles
    }

    // Equatable/Hashable: internalKeyで比較
    static func == (lhs: SessionName, rhs: SessionName) -> Bool {
        lhs.internalKey == rhs.internalKey
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(internalKey)
    }
}

extension String {
    var normalized: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

// MARK: - 上限定数

extension SessionName {
    /// 親（SessionName）の最大数
    static let parentLimit = 50
    /// 子（Subtitle）の最大数
    static let childLimit = 50
}
