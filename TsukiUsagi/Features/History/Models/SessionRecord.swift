import Foundation

struct SessionRecord: Codable, Identifiable {
    var id: String // UUID から String に変更（固定値）
    var start, end: Date
    var phase: PomodoroPhase
    var sessionName: String // 上位
    var task: String? // 下位
    var memo: String? // ←★ legacy memo
    // 静かな完了（通知を出さず復帰時に確定）
    var completedSilently: Bool?

    // 履歴行のduration（秒）
    var duration: TimeInterval { end.timeIntervalSince(start) }

    private enum CodingKeys: String, CodingKey {
        case id, start, end, phase, memo, completedSilently
        case sessionName = "activity"
        case task
        case legacySubtitle = "subtitle"
    }

    init(
        id: String,
        start: Date,
        end: Date,
        phase: PomodoroPhase,
        sessionName: String,
        task: String?,
        memo: String?,
        completedSilently: Bool? = nil
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.phase = phase
        self.sessionName = sessionName
        self.task = task
        self.memo = memo
        self.completedSilently = completedSilently
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        phase = try container.decode(PomodoroPhase.self, forKey: .phase)
        sessionName = try container.decode(String.self, forKey: .sessionName)
        if let decodedTask = try container.decodeIfPresent(String.self, forKey: .task) {
            task = decodedTask
        } else {
            task = try container.decodeIfPresent(String.self, forKey: .legacySubtitle)
        }
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        completedSilently = try container.decodeIfPresent(Bool.self, forKey: .completedSilently)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
        try container.encode(phase, forKey: .phase)
        try container.encode(sessionName, forKey: .sessionName)
        try container.encode(task, forKey: .task)
        try container.encodeIfPresent(memo, forKey: .memo)
        try container.encodeIfPresent(completedSilently, forKey: .completedSilently)
    }

    // MARK: - Legacy accessors (temporary)

    @available(*, deprecated, message: "Use sessionName instead of activity")
    var activity: String {
        get { sessionName }
        set { sessionName = newValue }
    }

    @available(*, deprecated, message: "Use task instead of subtitle")
    var subtitle: String? {
        get { task }
        set { task = newValue }
    }

    @available(*, deprecated, message: "Use task instead.")
    var description: String? {
        get { task }
        set { task = newValue }
    }

    @available(*, deprecated, message: "Use task-based initializer instead.")
    init(
        id: String,
        start: Date,
        end: Date,
        phase: PomodoroPhase,
        sessionName: String,
        description: String?,
        memo: String?,
        completedSilently: Bool? = nil
    ) {
        self.init(
            id: id,
            start: start,
            end: end,
            phase: phase,
            sessionName: sessionName,
            task: description,
            memo: memo,
            completedSilently: completedSilently
        )
    }
}

// MARK: - Add Session Parameters

struct AddSessionParameters {
    let start: Date
    let end: Date
    let phase: PomodoroPhase
    let sessionName: String
    let task: String?
    let memo: String?
    let completedSilently: Bool
}
