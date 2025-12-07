import SwiftUI

struct SessionLabelSection: View {
    @Binding var activity: String
    @Binding var taskText: String
    @FocusState.Binding var isActivityFocused: Bool
    @FocusState.Binding var isTaskFocused: Bool
    let labelCornerRadius: CGFloat
    @Binding var showEmptyError: Bool
    let onDone: (() -> Void)?
    @EnvironmentObject var sessionManager: SessionManager

    // 内部で固定値として定義
    private let inputHeight: CGFloat = 28
    private let labelHeight: CGFloat = 28

    // ツールバー強制更新用
    @State private var toolbarID = UUID()

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
        VStack(alignment: .leading, spacing: 12) {
            // Session Selection Menu - TsukiSound style
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
                    Text(activity.isEmpty ? "Select session..." : activity)
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.MoonColors.accentBlue.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                (showEmptyError && activity.isEmpty)
                                ? Color.moonErrorBackground.opacity(0.3)
                                : Color.white.opacity(0.15)
                            )
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                .contentShape(Rectangle())
            }

            // Task Selection Menu - TsukiSound style
            let tasks = getCurrentSessionTasks()
            if !tasks.isEmpty {
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
                                : taskText
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.02)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                    .contentShape(Rectangle())
                }
            } else {
                // セッションにタスクが設定されていない場合は空のプレースホルダー
                HStack {
                    Text(Labels.State.noTasksConfigured)
                        .foregroundColor(DesignTokens.SkyToneColors.textQuinary)
                        .font(DesignTokens.Fonts.label)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
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

// SessionManagerのエントリモデルも更新が必要
// 以下のようにtasksプロパティを追加する必要があります
/*
struct SessionEntry: Identifiable, Codable {
    let id = UUID()
    let sessionName: String
    let tasks: [String]? // 追加
}
*/
