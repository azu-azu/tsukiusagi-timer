//
//  SettingsView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

import SwiftUI

struct SettingsView: View {
    // モーダルを閉じる
    @Environment(\.dismiss) private var dismiss

    // 各種 ViewModel を EnvironmentObject から取得
    @EnvironmentObject private var timerVM:   TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel

    // ポモドーロと休憩の長さ
    @AppStorage("sessionLabel") private var sessionLabel: String = "Work"
    @AppStorage("workMinutes")  private var workMinutes:  Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    var body: some View {
        NavigationStack {
            Form {
                // Work Length
                Section(header: Text("Work Length")) {
                    Stepper(value: $workMinutes, in: 1...60, step: 5) {
                        Text("\(workMinutes) minutes")
                    }
                }

                // Break Length
                Section(header: Text("Break Length")) {
                    Stepper(value: $breakMinutes, in: 1...30, step: 1) {
                        Text("\(breakMinutes) minutes")
                    }
                }

                // Session Label
                Section(header: Text("Session Label")) {
                    Picker("Preset", selection: $sessionLabel) {
                        ForEach(["Work", "Study", "Read", "Other"], id: \.self) { label in
                            Text(label)
                        }
                    }

                    // カスタム入力（"Other" を選んだときだけ出す）
                    if sessionLabel == "Other" {
                        TextField("Custom Label", text: $sessionLabel)
                    }
                }

                // Reset Timer
                Section {
                    Button(role: .destructive) {
                        timerVM.resetTimer()
                    } label: {
                        Label("Reset Timer（0に戻す）", systemImage: "arrow.uturn.backward")
                    }
                }

                // Logs
                Section("Logs") {
                    NavigationLink("View History") {
                        HistoryView()
                            .environmentObject(historyVM) // モデルを渡す
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}