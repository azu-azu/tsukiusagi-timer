import Foundation

struct SessionEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var sessionName: String
    var descriptions: [String]
    var isDefault: Bool

    init(id: UUID = UUID(), sessionName: String, descriptions: [String] = [], isDefault: Bool = false) {
        self.id = id
        self.sessionName = sessionName
        self.descriptions = descriptions
        self.isDefault = isDefault
    }
}
