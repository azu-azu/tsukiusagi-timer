import Foundation

protocol SessionHistoryServiceable: AnyObject {
    @MainActor func add(parameters: AddSessionParameters)
}

final class SessionHistoryService: SessionHistoryServiceable {
    private let formatter: TimeFormatterUtilable
    private weak var historyVM: HistoryViewModel?

    init(formatter: TimeFormatterUtilable, historyVM: HistoryViewModel) {
        self.formatter = formatter
        self.historyVM = historyVM
    }

    @MainActor
    func add(parameters: AddSessionParameters) {
        // HistoryViewModel に委譲して単一ソース・オブ・トゥルースを保つ
        historyVM?.add(parameters: parameters)
    }
}
