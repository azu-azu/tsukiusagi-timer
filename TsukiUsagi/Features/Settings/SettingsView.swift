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

    // 設定値
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("detailLabel")   private var detailLabel: String = ""
    @AppStorage("workMinutes")   private var workMinutes: Int = 25
    @AppStorage("breakMinutes")  private var breakMinutes: Int = 5

    // Stopボタン用
    @State private var isPresentingBreakView = false

    var body: some View {
        NavigationStack {
            Form {
                // Work Length
                Section(header: Text("Work Length")) {
                    Stepper(value: $workMinutes, in: 1...60, step: 5) {
                        Text("\(workMinutes) minutes")
                    }
                    .onChange(of: workMinutes) {
                        timerVM.refreshAfterSettingsChange()   // ← ここ！
                    }
                }

                // Break Length
                Section(header: Text("Break Length")) {
                    Stepper(value: $breakMinutes, in: 1...30, step: 1) {
                        Text("\(breakMinutes) minutes")
                    }
                }

                // Activity & Detail Labels
                Section(header: Text("Session Label")) {
                    Picker("Activity", selection: $activityLabel) {
                        ForEach(["Work", "Study", "Read", "Other"], id: \.self) { label in
                            Text(label)
                        }
                    }

                    if activityLabel == "Other" {
                        TextField("Custom Activity", text: $activityLabel)
                    }

                    TextField("Detail (optional)", text: $detailLabel)
                        .textInputAutocapitalization(.never)
                }

                // Reset Timer
                Section {
                    Button(role: .destructive) {
                        timerVM.resetTimer()
                        dismiss()
                    } label: {
                        Label("Reset Timer (No Save)", systemImage: "arrow.uturn.backward")
                    }
                    // Stopボタン修正
                    Button(role: .destructive) {
                        timerVM.forceFinishWorkSession()  // 新しいメソッドを使用
                        dismiss()
                    } label: {
                        Label("Stop (Go to Break)", systemImage: "stop.circle")
                    }
                    .disabled(!timerVM.isRunning)
                    .foregroundStyle(timerVM.isRunning ? .red : Color.gray.opacity(0.6))
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
