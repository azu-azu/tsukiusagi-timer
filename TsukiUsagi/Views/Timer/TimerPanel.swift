//
//  TimerPanel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

import SwiftUI

struct TimerPanel: View {
	@ObservedObject var timerVM: TimerViewModel

	var body: some View {
		VStack(spacing: 40) {
			Spacer()

			Text(timerVM.formatTime())
				.font(.system(size: 48, weight: .bold, design: .rounded))
				.foregroundColor(.white)
				.padding(.top, 100)

			Button(timerVM.isRunning ? "Stop" : "Start") {
				timerVM.isRunning ? timerVM.stopTimer() : timerVM.startTimer()
			}
			.font(.title2)
			.padding()
			.frame(width: 160)
			.background(Color.white.opacity(0.2),
						in: RoundedRectangle(cornerRadius: 12))
			.foregroundColor(.white)

			Spacer()
		}
	}
}


