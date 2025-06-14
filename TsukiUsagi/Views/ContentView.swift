//
//  ContentView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/11.
//

import SwiftUI

struct ContentView: View {
	@StateObject private var historyVM: HistoryViewModel
	@StateObject private var timerVM: TimerViewModel
	@State private var showingSettings = false

	init() {
		let history = HistoryViewModel()
		_historyVM = StateObject(wrappedValue: history)
		_timerVM = StateObject(wrappedValue: TimerViewModel(historyVM: history))
	}

	var body: some View {
		NavigationStack {
			ZStack {
				BackgroundGradientView()
				StarView()

                // 月またはメッセージ
                ZStack {
                    if timerVM.isSessionFinished {
                        Text("おつかれさま 🌕")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        MoonView()
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

				// centre UI
				TimerPanel(timerVM: timerVM)

				// 設定ボタン
				.settingsToolbar(showing: $showingSettings)
				.sheet(isPresented: $showingSettings) {
					SettingsView()
				}
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						DateDisplayView()
					}
				}
				.navigationBarTitleDisplayMode(.inline)   // optional
				.animation(.easeInOut(duration: 0.8), value: timerVM.isSessionFinished)
			}
		}
	}
}

#Preview {
	NavigationStack { ContentView() }          // preview wrapped too
}
