//
//  TimerPanel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

import SwiftUI

struct TimerPanel: View {
    @ObservedObject var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @AppStorage("sessionLabel") private var sessionLabel: String = "Work"
    @Environment(\.scenePhase) private var scenePhase

    @State private var flashYellow = false
    @State private var flashScale  = false
    @State private var isEditing = false
    @State private var editedActivity: String = ""
    @State private var editedDetail: String = ""
    @State private var editedMemo: String = ""
    @State private var lastEditID = UUID()

    private let buttonWidth: CGFloat = 120
    private let recordBottomPadding: CGFloat = 200   // ← 下から何pt に出す？

    var body: some View {
        // "タイマー中央" と "記録ブロック下端" を別レイヤーで配置
        ZStack {
            // タイマー：常に中央寄り
            TimerTextView(
                timeText: timerVM.formatTime(),
                isSessionFinished: timerVM.isSessionFinished,
                flashYellow: flashYellow,
                flashScale: flashScale
            )
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
        }) { editSheetView() }

        // ★ Moon メッセージと同じ duration で同期
        .animation(
            timerVM.shouldSuppressSessionFinishedAnimation ? nil : .easeInOut(duration: LayoutConstants.sessionEndAnimationDuration),
            value: timerVM.isSessionFinished
        )
        // アニメーション抑制フラグをリセット
        .onChange(of: timerVM.isSessionFinished) { oldValue, newValue in
            if timerVM.shouldSuppressSessionFinishedAnimation {
                timerVM.shouldSuppressSessionFinishedAnimation = false
            }
        }

        // ★START押下アニメ（追加）
        .onReceive(timerVM.startPulse) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                flashYellow = true
                flashScale  = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 1.8)) {
                    flashYellow = false
                    flashScale  = false
                }
            }
        }

        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                timerVM.appDidEnterBackground()
                timerVM.saveTimerState()
            case .active:
                timerVM.appWillEnterForeground()
            default:
                break
            }
        }

        .onAppear {
            // 通知の重複防止: 先に必ずremove
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["SessionEnd"])
            if timerVM.isRunning && timerVM.timeRemaining > 0 {
                NotificationManager.shared.scheduleSessionEndNotification(
                    after: timerVM.timeRemaining,
                    phase: timerVM.isWorkSession ? .focus : .breakTime
                )
            }
        }
    }

    // 編集シートを新しいビューに置き換え
    @ViewBuilder
    private func editSheetView() -> some View {
        TimerEditView()
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


