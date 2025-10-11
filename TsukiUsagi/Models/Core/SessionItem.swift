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
    var task: String?
    var isFixed: Bool // ← 固定／カスタムを区別
    // 説明（description）複数対応（将来拡張用）
    // var descriptions: [String] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case task
        case isFixed
        case legacyDescription = "description"
    }

    init(
        id: UUID = UUID(),
        name: String,
        task: String? = nil,
        isFixed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.task = task
        self.isFixed = isFixed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        if let decodedTask = try container.decodeIfPresent(String.self, forKey: .task) {
            task = decodedTask
        } else {
            task = try container.decodeIfPresent(String.self, forKey: .legacyDescription)
        }
        isFixed = try container.decodeIfPresent(Bool.self, forKey: .isFixed) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(task, forKey: .task)
        try container.encode(isFixed, forKey: .isFixed)
    }
}

extension SessionItem {
    @available(*, deprecated, message: "Use task instead.")
    var description: String? {
        get { task }
        set { task = newValue }
    }
}

extension SessionItem {
    // 固定3種のSessionItemを返す
    static var fixedSessions: [SessionItem] {
        [
            SessionItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "Work",
                task: nil,
                isFixed: true
            ),
            SessionItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Study",
                task: nil,
                isFixed: true
            ),
            SessionItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Read",
                task: nil,
                isFixed: true
            )
        ]
    }
}
