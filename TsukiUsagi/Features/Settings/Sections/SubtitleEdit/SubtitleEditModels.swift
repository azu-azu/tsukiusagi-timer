// SubtitleEditModels.swift
//
// Session編集機能のデータモデル定義
// 責務: 状態管理と型安全性の提供

import Foundation

/// Session編集時のコンテキスト情報を型安全に管理
///
/// - Note: Identifiableを実装することで.sheet(item:)との親和性を確保
/// - Note: Equatableを実装することで状態変化の検知を効率化
struct SessionEditContext: Identifiable, Equatable {
    /// 一意識別子（.sheet(item:)で必要）
    let id = UUID()

    /// 編集対象のSessionEntryのID
    let entryId: UUID

    /// 現在のセッション名
    let sessionName: String

    /// 現在のDescriptionリスト
    let descriptions: [String]

    /// 編集モードの種類
    let editMode: EditMode

    /// 編集モードの定義
    enum EditMode: Equatable {
        case descriptionOnly(index: Int?)  // Default Session: 特定のDescription編集 or 全Description管理
        case fullSession                // Custom Session: Session名 + 全Description編集
    }

    /// Description編集用の初期化
    /// - Parameters:
    ///   - entryId: 編集対象のSessionEntryのID
    ///   - sessionName: セッション名（Default Sessionの場合は固定値）
    ///   - descriptions: 現在のDescriptionリスト
    ///   - descriptionIndex: 編集対象のDescriptionのインデックス（既存編集の場合）
    static func descriptionEdit(
        entryId: UUID,
        sessionName: String,
        descriptions: [String],
        descriptionIndex: Int? = nil
    ) -> SessionEditContext {
        SessionEditContext(
            entryId: entryId,
            sessionName: sessionName,
            descriptions: descriptions,
            editMode: .descriptionOnly(index: descriptionIndex)
        )
    }

    /// Full Session編集用の初期化
    /// - Parameters:
    ///   - entryId: 編集対象のSessionEntryのID
    ///   - sessionName: 現在のセッション名
    ///   - descriptions: 現在のDescriptionリスト
    static func fullSessionEdit(
        entryId: UUID,
        sessionName: String,
        descriptions: [String]
    ) -> SessionEditContext {
        SessionEditContext(
            entryId: entryId,
            sessionName: sessionName,
            descriptions: descriptions,
            editMode: .fullSession
        )
    }

    /// Default Sessionかどうかを判定
    /// - Returns: Default Sessionの場合はtrue
    var isDefaultSession: Bool {
        ["Work", "Study", "Life", "Personal", "Health"].contains(sessionName)
    }

    /// 編集対象のDescriptionのインデックス（Description編集時のみ）
    var descriptionIndex: Int? {
        if case .descriptionOnly(let index) = editMode {
            return index
        }
        return nil
    }

    /// 編集対象のDescriptionテキスト（特定のDescription編集時のみ）
    var currentDescriptionText: String? {
        if case .descriptionOnly(let optionalIndex) = editMode,
            let index = optionalIndex,
            index < descriptions.count {
            return descriptions[index]
        }
        return nil
    }

    /// 編集コンテキストの説明文字列（デバッグ用）
    var debugDescription: String {
        switch editMode {
        case .descriptionOnly(let index):
            if let index = index {
                let descriptionText = descriptions.indices.contains(index) ? descriptions[index] : ""
                return "SessionEditContext(session: \(sessionName), " +
                    "description[\(index)]: \"\(descriptionText)\")"
            } else {
                return "SessionEditContext(session: \(sessionName), " +
                    "descriptionManagement, descriptions: \(descriptions.count))"
            }
        case .fullSession:
            return "SessionEditContext(session: \(sessionName), " +
                "fullEdit, descriptions: \(descriptions.count))"
        }
    }
}

// MARK: - Extensions

extension SessionEditContext {
    /// テスト用のサンプルデータ
    static let sampleDescriptionEdit = SessionEditContext.descriptionEdit(
        entryId: UUID(),
        sessionName: "Work",
        descriptions: ["SwiftUI development", "Code review"],
        descriptionIndex: 0
    )

    static let sampleFullSessionEdit = SessionEditContext.fullSessionEdit(
        entryId: UUID(),
        sessionName: "My Custom Project",
        descriptions: ["Task 1", "Task 2", "Task 3"]
    )
}
