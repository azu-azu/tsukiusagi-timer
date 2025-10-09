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

    /// 非同期に保存し、結果をコールバックで返す
    func save(_ data: [SessionRecord], completion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            let encoded = try encoder.encode(data)
            let fileURL = url // capture value for thread safety

            DispatchQueue.global(qos: .utility).async {
                do {
                    try encoded.write(
                        to: fileURL,
                        options: [.atomic, .completeFileProtectionUnlessOpen]
                    )
                    completion?(.success(()))
                } catch {
                    #if DEBUG
                    print("[history_save_failed] HistoryStore save failed:", error)
                    #endif
                    completion?(.failure(error))
                }
            }
        } catch {
            #if DEBUG
            print("[history_save_failed] HistoryStore encoding failed:", error)
            #endif
            completion?(.failure(error))
        }
    }

    // MARK: - Load

    func load() -> [SessionRecord] {
        guard let raw = try? Data(contentsOf: url) else { return [] }
        return (try? decoder.decode([SessionRecord].self, from: raw)) ?? []
    }
}
