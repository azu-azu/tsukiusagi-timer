//
//  ContentView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/11.
//

import SwiftUI

struct ContentView: View {
	@StateObject private var timerVM = TimerViewModel()
	@State private var float = false

	var body: some View {
		ZStack {
			// 背景グラデーション
			BackgroundGradientView()

			// 🌕 月の表示
			PoeticMoonView()

			// 🐇 ウサギ画像
			UsagiView()

			// 中央UI（タイマー表示＋Start/Stopボタン）
			VStack(spacing: 40) {
				Spacer()

				Text(timerVM.formatTime())
					.font(.system(size: 48, weight: .bold, design: .rounded))
					.foregroundColor(.white)
					.padding(.top, 100)

				Button(action: {
					if timerVM.isRunning {
						timerVM.stopTimer()
					} else {
						timerVM.startTimer()
					}
				}) {
					Text(timerVM.isRunning ? "Stop" : "Start")
						.font(.title2)
						.padding()
						.frame(width: 160)
						.background(Color.white.opacity(0.2).cornerRadius(12))
						.foregroundColor(.white)
				}

				Spacer()
			}
		}
	}
}


#Preview {
	ContentView()
}
