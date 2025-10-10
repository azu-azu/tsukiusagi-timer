import Foundation

extension SessionManager {

    // MARK: - Private Helpers

    private func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizedDescription(_ text: String) -> String {
        text.tsu_descriptionNormalizedValue
    }

    /// セッションを取得し存在を保証した上で返す
    private func getValidatedEntry(_ sessionName: String) throws -> SessionEntry {
        let key = normalizedName(sessionName)
        let entry = sessionDatabase[key]
        return try SessionManagerValidator.validateAndUnwrap(entry)
    }

    // MARK: - Public Methods

    func updateSessionDescriptions(sessionName: String, newDescriptions: [String]) throws {
        let entry = try getValidatedEntry(sessionName)
        let canonicalDescriptions = newDescriptions.map { normalizedDescription($0) }
        try SessionManagerValidator.validateDescriptions(canonicalDescriptions)

        sessionDatabase[normalizedName(sessionName)] = SessionEntry(
            id: entry.id,
            sessionName: entry.sessionName,
            descriptions: canonicalDescriptions,
            isDefault: entry.isDefault
        )
        save()
    }

    func addDescriptionToSession(sessionName: String, newDescription: String) throws {
        let entry = try getValidatedEntry(sessionName)
        let trimmedDesc = normalizedDescription(newDescription)

        try SessionManagerValidator.validateAddDescription(entry, newText: trimmedDesc)

        var newDescriptions = entry.descriptions
        newDescriptions.append(trimmedDesc)
        try updateSessionDescriptions(sessionName: sessionName, newDescriptions: newDescriptions)
    }

    func updateDescription(sessionName: String, at index: Int, newDescription: String) throws {
        let entry = try getValidatedEntry(sessionName)
        let trimmedDesc = normalizedDescription(newDescription)

        try SessionManagerValidator.validateUpdateDescription(entry, index: index, newText: trimmedDesc)

        var newDescriptions = entry.descriptions
        newDescriptions[index] = trimmedDesc
        try updateSessionDescriptions(sessionName: sessionName, newDescriptions: newDescriptions)
    }

    func removeDescription(sessionName: String, at index: Int) throws {
        let entry = try getValidatedEntry(sessionName)
        try SessionManagerValidator.validateIndex(index, for: entry.descriptions)

        var newDescriptions = entry.descriptions
        newDescriptions.remove(at: index)
        try updateSessionDescriptions(sessionName: sessionName, newDescriptions: newDescriptions)
    }
}
