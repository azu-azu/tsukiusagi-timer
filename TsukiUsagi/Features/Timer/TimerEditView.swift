import SwiftUI

struct TimerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel

    @State private var editedActivity = ""
    @State private var editedDetail   = ""
    @State private var editedMemo     = ""
    @State private var editedEnd      = Date()
    @State private var minEnd         = Date()

    @FocusState private var isDetailFocused: Bool
    @FocusState private var isMemoFocused: Bool

    var body: some View {
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
                    .focused($isDetailFocused)

                DatePicker(
                    "Final Time",
                    selection: $editedEnd,
                    in: minEnd...,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)

                Section("Memo") {
                    TextEditor(text: $editedMemo)
                        .frame(minHeight: 120, maxHeight: .infinity)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isMemoFocused)
                }
            }
            .navigationTitle("Edit Record")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        historyVM.updateLast(activity: editedActivity,
                                                detail: editedDetail,
                                                memo: editedMemo,
                                                end: editedEnd)
                        timerVM.setEndTime(editedEnd)
                        dismiss()
                    }
                    .disabled(editedActivity.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Close") {
                        isDetailFocused = false
                        isMemoFocused = false
                    }
                }
            }
            .task {
                // 編集画面を開いた時、現在のセッションの値をセット
                editedEnd = timerVM.endTime ?? Date()
                minEnd    = timerVM.startTime ?? Date()
                editedActivity = timerVM.currentActivityLabel
                editedDetail   = timerVM.currentDetailLabel
                editedMemo     = "" // 必要なら timerVM から取得
            }
        }
    }
}