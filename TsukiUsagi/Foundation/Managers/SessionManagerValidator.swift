import Foundation

/// バリデーション時に必要な文脈情報をまとめた構造体
struct SessionValidationContext {
    let isNewSession: Bool
    let currentCustomCount: Int
    let isDefaultSession: Bool
    let existingEntry: SessionEntry?
    let oldKey: String
    let newKey: String
}

/// セッション管理のエラー
enum SessionManagerError: Error {
    case notFound
    case descriptionLimitExceeded
    case descriptionTooLong

    var localizedDescription: String {
        switch self {
        case .notFound:
            return "セッションが見つかりません"
        case .descriptionLimitExceeded:
            return "説明の数が上限に達しています（最大\(SessionManager.maxDescriptionCount)個）"
        case .descriptionTooLong:
            return "説明が長すぎます（最大\(SessionManager.maxDescriptionLength)文字）"
        }
    }
}

/// セッションバリデーションエラー
enum SessionValidationError: Error {
    case emptySessionName
    case sessionNameTooLong
    case maxSessionCountExceeded
    case duplicateSessionName
    case tooManyDescriptions
    case descriptionTooLong
    case sessionNotFound
    case invalidIndex

    var localizedDescription: String {
        switch self {
        case .emptySessionName:
            return "セッション名が空です"
        case .sessionNameTooLong:
            return "セッション名が長すぎます（最大\(SessionManager.maxNameLength)文字）"
        case .maxSessionCountExceeded:
            return "セッション数が上限に達しています（最大\(SessionManager.maxSessionCount)個）"
        case .duplicateSessionName:
            return "同じ名前のセッションが既に存在します"
        case .tooManyDescriptions:
            return "説明が多すぎます（最大\(SessionManager.maxDescriptionCount)個）"
        case .descriptionTooLong:
            return "説明が長すぎます（最大\(SessionManager.maxDescriptionLength)文字）"
        case .sessionNotFound:
            return "指定されたセッションが見つかりません"
        case .invalidIndex:
            return "無効なインデックスです"
        }
    }
}

/// セッション管理のバリデーションを行うクラス
class SessionManagerValidator {

    /// セッションエントリのバリデーション
    static func validateSessionEntry(
        sessionName: String,
        descriptions: [String],
        validationContext: SessionValidationContext
    ) throws {

        // セッション名の検証
        try validateSessionName(sessionName, context: validationContext)

        // 説明の検証
        try validateDescriptionsInternal(descriptions)
    }

    /// セッション名のバリデーション
    private static func validateSessionName(
        _ sessionName: String,
        context: SessionValidationContext
    ) throws {

        // 空文字チェック
        guard !sessionName.isEmpty else {
            throw SessionValidationError.emptySessionName
        }

        // 文字数制限チェック
        guard sessionName.count <= SessionManager.maxNameLength else {
            throw SessionValidationError.sessionNameTooLong
        }

        // 新規セッション時のカウント制限チェック
        if context.isNewSession && !context.isDefaultSession {
            guard context.currentCustomCount < SessionManager.maxSessionCount else {
                throw SessionValidationError.maxSessionCountExceeded
            }
        }

        // 同名セッションの重複チェック（キー変更時）
        if context.oldKey != context.newKey && context.existingEntry != nil {
            throw SessionValidationError.duplicateSessionName
        }
    }

    /// セッションの存在チェック（SessionEntry?版）
    static func validateSessionExists(_ entry: SessionEntry?) throws {
        guard entry != nil else {
            throw SessionValidationError.sessionNotFound
        }
    }

    /// セッションの存在チェック（sessionName版）
    static func validateSessionExists(sessionName: String, in sessionDatabase: [String: SessionEntry]) throws {
        let key = sessionName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard sessionDatabase[key] != nil else {
            throw SessionValidationError.sessionNotFound
        }
    }

    /// インデックスの妥当性チェック
    static func validateIndex(_ index: Int, for descriptions: [String]) throws {
        guard index >= 0 && index < descriptions.count else {
            throw SessionValidationError.invalidIndex
        }
    }

    /// 説明のバリデーション（public版）
    static func validateDescriptions(_ descriptions: [String]) throws {
        try validateDescriptionsInternal(descriptions)
    }

    /// 説明のバリデーション（内部用）
    private static func validateDescriptionsInternal(_ descriptions: [String]) throws {

        // 説明数の制限チェック
        guard descriptions.count <= SessionManager.maxDescriptionCount else {
            throw SessionValidationError.tooManyDescriptions
        }

        // 各説明の文字数チェック
        for description in descriptions {
            guard description.count <= SessionManager.maxDescriptionLength else {
                throw SessionValidationError.descriptionTooLong
            }
        }
    }
}
