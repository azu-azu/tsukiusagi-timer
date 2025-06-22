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
    @Environment(\.scenePhase) private var scenePhase

    @State private var flashYellow = false
    @State private var flashScale  = false
    @State private var isEditing = false
    @State private var editedActivity: String = ""
    @State private var editedDetail: String = ""
    @State private var editedMemo: String = ""

    private let buttonWidth: CGFloat = 120
    private let recordBottomPadding: CGFloat = 200   // ← 下から何pt に出す？

    var body: some View {
        // "タイマー中央" と "記録ブロック下端" を別レイヤーで配置
        ZStack {
            // タイマー：常に中央寄り
            timerText()
                .frame(maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center)

            // 記録ブロック：常に下端
            if timerVM.isSessionFinished && !timerVM.isWorkSession {
                recordedTimes()
                    .frame(maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottom)
                    .padding(.bottom, recordBottomPadding)
                    .transition(.opacity)
            }
        }
        // 編集シート
        .sheet(isPresented: $isEditing) { editSheetView() }

        // ★ Moon メッセージと同じ 0.8 秒で同期
        .animation(
            timerVM.shouldSuppressSessionFinishedAnimation ? nil : .easeInOut(duration: 0.8),
            value: timerVM.isSessionFinished
        )
        // アニメーション抑制フラグをリセット
        .onChange(of: timerVM.isSessionFinished) { oldValue, newValue in
            if timerVM.shouldSuppressSessionFinishedAnimation {
                timerVM.shouldSuppressSessionFinishedAnimation = false
            }
        }

        // ★START押下アニメ（追加）
        .onReceive(timerVM.startPulse) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                flashYellow = true
                flashScale  = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    flashYellow = false
                    flashScale  = false
                }
            }
        }

        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                timerVM.appDidEnterBackground()
            case .active:
                timerVM.appWillEnterForeground()
            default:
                break
            }
        }
    }


    // 🕐 時間表示
    private func timerText() -> some View {
        Text(timerVM.formatTime())
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
                        editedMemo     = last.memo   ?? ""
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
                TextField("Memo", text: $editedMemo)

            }
            .navigationTitle("Edit Record")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if var last = historyVM.history.last {
                            last.activity = editedActivity
                            last.detail   = editedDetail
                            last.memo     = editedMemo
                            historyVM.updateLast(activity: editedActivity,
                                                    detail: editedDetail,
                                                    memo: editedMemo)
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


