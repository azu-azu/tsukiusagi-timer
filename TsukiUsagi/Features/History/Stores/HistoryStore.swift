import Foundation

struct HistoryStore {
    private let file = "history.json"

    private var url: URL {
        FileManager.default.urls(for: .documentDirectory,
                                 in: .userDomainMask)[0]
            .appendingPathComponent(file)
    }

    // MARK: - JSON coder/decoder with ISO-8601 dates

    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    // MARK: - Save

    func save(_ data: [SessionRecord]) {
        do {
            let encoded = try encoder.encode(data)
            let fileURL = url // capture value for thread safety

            DispatchQueue.global(qos: .utility).async {
                do {
                    try encoded.write(
                        to: fileURL,
                        options: [.atomic, .completeFileProtectionUnlessOpen]
                    )
                } catch {
                    print("HistoryStore save failed:", error)
                }
            }
        } catch {
            print("HistoryStore encoding failed:", error)
        }
    }

    // MARK: - Load

    func load() -> [SessionRecord] {
        guard let raw = try? Data(contentsOf: url) else { return [] }
        return (try? decoder.decode([SessionRecord].self, from: raw)) ?? []
    }
}
