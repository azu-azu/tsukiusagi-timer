import SwiftUI

struct SessionLabelSection: View {
    @Binding var activity: String
    @Binding var subtitle: String
    @FocusState.Binding var isActivityFocused: Bool
    @FocusState.Binding var isSubtitleFocused: Bool
    let labelCornerRadius: CGFloat
    @Binding var showEmptyError: Bool
    let onDone: (() -> Void)?
    @EnvironmentObject var sessionManager: SessionManager

    // 内部で固定値として定義
    private let inputHeight: CGFloat = 28
    private let labelHeight: CGFloat = 28

    // 明示的なCustom Input状態管理
    @State private var isCustomInputMode: Bool = false
    @State private var isCustomSubtitleMode: Bool = false
    @State private var toolbarID = UUID() // ツールバー強制更新用

    private var isCustomActivity: Bool {
        // 明示的なCustom Inputモードまたは空文字の場合
        return isCustomInputMode || activity.isEmpty
    }

    private var isCustomSubtitle: Bool {
        // 明示的なCustom Subtitleモードまたは選択されたセッションにsubtitleがない場合
        return isCustomSubtitleMode || getCurrentSessionSubtitles().isEmpty
    }

    // 現在選択されているセッションに紐づくsubtitlesを取得
    private func getCurrentSessionSubtitles() -> [String] {
        guard !activity.isEmpty else { return [] }

        // デフォルトセッションから検索
        if let entry = sessionManager.defaultEntries.first(where: { $0.sessionName == activity }) {
            return entry.subtitles
        }

        // カスタムセッションから検索
        if let entry = sessionManager.customEntries.first(where: { $0.sessionName == activity }) {
            return entry.subtitles
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
                                    .onChange(of: isActivityFocused) { _, newValue in
                                        // Haptic feedback removed
                                    }
                                    .onChange(of: activity) { _, newValue in
                                        // セッション名が変更されたらsubtitleもリセット
                                        subtitle = ""
                                        isCustomSubtitleMode = false
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
                                subtitle = sessionManager.defaultEntries.first?.subtitles.first ?? ""
                                isActivityFocused = false
                                isCustomInputMode = false
                                isCustomSubtitleMode = false
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
                                    subtitle = entry.subtitles.first ?? ""
                                    isCustomInputMode = false
                                    isCustomSubtitleMode = false
                                } label: {
                                    Text(entry.sessionName)
                                }
                            }
                            Divider()
                            // カスタムセッション
                            ForEach(sessionManager.customEntries) { entry in
                                Button {
                                    activity = entry.sessionName
                                    subtitle = entry.subtitles.first ?? ""
                                    isCustomInputMode = false
                                    isCustomSubtitleMode = false
                                } label: {
                                    Text(entry.sessionName)
                                }
                            }
                            Divider()
                            Button("Custom Input...") {
                                activity = ""
                                subtitle = ""
                                isCustomInputMode = true
                                isCustomSubtitleMode = true
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

            // Subtitle Section
            if isCustomSubtitle {
                ZStack(alignment: .topLeading) {
                    if subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Subtitle (optional)")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $subtitle)
                        .frame(height: inputHeight)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                        .focused($isSubtitleFocused)
                        .onChange(of: isSubtitleFocused) { _, newValue in
                            // Haptic feedback removed
                        }
                }
            } else {
                // Subtitle selection menu
                let subtitles = getCurrentSessionSubtitles()
                if !subtitles.isEmpty {
                    Menu {
                        ForEach(subtitles, id: \.self) { subtitleOption in
                            Button {
                                subtitle = subtitleOption
                                isCustomSubtitleMode = false
                            } label: {
                                HStack {
                                    Text(subtitleOption)
                                    if subtitle == subtitleOption {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Custom Input...") {
                            isCustomSubtitleMode = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSubtitleFocused = true
                            }
                        }
                        // 「None」ボタンは、subtitle（サブタイトル）を未設定（空文字）に戻すために必要。
                        // これがないと、一度subtitleを選択・入力した後に「サブタイトルなし」に戻せなくなる。
                        // 例: 「読書」→「集中」→「None」でsubtitle=""（未設定）に戻す用途。
                        Button("None") {
                            subtitle = ""
                            isCustomSubtitleMode = false
                        }
                    } label: {
                        HStack {
                            Text(subtitle.isEmpty ? "Select subtitle..." : subtitle)
                                .foregroundColor(subtitle.isEmpty ? .gray : .moonTextPrimary)
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
                    // セッションにsubtitleが設定されていない場合はcustom inputのみ
                    ZStack(alignment: .topLeading) {
                        if subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Subtitle (optional)")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $subtitle)
                            .frame(height: inputHeight)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(6)
                            .focused($isSubtitleFocused)
                            .onChange(of: isSubtitleFocused) { _, newValue in
                                // Haptic feedback removed
                            }
                    }
                }
            }
        }
        .keyboardCloseButton(
            isVisible: isActivityFocused || isSubtitleFocused,
            topPadding: 8,
            action: {
                KeyboardManager.hideKeyboard {
                    isActivityFocused = false
                    isSubtitleFocused = false
                    onDone?()
                }
            }
        )
        .onChange(of: isActivityFocused) { _, newValue in
            // Haptic feedback removed
            // フォーカス時にツールバーを強制更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toolbarID = UUID()
            }
        }
        .onChange(of: isSubtitleFocused) { _, newValue in
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
                isCustomSubtitleMode = false
            }
        }
        .debugSection(String(describing: Self.self), position: .topLeading)
    }
}

// SessionManagerのエントリモデルも更新が必要
// 以下のようにsubtitlesプロパティを追加する必要があります
/*
struct SessionEntry: Identifiable, Codable {
    let id = UUID()
    let sessionName: String
    let subtitles: [String]? // 追加
}
*/