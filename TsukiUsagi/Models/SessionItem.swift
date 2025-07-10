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
    var subtitle: String?
    var isFixed: Bool            // ← 固定／カスタムを区別
    // サブタイトル複数対応（将来拡張用）
    // var subtitles: [String] = []
}

extension SessionItem {
    // 固定3種のSessionItemを返す
    static var fixedSessions: [SessionItem] {
        [
            SessionItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Work", subtitle: nil, isFixed: true),
            SessionItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Study", subtitle: nil, isFixed: true),
            SessionItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Read", subtitle: nil, isFixed: true),
        ]
    }
}