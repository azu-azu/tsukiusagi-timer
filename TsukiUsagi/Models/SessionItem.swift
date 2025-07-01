import Foundation

struct SessionItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var detail: String?

    static func == (lhs: SessionItem, rhs: SessionItem) -> Bool {
        lhs.name == rhs.name
    }
}

extension SessionItem {
    // 固定3種のSessionItemを返す
    static var fixedSessions: [SessionItem] {
        [
            SessionItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Work", detail: nil),
            SessionItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Study", detail: nil),
            SessionItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Read", detail: nil)
        ]
    }
}