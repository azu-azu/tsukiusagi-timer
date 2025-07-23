import Foundation

// マイグレーション用の古いモデル定義
struct OldSessionItem: Codable, Identifiable {
    var id: UUID
    var name: String
    var detail: String?
}

struct SessionItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String?
    var isFixed: Bool // ← 固定／カスタムを区別
    // 説明（description）複数対応（将来拡張用）
    // var descriptions: [String] = []
}

extension SessionItem {
    // 固定3種のSessionItemを返す
    static var fixedSessions: [SessionItem] {
        [
            SessionItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "Work",
                description: nil,
                isFixed: true
            ),
            SessionItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Study",
                description: nil,
                isFixed: true
            ),
            SessionItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Read",
                description: nil,
                isFixed: true
            )
        ]
    }
}
