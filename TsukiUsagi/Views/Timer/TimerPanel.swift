//
//  TimerPanel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

// TimerPanel.swift

import SwiftUI

struct TimerPanel: View {
    @ObservedObject var timerVM: TimerViewModel

    private let spacingBetween: CGFloat = 180
    private let recordDistance: CGFloat = 100
    private let buttonWidth: CGFloat = 160

    var body: some View {
        // 高さはボタンとタイマーだけで決まる
        ZStack(alignment: .bottom) {
            VStack(spacing: spacingBetween) {
                timerText()
                startStopButton() // ← VStack の最下端 = ボタン下端
            }
            // 終了後だけ「重ねる」ので高さに影響しない
            if timerVM.isSessionFinished {
                recordedTimes()
                    .padding(.bottom, recordDistance)  // ← ボタンから X pt 上に表示
            }
        }
    }

    // ⏱ 残り時間表示
    private func timerText() -> some View {
        Text(timerVM.formatTime())
            .titleWhiteAvenir(size: 65, weight: .bold)
            .opacity(timerVM.isSessionFinished ? 0.1 : 1.0)
            .blur(radius: timerVM.isSessionFinished ? 2 : 0)
    }

    // 記録時刻（start / final）── 終了時のみ表示される
    private func recordedTimes() -> some View {
        VStack(spacing: 2) {
            Text("start  ⏳  \(timerVM.formattedStartTime)")
            Text("final  ⌛️  \(Date(), style: .time)")
        }
        .titleWhiteAvenir(weight: .regular)
        .padding(.top, 20)
    }

    // ▶︎ START / PAUSE ボタン
    private func startStopButton() -> some View {
        Button(timerVM.isRunning ? "PAUSE" : "START") {
            timerVM.isRunning ? timerVM.stopTimer() : timerVM.startTimer()
        }
        .padding()
        .frame(width: buttonWidth)
        .background(
            Color.white.opacity(0.3),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .titleWhiteAvenir(weight: .bold)
    }
}
