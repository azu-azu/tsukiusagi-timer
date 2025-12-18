import Foundation

extension SessionManager {

    // MARK: - Private Helpers

    private func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizedTask(_ text: String) -> String {
        text.tsu_taskNormalizedValue
    }

    /// セッションを取得し存在を保証した上で返す
    private func getValidatedEntry(_ sessionName: String) throws -> SessionEntry {
        let key = normalizedName(sessionName)
        let entry = sessionDatabase[key]
        return try SessionManagerValidator.validateAndUnwrap(entry)
    }

    // MARK: - Public Methods

    func updateSessionTasks(sessionName: String, newTasks: [String]) throws {
        let entry = try getValidatedEntry(sessionName)
        let canonicalTasks = newTasks.map { normalizedTask($0) }
        try SessionManagerValidator.validateTasks(canonicalTasks)

        sessionDatabase[normalizedName(sessionName)] = SessionEntry(
            id: entry.id,
            sessionName: entry.sessionName,
            tasks: canonicalTasks,
            isDefault: entry.isDefault
        )
        save()
    }

    func addTaskToSession(sessionName: String, newTask: String) throws {
        let entry = try getValidatedEntry(sessionName)
        let trimmedTask = normalizedTask(newTask)

        try SessionManagerValidator.validateAddTask(entry, newText: trimmedTask)

        var updatedTasks = entry.tasks
        updatedTasks.append(trimmedTask)
        try updateSessionTasks(sessionName: sessionName, newTasks: updatedTasks)
    }

    func updateTask(sessionName: String, at index: Int, newTask: String) throws {
        let entry = try getValidatedEntry(sessionName)
        let trimmedTask = normalizedTask(newTask)

        try SessionManagerValidator.validateUpdateTask(entry, index: index, newText: trimmedTask)

        var updatedTasks = entry.tasks
        updatedTasks[index] = trimmedTask
        try updateSessionTasks(sessionName: sessionName, newTasks: updatedTasks)
    }

    func removeTask(sessionName: String, at index: Int) throws {
        let entry = try getValidatedEntry(sessionName)
        try SessionManagerValidator.validateIndex(index, for: entry.tasks)

        var updatedTasks = entry.tasks
        updatedTasks.remove(at: index)
        try updateSessionTasks(sessionName: sessionName, newTasks: updatedTasks)
    }
}
