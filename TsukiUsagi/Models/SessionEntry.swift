import Foundation

struct SessionEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var sessionName: String?
    var subtitles: [String]

    init(sessionName: String? = nil, subtitles: [String] = []) {
        self.sessionName = sessionName
        self.subtitles = subtitles
    }
}