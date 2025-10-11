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

    /// 現在のTaskリスト
    let tasks: [String]

    /// デフォルトセッションかどうか
    let isDefaultSession: Bool

    /// 編集モードの種類
    let editMode: EditMode

    /// 編集モードの定義
    enum EditMode: Equatable {
        case descriptionOnly(index: Int?)  // Default Session: 特定のDescription編集 or 全Description管理
        case fullSession                // Custom Session: Session名 + 全Description編集
    }

    /// Task編集用の初期化
    /// - Parameters:
    ///   - entryId: 編集対象のSessionEntryのID
    ///   - sessionName: セッション名（Default Sessionの場合は固定値）
    ///   - tasks: 現在のTaskリスト
    ///   - descriptionIndex: 編集対象のTaskのインデックス（既存編集の場合）
    static func descriptionEdit(
        entryId: UUID,
        sessionName: String,
        tasks: [String],
        isDefault: Bool,
        descriptionIndex: Int? = nil
    ) -> SessionEditContext {
        SessionEditContext(
            entryId: entryId,
            sessionName: sessionName,
            tasks: tasks,
            isDefaultSession: isDefault,
            editMode: .descriptionOnly(index: descriptionIndex)
        )
    }

    /// Full Session編集用の初期化
    /// - Parameters:
    ///   - entryId: 編集対象のSessionEntryのID
    ///   - sessionName: 現在のセッション名
    ///   - tasks: 現在のTaskリスト
    static func fullSessionEdit(
        entryId: UUID,
        sessionName: String,
        tasks: [String],
        isDefault: Bool
    ) -> SessionEditContext {
        SessionEditContext(
            entryId: entryId,
            sessionName: sessionName,
            tasks: tasks,
            isDefaultSession: isDefault,
            editMode: .fullSession
        )
    }

    /// 編集対象のDescriptionのインデックス（Description編集時のみ）
    var descriptionIndex: Int? {
        if case .descriptionOnly(let index) = editMode {
            return index
        }
        return nil
    }

    /// 編集対象のTaskテキスト（特定のTask編集時のみ）
    var currentDescriptionText: String? {
        if case .descriptionOnly(let optionalIndex) = editMode,
            let index = optionalIndex,
            index < tasks.count {
            return tasks[index]
        }
        return nil
    }

    /// 編集コンテキストの説明文字列（デバッグ用）
    var debugDescription: String {
        switch editMode {
        case .descriptionOnly(let index):
            if let index = index {
                let descriptionText = tasks.indices.contains(index) ? tasks[index] : ""
                return "SessionEditContext(session: \(sessionName), " +
                    "description[\(index)]: \"\(descriptionText)\")"
            } else {
                return "SessionEditContext(session: \(sessionName), " +
                    "descriptionManagement, tasks: \(tasks.count))"
            }
        case .fullSession:
            return "SessionEditContext(session: \(sessionName), " +
                "fullEdit, tasks: \(tasks.count))"
        }
    }
}

// MARK: - Extensions

extension SessionEditContext {
    /// テスト用のサンプルデータ
    static let sampleDescriptionEdit = SessionEditContext.descriptionEdit(
        entryId: UUID(),
        sessionName: "Work",
        tasks: ["SwiftUI development", "Code review"],
        isDefault: true,
        descriptionIndex: 0
    )

    static let sampleFullSessionEdit = SessionEditContext.fullSessionEdit(
        entryId: UUID(),
        sessionName: "My Custom Project",
        tasks: ["Task 1", "Task 2", "Task 3"],
        isDefault: false
    )
}
