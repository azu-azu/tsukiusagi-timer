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
        VStack(alignment: .leading, spacing: 8) {
            // Session Selection Menu
            Menu {
                // デフォルトセッション
                ForEach(sessionManager.defaultEntries) { entry in
                    Button {
                        activity = entry.sessionName
                        taskText = entry.tasks.first ?? ""
                    } label: {
                        Text(entry.sessionName)
                            .font(DesignTokens.Fonts.label)
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
                                .font(DesignTokens.Fonts.label)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(activity.isEmpty ? "Select session..." : activity)
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(
                            activity.isEmpty
                            ? DesignTokens.MoonColors.textMuted
                            : DesignTokens.MoonColors.textPrimary
                        )
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: labelHeight)
                .background(
                    (showEmptyError && activity.isEmpty) ?
                        Color.moonErrorBackground.opacity(0.3) :
                        DesignTokens.WhiteColors.surface
                )
                .cornerRadius(labelCornerRadius)
            }

            // Task Selection Menu
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
                    Button(NSLocalizedString("session_task_none", comment: "")) {
                        taskText = ""
                    }
                } label: {
                    HStack {
                        Text(
                            taskText.isEmpty
                                ? NSLocalizedString("session_task_select", comment: "")
                                : taskText
                        )
                            .foregroundColor(
                                taskText.isEmpty
                                ? DesignTokens.MoonColors.textMuted
                                : DesignTokens.MoonColors.textPrimary
                            )
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: labelHeight)
                    .background(DesignTokens.WhiteColors.surface)
                    .cornerRadius(6)
                }
            } else {
                // セッションにタスクが設定されていない場合は空のプレースホルダー
                HStack {
                    Text(NSLocalizedString("session_task_none_available", comment: ""))
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .font(DesignTokens.Fonts.label)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: labelHeight)
                .background(DesignTokens.WhiteColors.surface)
                .cornerRadius(6)
            }
        }
        .onAppear {
            // 初期状態でactivityが空の場合はデフォルトセッションを設定
            if activity.isEmpty {
                activity = sessionManager.defaultEntries.first?.sessionName ?? "Work"
                taskText = sessionManager.defaultEntries.first?.tasks.first ?? ""
            }
        }
        .debugSection(String(describing: Self.self), position: .topLeading)
    }
}

// SessionManagerのエントリモデルも更新が必要
// 以下のようにdescriptionsプロパティを追加する必要があります
/*
struct SessionEntry: Identifiable, Codable {
    let id = UUID()
    let sessionName: String
    let descriptions: [String]? // 追加
}
*/
