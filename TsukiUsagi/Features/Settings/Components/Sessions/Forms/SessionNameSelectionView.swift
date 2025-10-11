import SwiftUI

struct SessionNameSelectionView: View {
    @Binding var editingName: String
    @Binding var editingTasks: [String]
    @Binding var isCustomInputMode: Bool
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                menuContent
            } label: {
                menuLabelView
            }
            .onAppear {
                // 編集開始時に既存のセッション名が設定されている場合、そのセッションを選択状態にする
                if !editingName.isEmpty && !isCustomInputMode {
                    // 既存のセッション名が設定されている場合は何もしない（既に正しい状態）
                }
            }
        }
    }

    // メニューコンテンツ
    private var menuContent: some View {
        Group {
            // デフォルトセッション
            ForEach(sessionManager.defaultEntries) { entry in
                Button {
                    editingName = entry.sessionName
                    editingTasks = entry.tasks
                } label: {
                    Text(entry.sessionName)
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
            }
            Divider()
            // カスタムセッション
            ForEach(sessionManager.customEntries) { entry in
                Button {
                    editingName = entry.sessionName
                    editingTasks = entry.tasks
                } label: {
                    Text(entry.sessionName)
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
            }
            Divider()
            Button("Custom Input...") {
                isCustomInputMode = true
                editingName = ""
                editingTasks = [""]
            }
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
        }
    }

    // メニューラベル
    private var menuLabelView: some View {
        HStack {
            Text(editingName.isEmpty ? "Select Session" : editingName)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(editingName.isEmpty ? DesignTokens.MoonColors.textSecondary : .moonTextPrimary)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}
