//
//  SettingsView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

import SwiftUI

struct SettingsView: View {
    // ⬅️ モーダルを閉じる
    @Environment(\.dismiss) private var dismiss
    // ⬅️ タイマーVMを取得（EnvironmentObject で渡しておく）
    @EnvironmentObject private var timerVM: TimerViewModel

    // ⌛️ ポモドーロと休憩の長さ
    @AppStorage("workMinutes")  private var workMinutes:  Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    var body: some View {
        NavigationStack {
            Form {
                // ─── Work Length ───
                Section(header: Text("Work Length")) {
                    Stepper(value: $workMinutes, in: 1...60, step: 5) {
                        Text("\(workMinutes) minutes")
                    }
                }

                // ─── Break Length ───
                Section(header: Text("Break Length")) {
                    Stepper(value: $breakMinutes, in: 1...30, step: 1) {
                        Text("\(breakMinutes) minutes")
                    }
                }

                // ─── Reset Timer ───
                Section {
                    Button(role: .destructive) {
                        timerVM.resetTimer()   // ← ここでリセット！
                    } label: {
                        Label("Reset Timer", systemImage: "arrow.uturn.backward")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
