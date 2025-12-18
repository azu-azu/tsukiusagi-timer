import Foundation

struct SessionEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var sessionName: String
    var tasks: [String]
    var isDefault: Bool

    init(id: UUID = UUID(), sessionName: String, tasks: [String] = [], isDefault: Bool = false) {
        self.id = id
        self.sessionName = sessionName
        self.tasks = tasks
        self.isDefault = isDefault
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case sessionName
        case tasks
        case isDefault
        case legacyDescriptions = "descriptions"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sessionName = try container.decode(String.self, forKey: .sessionName)
        if let decodedTasks = try container.decodeIfPresent([String].self, forKey: .tasks) {
            tasks = decodedTasks
        } else {
            tasks = try container.decodeIfPresent([String].self, forKey: .legacyDescriptions) ?? []
        }
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sessionName, forKey: .sessionName)
        try container.encode(tasks, forKey: .tasks)
        try container.encode(isDefault, forKey: .isDefault)
    }
}
