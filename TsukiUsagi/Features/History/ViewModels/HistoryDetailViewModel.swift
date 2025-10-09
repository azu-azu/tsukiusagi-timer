import Combine
import Foundation

@MainActor
final class HistoryDetailViewModel: ObservableObject {
    @Published private(set) var summary: DaySummary
    @Published var reflectionText: String = ""
    @Published private(set) var isSaving = false
    @Published private(set) var error: Error?

    private let targetDate: Date
    private let dataProvider = DailyTimelineDataProvider()
    private var historyVM: HistoryViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var isConfigured = false

    init(targetDate: Date) {
        self.targetDate = targetDate
        self.summary = DaySummary(total: 0, sessionName: nil, descriptions: [])
    }

    func attach(historyViewModel: HistoryViewModel) {
        guard !isConfigured else { return }
        isConfigured = true

        historyVM = historyViewModel
        summary = dataProvider.makeDaySummary(historyVM: historyViewModel, targetDate: targetDate)
        reflectionText = historyViewModel.reflectionText(for: targetDate)
        isSaving = historyViewModel.reflection(for: targetDate)?.isPendingSave ?? false
        error = historyViewModel.reflectionSaveError

        historyViewModel.$history
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, let historyVM = self.historyVM else { return }
                self.summary = self.dataProvider.makeDaySummary(historyVM: historyVM, targetDate: self.targetDate)
            }
            .store(in: &cancellables)

        historyViewModel.$reflectionsByDay
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncReflectionState()
            }
            .store(in: &cancellables)

        historyViewModel.$reflectionSaveError
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)

        $reflectionText
            .removeDuplicates()
            .debounce(for: .milliseconds(800), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.commitReflection(text: newValue)
            }
            .store(in: &cancellables)
    }

    func flush() {
        commitReflection(text: reflectionText)
    }

    func retry() {
        historyVM?.retrySaveReflection()
    }

    private func commitReflection(text: String) {
        historyVM?.updateReflection(for: targetDate, text: text)
    }

    private func syncReflectionState() {
        guard let historyVM else { return }
        let latest = historyVM.reflection(for: targetDate)
        if let latest, !latest.isPendingSave, latest.text != reflectionText {
            reflectionText = latest.text
        }
        isSaving = latest?.isPendingSave ?? false
    }
}
