//
//  TimerPanel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

//
//  TimerPanel.swift
//  TsukiUsagi
//

import SwiftUI

struct TimerPanel: View {
    @ObservedObject var timerVM: TimerViewModel

	private let spacing: CGFloat = 20 // timerとボタンの間の余白

    var body: some View {
        VStack(spacing: spacing) {
            Spacer()

            // 残り時間 ── セッションが終わったら 50% 透過
            Text(timerVM.formatTime())
                .titleWhite(size: 48, design: .rounded)
                .opacity(timerVM.isSessionFinished ? 0.3 : 1.0)   // ← ここ！
                .padding(.top, 100)

            // Start / Stop ボタン
            Button(timerVM.isRunning ? "Stop" : "Start") {
                timerVM.isRunning ? timerVM.stopTimer() : timerVM.startTimer()
            }
            .font(.title2)
            .padding()
            .frame(width: 160)
            .background(
                Color.white.opacity(0.2),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundColor(.white)

            Spacer()
        }
    }
}
