import Foundation

/// SessionManagerのDescription管理機能拡張
///
/// 責務:
/// - Description配列の完全更新
/// - 個別Descriptionの追加/更新/削除
/// - Description操作のバリデーション
extension SessionManager {

    /// 指定されたセッションのDescription配列を完全に更新する
    /// - Parameters:
    ///   - sessionName: セッション名
    ///   - newDescriptions: 新しいDescription配列
    func updateSessionDescriptions(sessionName: String, newDescriptions: [String]) throws {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmedName.lowercased()

        // 既存のエントリを確認
        let existingEntry = sessionDatabase[key]
        try SessionManagerValidator.validateSessionExists(existingEntry)

        guard let entry = existingEntry else {
            throw SessionManagerError.notFound
        }

        // Descriptionバリデーション
        try SessionManagerValidator.validateDescriptions(newDescriptions)

        // Descriptionのみ更新（他のプロパティは保持）
        let updatedEntry = SessionEntry(
            id: entry.id,
            sessionName: entry.sessionName,
            descriptions: newDescriptions,
            isDefault: entry.isDefault
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
        let existingEntry = sessionDatabase[key]
        try SessionManagerValidator.validateSessionExists(existingEntry)

        guard let entry = existingEntry else {
            throw SessionManagerError.notFound
        }

        // Description数制限チェック
        if entry.descriptions.count >= Self.maxDescriptionCount {
            throw SessionManagerError.descriptionLimitExceeded
        }

        // Description文字数チェック
        if trimmedDescription.count > Self.maxDescriptionLength {
            throw SessionManagerError.descriptionTooLong
        }

        // 新しいDescription配列を作成
        var newDescriptions = entry.descriptions
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
        let existingEntry = sessionDatabase[key]
        try SessionManagerValidator.validateSessionExists(existingEntry)

        guard let entry = existingEntry else {
            throw SessionManagerError.notFound
        }

        // インデックスチェック
        try SessionManagerValidator.validateIndex(index, for: entry.descriptions)

        // Description文字数チェック
        if trimmedDescription.count > Self.maxDescriptionLength {
            throw SessionManagerError.descriptionTooLong
        }

        // 新しいDescription配列を作成
        var newDescriptions = entry.descriptions
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
        let existingEntry = sessionDatabase[key]
        try SessionManagerValidator.validateSessionExists(existingEntry)

        guard let entry = existingEntry else {
            throw SessionManagerError.notFound
        }

        // インデックスチェック
        try SessionManagerValidator.validateIndex(index, for: entry.descriptions)

        // 新しいDescription配列を作成
        var newDescriptions = entry.descriptions
        newDescriptions.remove(at: index)

        // 更新
        try updateSessionDescriptions(sessionName: sessionName, newDescriptions: newDescriptions)
    }
}
