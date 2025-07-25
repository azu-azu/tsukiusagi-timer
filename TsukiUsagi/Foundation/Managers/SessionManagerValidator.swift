import Foundation

/// SessionManagerのバリデーション処理を担当
///
/// 責務:
/// - セッション名のバリデーション
/// - Description配列のバリデーション
/// - 重複チェック
/// - 制限値チェック
struct SessionManagerValidator {

    /// セッションエントリのバリデーション
    static func validateSessionEntry(
        sessionName: String,
        descriptions: [String],
        isNewSession: Bool,
        currentCustomCount: Int,
        isDefaultSession: Bool,
        existingEntry: SessionEntry?,
        oldKey: String,
        newKey: String
    ) throws {
        // セッション名の長さチェック
        try validateSessionNameLength(sessionName)

        // セッション数制限チェック
        try validateSessionCount(
            isNewSession: isNewSession,
            currentCustomCount: currentCustomCount,
            isDefaultSession: isDefaultSession
        )

        // 重複チェック
        try validateDuplicateSession(
            sessionName: sessionName,
            existingEntry: existingEntry,
            isDefaultSession: isDefaultSession,
            oldKey: oldKey,
            newKey: newKey
        )

        // Description配列のバリデーション
        try validateDescriptions(descriptions)
    }

    /// Description配列のバリデーション
    static func validateDescriptions(_ descriptions: [String]) throws {
        // Description数制限チェック
        if descriptions.count > SessionManager.maxDescriptionCount {
            throw SessionManagerError.descriptionLimitExceeded
        }

        // 各Descriptionの文字数チェック
        for description in descriptions where description.count > SessionManager.maxDescriptionLength {
            throw SessionManagerError.descriptionTooLong
        }
    }

    /// セッション名の長さバリデーション
    static func validateSessionNameLength(_ sessionName: String) throws {
        if sessionName.count > SessionManager.maxNameLength {
            throw SessionManagerError.nameTooLong
        }
    }

    /// セッション数制限のバリデーション
    static func validateSessionCount(
        isNewSession: Bool,
        currentCustomCount: Int,
        isDefaultSession: Bool
    ) throws {
        if !isDefaultSession &&
            currentCustomCount >= SessionManager.maxSessionCount &&
            isNewSession {
            throw SessionManagerError.sessionLimitExceeded
        }
    }

    /// セッション重複のバリデーション
    static func validateDuplicateSession(
        sessionName: String,
        existingEntry: SessionEntry?,
        isDefaultSession: Bool,
        oldKey: String,
        newKey: String
    ) throws {
        // 重複禁止（空文字でない場合のみチェック）
        if !sessionName.isEmpty,
           let existing = existingEntry,
           !isDefaultSession {
            // 元のキーと違う場合のみ重複エラー
            if newKey != oldKey && !existing.isDefault {
                throw SessionManagerError.duplicateName
            }
        }
    }

    /// 既存セッションの存在チェック
    static func validateSessionExists(_ sessionEntry: SessionEntry?) throws {
        guard sessionEntry != nil else {
            throw SessionManagerError.notFound
        }
    }

    /// インデックスの有効性チェック
    static func validateIndex(_ index: Int, for descriptions: [String]) throws {
        guard index >= 0 && index < descriptions.count else {
            throw SessionManagerError.notFound
        }
    }
}
