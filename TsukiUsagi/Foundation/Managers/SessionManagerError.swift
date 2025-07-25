import Foundation

/// SessionManager関連のエラー定義
///
/// 責務:
/// - エラータイプの定義
/// - ユーザー向けエラーメッセージの提供
/// - エラーハンドリングの統一
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
