import SwiftUI

struct SessionLabelSection: View {
    @Binding var activity: String
    @Binding var taskText: String
    @FocusState.Binding var isActivityFocused: Bool
    @FocusState.Binding var isTaskFocused: Bool
    @Binding var showEmptyError: Bool
    let onDone: (() -> Void)?
    @EnvironmentObject var sessionManager: SessionManager

    // 現在選択されているセッションに紐づくタスクを取得
    private func getCurrentSessionTasks() -> [String] {
        guard !activity.isEmpty else { return [] }

        // デフォルトセッションから検索
        if let entry = sessionManager.defaultEntries.first(where: { $0.sessionName == activity }) {
            return entry.tasks
        }

        // カスタムセッションから検索
        if let entry = sessionManager.customEntries.first(where: { $0.sessionName == activity }) {
            return entry.tasks
        }

        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Session Selection Menu - TsukiSound style (centered dropdown)
            HStack {
                Spacer()
                Menu {
                    // デフォルトセッション
                    ForEach(sessionManager.defaultEntries) { entry in
                        Button {
                            activity = entry.sessionName
                            taskText = entry.tasks.first ?? ""
                        } label: {
                            Text(entry.sessionName)
                        }
                    }

                    // カスタムセッションがある場合は区切り線
                    if !sessionManager.customEntries.isEmpty {
                        Divider()
                        ForEach(sessionManager.customEntries) { entry in
                            Button {
                                activity = entry.sessionName
                                taskText = entry.tasks.first ?? ""
                            } label: {
                                Text(entry.sessionName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(activity.isEmpty ? "Select session..." : activity.withSessionEmoji)
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.accentBlue)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(DesignTokens.MoonColors.accentBlue.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                Spacer()
            }

            // Task Selection Menu - TsukiSound style (centered dropdown)
            let tasks = getCurrentSessionTasks()
            if !tasks.isEmpty {
                HStack {
                    Spacer()
                    Menu {
                        ForEach(tasks, id: \.self) { taskOption in
                            Button {
                                taskText = taskOption
                            } label: {
                                HStack {
                                    Text(taskOption)
                                    if taskText == taskOption {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Divider()
                        Button(Labels.State.noTask) {
                            taskText = ""
                        }
                    } label: {
                        HStack {
                            Text(
                                taskText.isEmpty
                                    ? Labels.Settings.manageSessionNames
                                    : taskText.withTaskEmoji
                            )
                                .font(DesignTokens.Fonts.label)
                                .foregroundColor(
                                    taskText.isEmpty
                                    ? DesignTokens.SkyToneColors.textQuinary
                                    : DesignTokens.MoonColors.accentBlue
                                )
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(DesignTokens.MoonColors.accentBlue.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                }
            } else {
                // セッションにタスクが設定されていない場合は空のプレースホルダー
                HStack {
                    Spacer()
                    Text("\(SessionEmoji.task) \(Labels.State.noTasksConfigured)")
                        .foregroundColor(DesignTokens.SkyToneColors.textQuinary)
                        .font(DesignTokens.Fonts.label)
                    Spacer()
                }
            }
        }
        .onAppear {
            // 初期状態でactivityが空の場合はデフォルトセッションを設定
            if activity.isEmpty {
                activity = sessionManager.defaultEntries.first?.sessionName ?? "Work"
                taskText = sessionManager.defaultEntries.first?.tasks.first ?? ""
            }
        }
        .accessibilityIdentifier("SessionLabelSection")
    }
}
