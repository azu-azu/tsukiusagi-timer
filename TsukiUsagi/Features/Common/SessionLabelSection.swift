import SwiftUI

struct SessionLabelSection: View {
    @Binding var activity: String
    @Binding var descriptionText: String
    @FocusState.Binding var isActivityFocused: Bool
    @FocusState.Binding var isDescriptionFocused: Bool
    let labelCornerRadius: CGFloat
    @Binding var showEmptyError: Bool
    let onDone: (() -> Void)?
    @EnvironmentObject var sessionManager: SessionManager

    // 内部で固定値として定義
    private let inputHeight: CGFloat = 28
    private let labelHeight: CGFloat = 28

    // 明示的なCustom Input状態管理
    @State private var isCustomInputMode: Bool = false
    @State private var isCustomDescriptionMode: Bool = false
    @State private var toolbarID = UUID() // ツールバー強制更新用

    private var isCustomActivity: Bool {
        // 明示的なCustom Inputモードまたは空文字の場合
        return isCustomInputMode || activity.isEmpty
    }

    private var isCustomDescription: Bool {
        // 明示的なCustom Descriptionモードまたは選択されたセッションにdescriptionがない場合
        return isCustomDescriptionMode || getCurrentSessionDescriptions().isEmpty
    }

    // 現在選択されているセッションに紐づくdescriptionsを取得
    private func getCurrentSessionDescriptions() -> [String] {
        guard !activity.isEmpty else { return [] }

        // デフォルトセッションから検索
        if let entry = sessionManager.defaultEntries.first(where: { $0.sessionName == activity }) {
            return entry.descriptions
        }

        // カスタムセッションから検索
        if let entry = sessionManager.customEntries.first(where: { $0.sessionName == activity }) {
            return entry.descriptions
        }

        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row with Close button
            HStack {
                // セッション名入力部分
                HStack(alignment: .top) {
                    if isCustomActivity {
                        HStack(spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                if activity.isEmpty {
                                    Text("Enter session name...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                }

                                TextField("", text: $activity)
                                    .foregroundColor(.moonTextPrimary)
                                    .padding(.horizontal, 12)
                                    .frame(height: labelHeight)
                                    .focused($isActivityFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        isActivityFocused = false
                                        onDone?()
                                    }
                                    .onChange(of: isActivityFocused) {
                                        // Haptic feedback removed
                                    }
                                    .onChange(of: activity) {
                                        // セッション名が変更されたらdescriptionもリセット
                                        descriptionText = ""
                                        isCustomDescriptionMode = false
                                    }
                            }
                            .frame(height: labelHeight)
                            .background(
                                (showEmptyError && activity.isEmpty) ?
                                    Color.moonErrorBackground.opacity(0.3) :
                                    Color.white.opacity(0.05)
                            )
                            .cornerRadius(labelCornerRadius)

                            Button {
                                activity = sessionManager.defaultEntries.first?.sessionName ?? "Work"
                                descriptionText = sessionManager.defaultEntries.first?.descriptions.first ?? ""
                                isActivityFocused = false
                                isCustomInputMode = false
                                isCustomDescriptionMode = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.moonTextMuted)
                                    .font(DesignTokens.Fonts.label)
                            }
                        }
                    } else {
                        Menu {
                            // デフォルトセッション
                            ForEach(sessionManager.defaultEntries) { entry in
                                Button {
                                    activity = entry.sessionName
                                    descriptionText = entry.descriptions.first ?? ""
                                    isCustomInputMode = false
                                    isCustomDescriptionMode = false
                                } label: {
                                    Text(entry.sessionName)
                                }
                            }
                            Divider()
                            // カスタムセッション
                            ForEach(sessionManager.customEntries) { entry in
                                Button {
                                    activity = entry.sessionName
                                    descriptionText = entry.descriptions.first ?? ""
                                    isCustomInputMode = false
                                    isCustomDescriptionMode = false
                                } label: {
                                    Text(entry.sessionName)
                                }
                            }
                            Divider()
                            Button("Custom Input...") {
                                activity = ""
                                descriptionText = ""
                                isCustomInputMode = true
                                isCustomDescriptionMode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isActivityFocused = true
                                }
                            }
                        } label: {
                            HStack {
                                Text(activity.isEmpty ? "Custom" : activity)
                                    .foregroundColor(.moonTextPrimary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.moonTextMuted)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: labelHeight)
                            .cornerRadius(labelCornerRadius)
                        }
                    }
                }
            }

            // Description Section
            if isCustomDescription {
                ZStack(alignment: .topLeading) {
                    if descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Description (optional)")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $descriptionText)
                        .frame(height: inputHeight)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                        .focused($isDescriptionFocused)
                        .onChange(of: isDescriptionFocused) {
                            // Haptic feedback removed
                        }
                }
            } else {
                // Description selection menu
                let descriptions = getCurrentSessionDescriptions()
                if !descriptions.isEmpty {
                    Menu {
                        ForEach(descriptions, id: \.self) { descriptionOption in
                            Button {
                                descriptionText = descriptionOption
                                isCustomDescriptionMode = false
                            } label: {
                                HStack {
                                    Text(descriptionOption)
                                    if descriptionText == descriptionOption {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Custom Input...") {
                            isCustomDescriptionMode = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isDescriptionFocused = true
                            }
                        }
                        // 「None」ボタンは、description（説明文）を未設定（空文字）に戻すために必要。
                        // これがないと、一度descriptionを選択・入力した後に「説明文なし」に戻せなくなる。
                        // 例: 「読書」→「集中」→「None」でdescription=""（未設定）に戻す用途。
                        Button("None") {
                            descriptionText = ""
                            isCustomDescriptionMode = false
                        }
                    } label: {
                        HStack {
                            Text(descriptionText.isEmpty ? "Select description..." : descriptionText)
                                .foregroundColor(descriptionText.isEmpty ? .gray : .moonTextPrimary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.moonTextMuted)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: labelHeight)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                    }
                } else {
                    // セッションにdescriptionが設定されていない場合はcustom inputのみ
                    ZStack(alignment: .topLeading) {
                        if descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Description (optional)")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $descriptionText)
                            .frame(height: inputHeight)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(6)
                            .focused($isDescriptionFocused)
                            .onChange(of: isDescriptionFocused) {
                                // Haptic feedback removed
                            }
                    }
                }
            }
        }
        .keyboardCloseButton(
            isVisible: isActivityFocused || isDescriptionFocused,
            topPadding: 8,
            action: {
                KeyboardManager.hideKeyboard {
                    isActivityFocused = false
                    isDescriptionFocused = false
                    onDone?()
                }
            }
        )
        .onChange(of: isActivityFocused) {
            // Haptic feedback removed
            // フォーカス時にツールバーを強制更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toolbarID = UUID()
            }
        }
        .onChange(of: isDescriptionFocused) {
            // Haptic feedback removed
            // フォーカス時にツールバーを強制更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toolbarID = UUID()
            }
        }
        .onAppear {
            // 初期状態で既存セッションが選択されている場合はCustom Inputモードを無効化
            let allSessionNames = sessionManager.allEntries.map { $0.sessionName }
            if allSessionNames.contains(activity) {
                isCustomInputMode = false
                isCustomDescriptionMode = false
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