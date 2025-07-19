import Foundation

struct SessionEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var sessionName: String
    var subtitles: [String]
    var isDefault: Bool

    init(id: UUID = UUID(), sessionName: String, subtitles: [String] = [], isDefault: Bool = false) {
        self.id = id
        self.sessionName = sessionName
        self.subtitles = subtitles
        self.isDefault = isDefault
    }
}
