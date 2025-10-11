//
//  TimerDisplayManager.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import Foundation
import Combine

/// タイマー表示管理を担当するManager
@MainActor
final class TimerDisplayManager: ObservableObject {

    // MARK: - Published Properties

    @Published var activityLabel: String = ""
    @Published var taskLabel: String = ""
    @Published var workMinutes: Int = 25
    @Published var breakMinutes: Int = 5

    // MARK: - Dependencies

    private let formatter: TimeFormatterUtilable

    // MARK: - Initialization

    init(formatter: TimeFormatterUtilable) {
        self.formatter = formatter
    }

    // MARK: - Display Methods

    /// 時間表示文字列を取得
    func timeDisplayString(for seconds: Int) -> String {
        return formatter.format(seconds: seconds)
    }

    /// アクティビティラベルを設定
    func setActivityLabel(_ label: String) {
        activityLabel = label
    }

    /// タスクラベルを設定
    func setTaskLabel(_ label: String) {
        taskLabel = label
    }

    /// 作業時間を設定
    func setWorkMinutes(_ minutes: Int) {
        workMinutes = max(1, minutes)
    }

    /// 休憩時間を設定
    func setBreakMinutes(_ minutes: Int) {
        breakMinutes = max(1, minutes)
    }

    /// デフォルト値にリセット
    func resetToDefaults() {
        activityLabel = ""
        taskLabel = ""
        workMinutes = 25
        breakMinutes = 5
    }

    @available(*, deprecated, message: "Use taskLabel instead.")
    var subtitleLabel: String {
        get { taskLabel }
        set { taskLabel = newValue }
    }

    @available(*, deprecated, message: "Use setTaskLabel(_:) instead.")
    func setSubtitleLabel(_ label: String) {
        setTaskLabel(label)
    }
}
