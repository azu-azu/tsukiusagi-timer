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

    /// 現在のSubtitleリスト
    let subtitles: [String]

    /// 編集モードの種類
    let editMode: EditMode

    /// 編集モードの定義
    enum EditMode: Equatable {
        case subtitleOnly(index: Int?)  // Default Session: 特定のSubtitle編集 or 全Subtitle管理
        case fullSession                // Custom Session: Session名 + 全Subtitle編集
    }

    /// Subtitle編集用の初期化
    /// - Parameters:
    ///   - entryId: 編集対象のSessionEntryのID
    ///   - sessionName: セッション名（Default Sessionの場合は固定値）
    ///   - subtitles: 現在のSubtitleリスト
    ///   - subtitleIndex: 編集対象のSubtitleのインデックス（既存編集の場合）
    static func subtitleEdit(
        entryId: UUID,
        sessionName: String,
        subtitles: [String],
        subtitleIndex: Int? = nil
    ) -> SessionEditContext {
        SessionEditContext(
            entryId: entryId,
            sessionName: sessionName,
            subtitles: subtitles,
            editMode: .subtitleOnly(index: subtitleIndex)
        )
    }

    /// Full Session編集用の初期化
    /// - Parameters:
    ///   - entryId: 編集対象のSessionEntryのID
    ///   - sessionName: 現在のセッション名
    ///   - subtitles: 現在のSubtitleリスト
    static func fullSessionEdit(
        entryId: UUID,
        sessionName: String,
        subtitles: [String]
    ) -> SessionEditContext {
        SessionEditContext(
            entryId: entryId,
            sessionName: sessionName,
            subtitles: subtitles,
            editMode: .fullSession
        )
    }

    /// Default Sessionかどうかを判定
    /// - Returns: Default Sessionの場合はtrue
    var isDefaultSession: Bool {
        ["Work", "Study", "Life", "Personal", "Health"].contains(sessionName)
    }

    /// 編集対象のSubtitleのインデックス（Subtitle編集時のみ）
    var subtitleIndex: Int? {
        if case .subtitleOnly(let index) = editMode {
            return index
        }
        return nil
    }

    /// 編集対象のSubtitleテキスト（特定のSubtitle編集時のみ）
    var currentSubtitleText: String? {
        if case .subtitleOnly(let optionalIndex) = editMode,
            let index = optionalIndex,
            index < subtitles.count {
            return subtitles[index]
        }
        return nil
    }

    /// 編集コンテキストの説明文字列（デバッグ用）
    var debugDescription: String {
        switch editMode {
        case .subtitleOnly(let index):
            if let index = index {
                let subtitleText = subtitles.indices.contains(index) ? subtitles[index] : ""
                return "SessionEditContext(session: \(sessionName), subtitle[\(index)]: \"\(subtitleText)\")"
            } else {
                return "SessionEditContext(session: \(sessionName), subtitleManagement, subtitles: \(subtitles.count))"
            }
        case .fullSession:
            return "SessionEditContext(session: \(sessionName), fullEdit, subtitles: \(subtitles.count))"
        }
    }
}

// MARK: - Extensions

extension SessionEditContext {
    /// テスト用のサンプルデータ
    static let sampleSubtitleEdit = SessionEditContext.subtitleEdit(
        entryId: UUID(),
        sessionName: "Work",
        subtitles: ["SwiftUI development", "Code review"],
        subtitleIndex: 0
    )

    static let sampleFullSessionEdit = SessionEditContext.fullSessionEdit(
        entryId: UUID(),
        sessionName: "My Custom Project",
        subtitles: ["Task 1", "Task 2", "Task 3"]
    )
}
