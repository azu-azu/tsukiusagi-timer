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
				MoonView()

				// centre UI
				TimerPanel(timerVM: timerVM)

				// 設定ボタン
				.settingsToolbar(showing: $showingSettings)
				.sheet(isPresented: $showingSettings) {
					SettingsView()
				}
				.navigationBarTitleDisplayMode(.inline)   // optional
			}
		}
	}
}

#Preview {
	NavigationStack { ContentView() }          // preview wrapped too
}
