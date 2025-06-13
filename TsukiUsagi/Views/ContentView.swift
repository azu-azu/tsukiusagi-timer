//
//  ContentView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/11.
//

import SwiftUI

struct ContentView: View {
	@StateObject private var timerVM = TimerViewModel()
	@State private var showingSettings = false
	
	var body: some View {
		NavigationStack {
			ZStack {
				BackgroundGradientView()
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
