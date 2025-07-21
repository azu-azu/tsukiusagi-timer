import Combine
import Foundation

class SessionManager: ObservableObject {
    // 定数一元管理
    static let maxSessionCount = 50
    static let maxSubtitleCount = 50
    static let maxNameLength = 30 // 文字数制限（将来UIにも反映）
    static let maxSubtitleLength = 30

    // デフォルトセッション名（順序保持）
    let defaultSessionNames: Set<String> = [
        "Work",
        "Study",
        "Read"
    ]
    let defaultSessionOrder: [String] = [
        "Work",
        "Study",
        "Read"
    ]

    // sessionName(lowercased)をキー
    @Published var sessionDatabase: [String: SessionEntry] = [:]

    // デフォルト/カスタム区別
    var defaultEntries: [SessionEntry] {
        let filtered = sessionDatabase.values.filter {
            defaultSessionNames.contains($0.sessionName) && $0.isDefault
        }
        return filtered.sorted { entry1, entry2 in
            let index1 = defaultSessionOrder.firstIndex(of: entry1.sessionName) ?? Int.max
            let index2 = defaultSessionOrder.firstIndex(of: entry2.sessionName) ?? Int.max
            return index1 < index2
        }
    }
    var customEntries: [SessionEntry] {
        sessionDatabase.values.filter {
            !defaultSessionNames.contains($0.sessionName) && !$0.isDefault
        }.sorted { $0.sessionName < $1.sessionName }
    }
    var allEntries: [SessionEntry] {
        (defaultEntries + customEntries)
    }

    init() {
        load()
        // デフォルトセッションがなければ追加
        for name in defaultSessionNames
            where sessionDatabase[
                name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            ] == nil
        {
            let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let entry = SessionEntry(
                id: UUID(),
                sessionName: name,
                subtitles: [],
                isDefault: true
            )
            sessionDatabase[key] = entry
        }
    }

    // サブタイトル取得
    func getSubtitles(for sessionName: String) -> [String] {
        let key = sessionName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return sessionDatabase[key]?.subtitles ?? []
    }

    // 追加・更新
    enum SessionManagerError: Error, LocalizedError {
        case duplicateName
        case sessionLimitExceeded
        case subtitleLimitExceeded
        case nameTooLong
        case subtitleTooLong
        case notFound
        case duplicateSubtitle

        var errorDescription: String? {
            switch self {
            case .duplicateName:
                return "This session name is already registered."
            case .sessionLimitExceeded:
                return "You have reached the maximum number of sessions."
            case .subtitleLimitExceeded:
                return "You have reached the maximum number of subtitles."
            case .nameTooLong:
                return "Session name is too long."
            case .subtitleTooLong:
                return "Subtitle is too long."
            case .notFound:
                return "Session not found."
            case .duplicateSubtitle:
                return "Duplicate subtitles are not allowed."
            }
        }
    }

    func addOrUpdateEntry(
        originalKey: String,
        sessionName: String,
        subtitles: [String]
    ) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newKey = trimmedName.lowercased()
        let oldKey = originalKey.trimmingCharacters(in: .whitespacesAndNewlines)
        // バリデーション
        if trimmedName.count > Self.maxNameLength {
            throw SessionManagerError.nameTooLong
        }
        if !defaultSessionNames.contains(trimmedName) &&
            customEntries.count >= Self.maxSessionCount &&
            sessionDatabase[newKey] == nil {
            throw SessionManagerError.sessionLimitExceeded
        }
        // 重複禁止（空文字でない場合のみチェック）
        if !trimmedName.isEmpty,
           let existing = sessionDatabase[newKey],
           !defaultSessionNames.contains(trimmedName)
        {
            // 元のキーと違う場合のみ重複エラー
            if newKey != oldKey && !existing.isDefault {
                throw SessionManagerError.duplicateName
            }
        }
        // サブタイトル最大数
        if subtitles.count > Self.maxSubtitleCount {
            throw SessionManagerError.subtitleLimitExceeded
        }
        // サブタイトル文字数
        for subtitle in subtitles where subtitle.count > Self.maxSubtitleLength {
            throw SessionManagerError.subtitleTooLong
        }
        // サブタイトル重複禁止（現状は許容、将来有効化）
        // let uniqueCount = Set(subtitles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }).count
        // if uniqueCount != subtitles.count { throw SessionManagerError.duplicateSubtitle }

        let isDefault = defaultSessionNames.contains(trimmedName)
        let entry = SessionEntry(
            id: sessionDatabase[oldKey]?.id ?? UUID(),
            sessionName: trimmedName,
            subtitles: subtitles,
            isDefault: isDefault
        )
        // キーが変わった場合は元のエントリを削除
        if oldKey != newKey {
            sessionDatabase.removeValue(forKey: oldKey)
        }
        sessionDatabase[newKey] = entry
        save()
    }

    func deleteEntry(id: UUID) {
        for entry in sessionDatabase.values
            where entry.id == id && !entry.isDefault // デフォルトは削除不可
        {
            sessionDatabase.removeValue(
                forKey: entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
            break
        }
        save()
    }

    // --- 永続化 ---
    private func save() {
        let custom = customEntries
        if let data = try? JSONEncoder().encode(custom) {
            UserDefaults.standard.set(data, forKey: "customEntriesV2")
        }
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: "customEntriesV2"),
           let decoded = try? JSONDecoder().decode([SessionEntry].self, from: data) {
            for entry in decoded where !entry.sessionName.isEmpty {
                let key = entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                sessionDatabase[key] = entry
            }
        }
    }
}

