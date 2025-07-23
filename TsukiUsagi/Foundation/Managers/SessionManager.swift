import Combine
import Foundation

class SessionManager: ObservableObject {
    // 定数一元管理
    static let maxSessionCount = 50
    static let maxDescriptionCount = 50
    static let maxNameLength = 30
    static let maxDescriptionLength = 30

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
        // デフォルトセッションがなければ追加（永続化されたものがあればそれを優先）
        for name in defaultSessionNames {
            let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if sessionDatabase[key] == nil {
                // デフォルトセッションが存在しないときのみ追加
                let entry = SessionEntry(
                    id: UUID(),
                    sessionName: name,
                    descriptions: [],
                    isDefault: true
                )
                sessionDatabase[key] = entry
            } else if sessionDatabase[key]?.isDefault == false {
                // デフォルトセッションとして正しくマークしておく
                let existingEntry = sessionDatabase[key]!
                let correctedEntry = SessionEntry(
                    id: existingEntry.id,
                    sessionName: existingEntry.sessionName,
                    descriptions: existingEntry.descriptions,
                    isDefault: true // 正しくデフォルトとしてマーク
                )
                sessionDatabase[key] = correctedEntry
                save() // 修正内容を永続化
            }
        }
    }

    // 説明（description）取得
    func getDescriptions(for sessionName: String) -> [String] {
        let key = sessionName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return sessionDatabase[key]?.descriptions ?? []
    }

    // エラー定義
    enum SessionManagerError: Error, LocalizedError {
        case duplicateName
        case sessionLimitExceeded
        case descriptionLimitExceeded
        case nameTooLong
        case descriptionTooLong
        case notFound
        case duplicateDescription

        var errorDescription: String? {
            switch self {
            case .duplicateName:
                return "This session name is already registered."
            case .sessionLimitExceeded:
                return "You have reached the maximum number of sessions."
            case .descriptionLimitExceeded:
                return "You have reached the maximum number of descriptions."
            case .nameTooLong:
                return "Session name is too long."
            case .descriptionTooLong:
                return "Description is too long."
            case .notFound:
                return "Session not found."
            case .duplicateDescription:
                return "Duplicate descriptions are not allowed."
            }
        }
    }

    func addOrUpdateEntry(
        originalKey: String,
        sessionName: String,
        descriptions: [String]
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
           !defaultSessionNames.contains(trimmedName) {
            // 元のキーと違う場合のみ重複エラー
            if newKey != oldKey && !existing.isDefault {
                throw SessionManagerError.duplicateName
            }
        }

        // 説明最大数
        if descriptions.count > Self.maxDescriptionCount {
            throw SessionManagerError.descriptionLimitExceeded
        }

        // 説明文字数
        for description in descriptions where description.count > Self.maxDescriptionLength {
            throw SessionManagerError.descriptionTooLong
        }

        let isDefault = defaultSessionNames.contains(trimmedName)
        let entry = SessionEntry(
            id: sessionDatabase[oldKey]?.id ?? UUID(),
            sessionName: trimmedName,
            descriptions: descriptions,
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
            where entry.id == id && !entry.isDefault { // デフォルトは削除不可
            sessionDatabase.removeValue(
                forKey: entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
            break
        }
        save()
    }

    // --- 永続化（修正版：デフォルトセッションも含める） ---
    private func save() {
        // 全セッションを永続化する
        let allSessionEntries = Array(sessionDatabase.values)
        if let data = try? JSONEncoder().encode(allSessionEntries) {
            UserDefaults.standard.set(data, forKey: "allSessionEntriesV3") // キー名変更
        }
    }

    private func load() {
        // --- マイグレーション処理: subtitles→descriptions ---
        if let data = UserDefaults.standard.data(forKey: "allSessionEntriesV3"),
           let decoded = try? JSONDecoder().decode([SessionEntry].self, from: data) {
            sessionDatabase.removeAll()
            for entry in decoded where !entry.sessionName.isEmpty {
                let key = entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                sessionDatabase[key] = entry
            }
            return
        }

        // 既存のカスタムセッションデータがあれば移行（互換性のため）
        if let data = UserDefaults.standard.data(forKey: "customEntriesV2"),
           let decoded = try? JSONDecoder().decode([SessionEntry].self, from: data) {
            for entry in decoded where !entry.sessionName.isEmpty {
                let key = entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                sessionDatabase[key] = entry
            }
            // 移行後は新しいキーで保存
            save()
            // 古いデータを削除
            UserDefaults.standard.removeObject(forKey: "customEntriesV2")
        }
    }
}

// MARK: - Description Management Extension

extension SessionManager {

    /// 指定されたセッションのDescription配列を完全に更新する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - newDescriptions: 新しいDescription配列
    func updateSessionDescriptions(sessionName: String, newDescriptions: [String]) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // バリデーション
        if newDescriptions.count > Self.maxDescriptionCount {
            throw SessionManagerError.descriptionLimitExceeded
        }

        for description in newDescriptions where description.count > Self.maxDescriptionLength {
            throw SessionManagerError.descriptionTooLong
        }

        // Descriptionのみ更新（他のプロパティは保持）
        let updatedEntry = SessionEntry(
            id: existingEntry.id,
            sessionName: existingEntry.sessionName,
            descriptions: newDescriptions,
            isDefault: existingEntry.isDefault
        )

        sessionDatabase[key] = updatedEntry
        save() // デフォルトセッションも永続化される
    }

    /// 指定されたセッションにDescriptionを追加する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - newDescription: 追加するDescription
    func addDescriptionToSession(sessionName: String, newDescription: String) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()
        let trimmedDescription = newDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // バリデーション
        if existingEntry.descriptions.count >= Self.maxDescriptionCount {
            throw SessionManagerError.descriptionLimitExceeded
        }

        if trimmedDescription.count > Self.maxDescriptionLength {
            throw SessionManagerError.descriptionTooLong
        }

        // 新しいDescription配列を作成
        var newDescriptions = existingEntry.descriptions
        newDescriptions.append(trimmedDescription)

        // 更新
        try updateSessionDescriptions(sessionName: sessionName, newDescriptions: newDescriptions)
    }

    /// 指定されたセッションの特定のDescriptionを更新する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - index: 更新するDescriptionのインデックス
    ///   - newDescription: 新しいDescriptionテキスト
    func updateDescription(sessionName: String, at index: Int, newDescription: String) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()
        let trimmedDescription = newDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // インデックスチェック
        guard index >= 0 && index < existingEntry.descriptions.count else {
            throw SessionManagerError.notFound
        }

        // バリデーション
        if trimmedDescription.count > Self.maxDescriptionLength {
            throw SessionManagerError.descriptionTooLong
        }

        // 新しいDescription配列を作成
        var newDescriptions = existingEntry.descriptions
        newDescriptions[index] = trimmedDescription

        // 更新
        try updateSessionDescriptions(sessionName: sessionName, newDescriptions: newDescriptions)
    }

    /// 指定されたセッションからDescriptionを削除する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - index: 削除するDescriptionのインデックス
    func removeDescription(sessionName: String, at index: Int) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()

        // 既存のエントリを確認
        guard let existingEntry = sessionDatabase[key] else {
            throw SessionManagerError.notFound
        }

        // インデックスチェック
        guard index >= 0 && index < existingEntry.descriptions.count else {
            throw SessionManagerError.notFound
        }

        // 新しいDescription配列を作成
        var newDescriptions = existingEntry.descriptions
        newDescriptions.remove(at: index)

        // 更新
        try updateSessionDescriptions(sessionName: sessionName, newDescriptions: newDescriptions)
    }
}

#if DEBUG
extension SessionManager {
    static var previewData: SessionManager {
        let manager = SessionManager()
        let samples: [SessionEntry] = [
            SessionEntry(
                sessionName: "Sample Session 1",
                descriptions: ["Test description"],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Sample Session 2",
                descriptions: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Multi Description Session",
                descriptions: [
                    "First description",
                    "Second description",
                    "Third description"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "No Description Session",
                descriptions: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName:
                    "This is a very long session name to test how the UI handles overflow " +
                    "and wrapping in the list row",
                descriptions: [
                    "Long description for testing purposes"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Special!@#¥%&*()_+{}|:<>? Session",
                descriptions: ["Emoji 😊🚀✨", "Symbols #$%&"],
                isDefault: false
            ),
            SessionEntry(sessionName: "Session 3", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 4", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 5", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 6", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 7", descriptions: [], isDefault: false)
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
