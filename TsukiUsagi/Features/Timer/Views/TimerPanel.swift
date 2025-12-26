//
//  TimerPanel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

import SwiftUI

struct TimerPanel: View {
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @AppStorage("sessionLabel") private var sessionLabel: String = "Work"
    @Environment(\.scenePhase) private var scenePhase

    @State private var isEditing = false
    @State private var editedActivity: String = ""
    @State private var editedSubtitle: String = ""
    @State private var editedMemo: String = ""
    @State private var lastEditID = UUID()

    private let buttonWidth: CGFloat = 120
    private let recordBottomPadding: CGFloat = 200 // ← 下から何pt に出す？

    var body: some View {
        // "タイマー中央" と "記録ブロック下端" を別レイヤーで配置
        ZStack {
            // タイマー：常に中央寄り
            TimerTextView(
                timeText: timerVM.formatTime(timerVM.timeRemaining),
                isSessionFinished: timerVM.isSessionFinished
            )

            // ★START押下アニメ（追加）
            .startPulseAnimation(publisher: timerVM.startPulse.eraseToAnyPublisher())

            .frame(maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center)

            // 記録ブロック：常に下端
            // --- RecordedTimesViewの呼び出しを削除 ---
        }
        // 編集シート
        .sheet(isPresented: $isEditing, onDismiss: {
            // 再描画用にIDを更新
            lastEditID = UUID()
        }, content: {
            // 外側（器）と内側（中身）の両方で黒を明示
            ZStack {
                DesignTokens.CosmosColors.background.ignoresSafeArea()
                editSheetView()
                    .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
            }
        })
        .presentationBackground(DesignTokens.CosmosColors.background)

        // ★ Moon メッセージと同じ duration で同期
        .animation(
            timerVM.shouldSuppressSessionFinishedAnimation ? nil : .easeInOut(
                duration: AppConstants.sessionEndAnimationDuration
            ),
            value: timerVM.isSessionFinished
        )
        // アニメーション抑制フラグをリセット
        .onChange(of: timerVM.isSessionFinished) { _, _ in
            if timerVM.shouldSuppressSessionFinishedAnimation {
                timerVM.clearSessionFinishedAnimationSuppression()
            }
        }

        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // Save running state and absolute endAt before pausing engine
                timerVM.saveTimerState()
                // appDidEnterBackground()はContentViewで処理されるため、ここでは不要
            case .active:
                Task { timerVM.appWillEnterForeground() }
            default:
                break
            }
        }

        .onAppear {
            // 再起動/再表示時の復元と再始動はライフサイクル経由で統一
            Task { @MainActor in
                timerVM.appWillEnterForeground()
            }
        }
    }

    // 編集シートを新しいビューに置き換え
    @ViewBuilder
    private func editSheetView() -> some View {
        EditRecordView()
    }

    private var formattedStartTime: String {
        return TimeFormatters.formatTime(date: timerVM.startTime)
    }

    private var formattedEndTime: String {
        return TimeFormatters.formatTime(date: timerVM.endTime)
    }

    private var actualSessionMinutes: Int {
        timerVM.actualSessionMinutes
    }
}