// MARK: - Subtitle Management Extension

extension SessionManager {

    /// 指定されたセッションのSubtitle配列を完全に更新する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - newSubtitles: 新しいSubtitle配列
    func updateSessionSubtitles(sessionName: String, newSubtitles: [String]) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // バリデーション
        if newSubtitles.count > Self.maxSubtitleCount {
            throw SessionManagerError.subtitleLimitExceeded
        }

        for subtitle in newSubtitles where subtitle.count > Self.maxSubtitleLength {
            throw SessionManagerError.subtitleTooLong
        }

        // Subtitleのみ更新（他のプロパティは保持）
        let updatedEntry = SessionEntry(
            id: existingEntry.id,
            sessionName: existingEntry.sessionName,
            subtitles: newSubtitles,
            isDefault: existingEntry.isDefault
        )

        sessionDatabase[key] = updatedEntry
        save()
    }

    /// 指定されたセッションにSubtitleを追加する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - newSubtitle: 追加するSubtitle
    func addSubtitleToSession(sessionName: String, newSubtitle: String) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()
        let trimmedSubtitle = newSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // バリデーション
        if existingEntry.subtitles.count >= Self.maxSubtitleCount {
            throw SessionManagerError.subtitleLimitExceeded
        }

        if trimmedSubtitle.count > Self.maxSubtitleLength {
            throw SessionManagerError.subtitleTooLong
        }

        // 新しいSubtitle配列を作成
        var newSubtitles = existingEntry.subtitles
        newSubtitles.append(trimmedSubtitle)

        // 更新
        try updateSessionSubtitles(sessionName: sessionName, newSubtitles: newSubtitles)
    }

    /// 指定されたセッションの特定のSubtitleを更新する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - index: 更新するSubtitleのインデックス
    ///   - newSubtitle: 新しいSubtitleテキスト
    func updateSubtitle(sessionName: String, at index: Int, newSubtitle: String) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()
        let trimmedSubtitle = newSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // インデックスチェック
        guard index >= 0 && index < existingEntry.subtitles.count else {
            throw SessionManagerError.notFound
        }

        // バリデーション
        if trimmedSubtitle.count > Self.maxSubtitleLength {
            throw SessionManagerError.subtitleTooLong
        }

        // 新しいSubtitle配列を作成
        var newSubtitles = existingEntry.subtitles
        newSubtitles[index] = trimmedSubtitle

        // 更新
        try updateSessionSubtitles(sessionName: sessionName, newSubtitles: newSubtitles)
    }

    /// 指定されたセッションからSubtitleを削除する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - index: 削除するSubtitleのインデックス
    func removeSubtitle(sessionName: String, at index: Int) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // インデックスチェック
        guard index >= 0 && index < existingEntry.subtitles.count else {
            throw SessionManagerError.notFound
        }

        // 新しいSubtitle配列を作成
        var newSubtitles = existingEntry.subtitles
        newSubtitles.remove(at: index)

        // 更新
        try updateSessionSubtitles(sessionName: sessionName, newSubtitles: newSubtitles)
    }
}

#if DEBUG
extension SessionManager {
    static var previewData: SessionManager {
        let manager = SessionManager()
        let samples: [SessionEntry] = [
            SessionEntry(
                sessionName: "Sample Session 1",
                subtitles: ["Test subtitle"],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Sample Session 2",
                subtitles: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Multi Subtitle Session",
                subtitles: [
                    "First subtitle",
                    "Second subtitle",
                    "Third subtitle"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "No Subtitle Session",
                subtitles: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName:
                    "This is a very long session name to test how the UI handles overflow " +
                    "and wrapping in the list row",
                subtitles: [
                    "Long subtitle for testing purposes"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Special!@#¥%&*()_+{}|:<>? Session",
                subtitles: ["Emoji 😊🚀✨", "Symbols #$%&"],
                isDefault: false
            ),
            SessionEntry(sessionName: "Session 3", subtitles: [], isDefault: false),
            SessionEntry(sessionName: "Session 4", subtitles: [], isDefault: false),
            SessionEntry(sessionName: "Session 5", subtitles: [], isDefault: false),
            SessionEntry(sessionName: "Session 6", subtitles: [], isDefault: false),
            SessionEntry(sessionName: "Session 7", subtitles: [], isDefault: false)
        ]
        for entry in samples {
            let key = entry.sessionName
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            manager.sessionDatabase[key] = entry
        }
        return manager
    }
}
#endif
