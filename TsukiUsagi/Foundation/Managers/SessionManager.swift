import Combine
import Foundation

/// セッション管理の中核クラス
///
/// 責務:
/// - セッションデータベースの管理
/// - デフォルト/カスタムセッションの区別
/// - 基本的なCRUD操作
/// - 永続化の管理
/// - サイドメニュー状態の管理
class SessionManager: ObservableObject {
    // MARK: - Constants

    static let maxSessionCount = 50
    static let maxTaskCount = 50
    static let maxNameLength = 30
    static let maxTaskLength = 30

    @available(*, deprecated, message: "Use maxTaskCount instead.")
    static var maxDescriptionCount: Int { maxTaskCount }

    @available(*, deprecated, message: "Use maxTaskLength instead.")
    static var maxDescriptionLength: Int { maxTaskLength }

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

    // MARK: - Published Properties

    /// sessionName(lowercased)をキーとするセッションデータベース
    @Published var sessionDatabase: [String: SessionEntry] = [:]

    /// サイドメニューを開くリクエストフラグ
    @Published var shouldOpenSideMenuOnDismiss: Bool = false

    // MARK: - Computed Properties

    /// デフォルトセッション一覧（順序保持）
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

    /// カスタムセッション一覧（アルファベット順）
    var customEntries: [SessionEntry] {
        sessionDatabase.values.filter {
            !defaultSessionNames.contains($0.sessionName) && !$0.isDefault
        }.sorted { $0.sessionName < $1.sessionName }
    }

    /// 全セッション一覧（デフォルト + カスタム）
    var allEntries: [SessionEntry] {
        (defaultEntries + customEntries)
    }

    // MARK: - Initialization

    init() {
        load()
        initializeDefaultSessions()
    }

    /// デフォルトセッションの初期化処理
    private func initializeDefaultSessions() {
        for name in defaultSessionNames {
            let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if sessionDatabase[key] == nil {
                // デフォルトセッションが存在しないときのみ追加
                let entry = SessionEntry(
                    id: UUID(),
                    sessionName: name,
                    tasks: [],
                    isDefault: true
                )
                sessionDatabase[key] = entry
            } else if sessionDatabase[key]?.isDefault == false {
                // デフォルトセッションとして正しくマークしておく
                let existingEntry = sessionDatabase[key]!
                let correctedEntry = SessionEntry(
                    id: existingEntry.id,
                    sessionName: existingEntry.sessionName,
                    tasks: existingEntry.tasks,
                    isDefault: true
                )
                sessionDatabase[key] = correctedEntry
                save() // 修正内容を永続化
            }
        }
    }

    // MARK: - Side Menu Management

    /// サイドメニューを開くリクエストを送る
    func requestSideMenuOnDismiss() {
        shouldOpenSideMenuOnDismiss = true
    }

    /// サイドメニューリクエストをリセット
    func resetSideMenuRequest() {
        shouldOpenSideMenuOnDismiss = false
    }

    // MARK: - Basic Operations

    /// 指定されたセッション名のタスク一覧を取得
    func getTasks(for sessionName: String) -> [String] {
        let key = sessionName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return sessionDatabase[key]?.tasks ?? []
    }

    @available(*, deprecated, message: "Use getTasks(for:) instead.")
    func getDescriptions(for sessionName: String) -> [String] {
        getTasks(for: sessionName)
    }

    /// セッションエントリの追加または更新
    func addOrUpdateEntry(
        originalKey: String,
        sessionName: String,
        tasks: [String]
    ) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newKey = trimmedName.lowercased()
        let oldKey = originalKey.trimmingCharacters(in: .whitespacesAndNewlines)

        let canonicalTasks = tasks.map { $0.tsu_taskNormalizedValue }

        // バリデーション実行
        let validationContext = SessionValidationContext(
            isNewSession: sessionDatabase[newKey] == nil,
            currentCustomCount: customEntries.count,
            isDefaultSession: defaultSessionNames.contains(trimmedName),
            existingEntry: sessionDatabase[newKey],
            oldKey: oldKey,
            newKey: newKey
        )

