import SwiftUI

struct SessionTasksView: View {
    @Binding var editingName: String
    @Binding var editingTasks: [String]
    @FocusState.Binding var isTaskFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            taskHeaderView
            taskListView
            addTaskButtonView
        }
    }

    // Task ヘッダー
    private var taskHeaderView: some View {
        HStack {
            Text("Tasks")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            if !editingName.isEmpty {
                Text("for \"\(editingName)\"")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
        }
    }

    // Task リスト
    private var taskListView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(editingTasks.indices, id: \.self) { idx in
                taskRowView(at: idx)
            }
        }
    }

    // Task 行
    private func taskRowView(at idx: Int) -> some View {
        HStack {
            // インデント表現
            Rectangle()
                .fill(Color.clear)
                .frame(width: 16, height: 1)

            TextField("Task \(idx + 1)", text: Binding(
                get: { editingTasks[safe: idx] ?? "" },
                set: { newValue in
                    if idx < editingTasks.count {
                        editingTasks[idx] = newValue
                    }
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .accessibilityIdentifier(AccessibilityIDs.SessionManager.taskField)
            .focused($isTaskFocused)
            .onChange(of: isTaskFocused) {
                // Focus handling
            }

            Button(action: { editingTasks.remove(at: idx) }, label: {
                Image(systemName: "minus.circle")
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            })
            .buttonStyle(.plain)
            .disabled(editingTasks.count == 1)
        }
    }

    // Add Task ボタン
    private var addTaskButtonView: some View {
        HStack {
            // インデント表現
            Rectangle()
                .fill(Color.clear)
                .frame(width: 16, height: 1)

            Button(action: { editingTasks.append("") }, label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Add Task")
                }
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            })
            .font(DesignTokens.Fonts.caption)
            .buttonStyle(.plain)
            .disabled(
                editingName.isEmpty ||
                (
                    editingTasks.first?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty ?? true
                )
            )

            Spacer()
        }
    }
}
