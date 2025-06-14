//
//  SettingsView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

import SwiftUI

struct SettingsView: View {
	// done
	@Environment(\.dismiss) private var dismiss
	
	// ポモドーロと休憩の長さを保存
	@AppStorage("workMinutes") private var workMinutes: Int = 25
	@AppStorage("breakMinutes") private var breakMinutes: Int = 5
	
	// 追加でテーマカラーなどもここに
	@AppStorage("themeColor") private var themeColor: String = "Purple"
	
	var body: some View {
		NavigationStack {
			Form {
				Section(header: Text("Pomodoro Length")) {
					Stepper(value: $workMinutes, in: 1...60, step: 5) {
						Text("\(workMinutes) minutes")
					}
				}
				
				Section(header: Text("Break Length")) {
					Stepper(value: $breakMinutes, in: 3...30, step: 1) {
						Text("\(breakMinutes) minutes")
					}
				}
				
				Section(header: Text("Theme")) {
					Picker("Color", selection: $themeColor) {
						Text("Purple").tag("Purple")
						Text("Blue").tag("Blue")
						Text("Green").tag("Green")
					}
					.pickerStyle(.segmented)
				}
			}
			.navigationTitle("Settings")
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") {
						dismiss()  // ← ここで自分で閉じてOK！
					}
				}
			}
		}
	}
}

