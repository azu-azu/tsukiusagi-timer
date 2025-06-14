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

                ZStack {
                    // 月またはメッセージ
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
                .zIndex(1)  // 月とメッセージを背面に

                // centre UI
                TimerPanel(timerVM: timerVM)
                    .zIndex(2)  // タイマーパネルを前面に

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
