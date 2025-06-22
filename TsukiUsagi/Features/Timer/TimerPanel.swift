//
//  TimerPanel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

// TimerPanel.swift

import SwiftUI

struct TimerPanel: View {
    @ObservedObject var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @AppStorage("sessionLabel") private var sessionLabel: String = "Work"

    @State private var flashYellow = false
    @State private var flashScale  = false
    @State private var isEditing = false
    @State private var editedActivity: String = ""
    @State private var editedDetail: String = ""

    private let spacingBetween: CGFloat = 180
    private let recordDistance: CGFloat = 80
    private let buttonWidth: CGFloat = 120

    var body: some View {
        // 高さはボタンとタイマーだけで決まる
        ZStack(alignment: .bottom) {
            VStack(spacing: spacingBetween) {
                timerText()
                startPauseButton() // ← VStack の最下端 = ボタン下端
            }
            // セッション終了 かつ work セッションだったときのみ表示
            if timerVM.isSessionFinished && !timerVM.isWorkSession {
                recordedTimes()
                    .padding(.bottom, recordDistance)
                    .transition(.opacity)
            }
        }
        // 編集シート
        .sheet(isPresented: $isEditing) { editSheetView() }

        // ★ Moon メッセージと同じ 0.8 秒で同期
        .animation(.easeInOut(duration: 0.8), // ← 追加②
                    value: timerVM.isSessionFinished)
    }


    // 🕐 時間表示
    private func timerText() -> some View {
        Text(timerVM.formatTime())
            // .titleWhiteAvenir(size: 65, weight: .bold)
            .font(.system(size: 65, weight: .bold, design: .rounded))
            .opacity(timerVM.isSessionFinished ? 0 : 1.0)
            .transition(.opacity)                                // ← フェード効果
            .foregroundColor(flashYellow ? .yellow : .white)     // ← 色切替
            .scaleEffect(flashScale ? 1.5 : 1.0, anchor: .center)
    }

    // 🌕 🌑 start / final 記録
    private func recordedTimes() -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                // 上２行：中央
                VStack(spacing: 4) {
                    Text("Start 🌕 \(timerVM.formattedStartTime)")
                    Text("Final 🌑 \(Date(), style: .time)")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .titleWhiteAvenir(size: 18, weight: .regular)
            }

            // ３行目の分数表示
            Text("-- \(timerVM.workLengthMinutes) min.")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .titleWhiteAvenir(size: 18, weight: .regular)
                .frame(maxWidth: 110)

            // ✏️
            HStack {
                Spacer()
                Button {
                    if let last = historyVM.history.last {
                        editedActivity = last.activity
                        editedDetail   = last.detail ?? ""
                        isEditing = true
                    }
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                }
            }
            .frame(maxWidth: 110)
        }
        .padding(.top, 20)
        .transition(.opacity)             // 念押しフェード
    }


    // 🔘 START / PAUSE ボタン
    private let expandAnimationDuration: Double = 0.3
    private func startPauseButton() -> some View {
        Button(timerVM.isRunning ? "PAUSE" : "START") {
            // START の時だけ
            if !timerVM.isRunning {
                withAnimation(.easeInOut(duration: expandAnimationDuration)) {
                    flashYellow = true
                    flashScale  = true             // ★ 拡大 ON
                }
                // 拡大状態でキープしてから戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + expandAnimationDuration + 0.3) { // + キープ時間
                    withAnimation(.easeInOut(duration: 2.0)) {
                        flashYellow = false
                        flashScale  = false
                    }
                }
            }
            timerVM.isRunning ? timerVM.stopTimer() : timerVM.startTimer()
        }
        .padding(.vertical, 12)
        .frame(width: buttonWidth)
        .background(
            Color.white.opacity(0.2),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .titleWhiteAvenir(weight: .bold)
    }

    @ViewBuilder
    private func editSheetView() -> some View {
        NavigationStack {
            Form {
                Picker("Activity", selection: $editedActivity) {
                    ForEach(["Work", "Study", "Read", "Other"], id: \.self) { Text($0) }
                }

                if editedActivity == "Other" {
                    TextField("Custom Activity", text: $editedActivity)
                }

                TextField("Detail", text: $editedDetail)
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle("Edit Record")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if var last = historyVM.history.last {
                            last.activity = editedActivity
                            last.detail   = editedDetail
                            historyVM.updateLast(activity: editedActivity, detail: editedDetail)
                            isEditing = false
                        }
                    }
                    .disabled(editedActivity.isEmpty) // Activity 空欄禁止
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                }
            }
        }
    }
}