        try SessionManagerValidator.validateSessionEntry(
            sessionName: trimmedName,
            tasks: canonicalTasks,
            validationContext: validationContext
        )

        let isDefault = defaultSessionNames.contains(trimmedName)
        let entry = SessionEntry(
            id: sessionDatabase[oldKey]?.id ?? UUID(),
            sessionName: trimmedName,
            tasks: canonicalTasks,
            isDefault: isDefault
        )

        // キーが変わった場合は元のエントリを削除
        if oldKey != newKey {
            sessionDatabase.removeValue(forKey: oldKey)
        }
        sessionDatabase[newKey] = entry
        save()
    }

    @available(*, deprecated, message: "Use addOrUpdateEntry(originalKey:sessionName:tasks:) instead.")
    func addOrUpdateEntry(
        originalKey: String,
        sessionName: String,
        descriptions: [String]
    ) throws {
        try addOrUpdateEntry(originalKey: originalKey, sessionName: sessionName, tasks: descriptions)
    }

    /// セッションエントリの削除（デフォルトセッションは削除不可）
    func deleteEntry(id: UUID) {
        for entry in sessionDatabase.values
            where entry.id == id && !entry.isDefault {
            sessionDatabase.removeValue(
                forKey: entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
            break
        }
        save()
    }

    // MARK: - Persistence

    /// データの永続化
    internal func save() {
        let allSessionEntries = Array(sessionDatabase.values)
        do {
            let data = try JSONEncoder().encode(allSessionEntries)
            UserDefaults.standard.set(data, forKey: "allSessionEntriesV3")
        } catch {
            #if DEBUG
            print("[session_save_failed] \(error.localizedDescription)")
            #endif
        }
    }

    /// データの読み込み（マイグレーション処理含む）
    private func load() {
        // V3形式のデータを読み込み
        if let data = UserDefaults.standard.data(forKey: "allSessionEntriesV3"),
            let decoded = try? JSONDecoder().decode([SessionEntry].self, from: data) {
            sessionDatabase.removeAll()
            var didSanitize = false
            for entry in decoded where !entry.sessionName.isEmpty {
                let key = entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let (sanitized, changed) = sanitizeEntry(entry)
                sessionDatabase[key] = sanitized
                if changed { didSanitize = true }
            }
            if didSanitize {
                save()
            }
            return
        }

        // 既存データからのマイグレーション処理
        migrateLegacyData()
    }

    private func sanitizeEntry(_ entry: SessionEntry) -> (SessionEntry, Bool) {
        var seen = Set<String>()
        var sanitized: [String] = []

        for task in entry.tasks {
            let canonical = task.tsu_taskNormalizedValue
            let key = canonical.tsu_taskNormalizedKey
            if seen.contains(key) {
                continue
            }
            seen.insert(key)
            sanitized.append(canonical)
        }

        let changed = sanitized != entry.tasks
        let sanitizedEntry = SessionEntry(
            id: entry.id,
            sessionName: entry.sessionName,
            tasks: sanitized,
            isDefault: entry.isDefault
        )
        return (sanitizedEntry, changed)
    }

    /// 旧形式データのマイグレーション
    private func migrateLegacyData() {
        if let data = UserDefaults.standard.data(forKey: "customEntriesV2"),
            let decoded = try? JSONDecoder().decode([SessionEntry].self, from: data) {
            var didSanitize = false
            for entry in decoded where !entry.sessionName.isEmpty {
                let key = entry.sessionName
                    .lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let (sanitized, changed) = sanitizeEntry(entry)
                sessionDatabase[key] = sanitized
                if changed { didSanitize = true }
            }
            if didSanitize {
                save()
            }
            // 古いデータを削除
            UserDefaults.standard.removeObject(forKey: "customEntriesV2")
        }
    }
}
