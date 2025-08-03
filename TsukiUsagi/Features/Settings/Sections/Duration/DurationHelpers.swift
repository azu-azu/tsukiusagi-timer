import SwiftUI

// MARK: - Duration Action Helpers

enum DurationActions {
    /// Work Durationの減少アクション
    static func makeDecrementWorkAction(
        workMinutes: Binding<Int>,
        options: [Int],
        timerVM: TimerViewModel
    ) -> @MainActor () -> Void {
        return { @MainActor in
            let currentIndex = options.firstIndex(of: workMinutes.wrappedValue) ?? 0
            if currentIndex > 0 {
                workMinutes.wrappedValue = options[currentIndex - 1]
                timerVM.refreshAfterSettingsChange()
            }
        }
    }

    /// Work Durationの増加アクション
    static func makeIncrementWorkAction(
        workMinutes: Binding<Int>,
        options: [Int],
        timerVM: TimerViewModel
    ) -> @MainActor () -> Void {
        return { @MainActor in
            let currentIndex = options.firstIndex(of: workMinutes.wrappedValue) ?? 0
            if currentIndex < options.count - 1 {
                workMinutes.wrappedValue = options[currentIndex + 1]
                timerVM.refreshAfterSettingsChange()
            }
        }
    }

    /// Break Durationの減少アクション
    static func makeDecrementBreakAction(
        breakMinutes: Binding<Int>,
        timerVM: TimerViewModel
    ) -> @MainActor () -> Void {
        return { @MainActor in
            if breakMinutes.wrappedValue > 1 {
                breakMinutes.wrappedValue -= 1
                timerVM.refreshAfterSettingsChange()
            }
        }
    }

    /// Break Durationの増加アクション
    static func makeIncrementBreakAction(
        breakMinutes: Binding<Int>,
        timerVM: TimerViewModel
    ) -> @MainActor () -> Void {
        return { @MainActor in
            if breakMinutes.wrappedValue < 30 {
                breakMinutes.wrappedValue += 1
                timerVM.refreshAfterSettingsChange()
            }
        }
    }
}

// MARK: - Duration Constants

struct DurationConstants {
    /// Work Minutesの選択肢: 1, 3, 5, 10, 15, ... 60
    static let workMinutesOptions: [Int] = [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))
}
