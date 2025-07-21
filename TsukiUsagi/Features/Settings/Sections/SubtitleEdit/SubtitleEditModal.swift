// SessionEditModal.swift
//
// Session編集機能のUI実装
// 責務: モーダル表示とユーザーインタラクション

import SwiftUI

// MARK: - EditableModal

/// 再利用可能なモーダル編集UI
///
/// Generic Contentを受け取ることで、様々な編集機能で再利用可能
/// 統一されたナビゲーション構造とボタン配置を提供
struct EditableModal<Content: View>: View {
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    let content: () -> Content
    let isKeyboardCloseVisible: Bool
    let onKeyboardClose: () -> Void

    init(
        title: String,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        isKeyboardCloseVisible: Bool,
        onKeyboardClose: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.onSave = onSave
        self.onCancel = onCancel
        self.isKeyboardCloseVisible = isKeyboardCloseVisible
        self.onKeyboardClose = onKeyboardClose
        self.content = content
    }

    var body: some View {
        NavigationView {
            VStack {
                content()
                Spacer()
            }
            .padding()
            .background(Color.cosmosBackground.ignoresSafeArea())
            .keyboardCloseButton(
                isVisible: isKeyboardCloseVisible,
                action: onKeyboardClose
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .background(Color.cosmosBackground.ignoresSafeArea())
        .interactiveDismissDisabled() // 意図しない閉じ操作を防ぐ
    }
}

// MARK: - SubtitleEditContent

/// Subtitle編集専用のコンテンツView
///
/// セッション名の固定表示とSubtitleの編集フィールドを提供
/// 視覚的に「何が固定で何が編集可能か」を明確に示す
struct SubtitleEditContent: View {
    let sessionName: String
    @State private var subtitles: [String]  // 単一ではなく配列で管理
    let editingIndex: Int?  // 編集中のインデックス（新規の場合はnil）
    let onSubtitlesChange: ([String]) -> Void
    @Binding var isAnyFieldFocused: Bool
    let onClearFocus: () -> Void

    @FocusState private var focusedField: Int?

    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
    }

    /// SubtitleEditContentの初期化
    /// - Parameters:
    ///   - sessionName: セッション名（編集不可・参考表示用）
    ///   - subtitles: 全てのSubtitleリスト
    ///   - editingIndex: 編集対象のインデックス（新規追加の場合はnil）
    ///   - onSubtitlesChange: Subtitleリスト変更時のコールバック
    ///   - isAnyFieldFocused: 外部から制御するフォーカス状態
    ///   - onClearFocus: フォーカスクリア時のコールバック
    init(
        sessionName: String,
        subtitles: [String],
        editingIndex: Int? = nil,
        onSubtitlesChange: @escaping ([String]) -> Void,
        isAnyFieldFocused: Binding<Bool>,
        onClearFocus: @escaping () -> Void
    ) {
        self.sessionName = sessionName
        self.editingIndex = editingIndex
        _subtitles = State(initialValue: subtitles)
        self.onSubtitlesChange = onSubtitlesChange
        self._isAnyFieldFocused = isAnyFieldFocused
        self.onClearFocus = onClearFocus
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionCategorySection
            subtitlesSection
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                if let editingIndex = self.editingIndex {
                    self.focusedField = editingIndex
                } else if !self.subtitles.isEmpty {
                    self.focusedField = self.subtitles.count - 1
                }
            }
        }
        .onChange(of: focusedField) { _, newValue in
            isAnyFieldFocused = newValue != nil
        }
    }

    // MARK: - Private Views

    /// セッションカテゴリ表示部分（編集不可）
    private var sessionCategorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Category")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack {
                Text(sessionName)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                // "固定" を示すロックアイコン
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .accessibilityLabel("Fixed category")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    /// Subtitles編集部分（複数対応）
    private var subtitlesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Descriptions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // 追加ボタン
                Button(action: addSubtitle) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Add description")
            }

            ForEach(Array(subtitles.enumerated()), id: \.offset) { [self] index, subtitle in
                VStack(alignment: .leading) {
                    TextField("Description \(index + 1)", text: self.binding(for: index))
                        .textFieldStyle(.roundedBorder)
                        .focused(self.$focusedField, equals: index)
                        .submitLabel(index == self.subtitles.count - 1 ? .done : .next)
                        .onSubmit { [self] in
                            if index < self.subtitles.count - 1 {
                                self.focusedField = index + 1
                            }
                        }

                    // 削除ボタン（最後の1つは削除不可）
                    if self.subtitles.count > 1 {
                        Button(action: { [self] in self.removeSubtitle(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            // 入力ヒント
            Text("Add descriptions for what you'll work on during this session")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Helper Methods

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { [self] in
                if index < self.subtitles.count {
                    return self.subtitles[index]
                } else {
                    return ""
                }
            },
            set: { [self] newValue in
                if index < self.subtitles.count {
                    self.subtitles[index] = newValue
                    self.onSubtitlesChange(self.subtitles)
                }
            }
        )
    }

    private func addSubtitle() {
        subtitles.append("")
        onSubtitlesChange(subtitles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            self.focusedField = self.subtitles.count - 1
        }
    }

    private func removeSubtitle(at index: Int) {
        guard subtitles.count > 1, index < subtitles.count else { return }
        subtitles.remove(at: index)
        onSubtitlesChange(subtitles)

        // フォーカス調整
        if focusedField == index {
            if index > 0 {
                focusedField = index - 1
            } else if !subtitles.isEmpty {
                focusedField = 0
            }
        } else if let currentFocus = focusedField, currentFocus > index {
            focusedField = currentFocus - 1
        }
    }
}

// MARK: - FullSessionEditContent

/// Custom Session全体編集用のコンテンツView
///
/// セッション名とすべてのSubtitleを編集可能にする
struct FullSessionEditContent: View {
    @State private var sessionName: String
    @State private var subtitles: [String]
    let onSessionNameChange: (String) -> Void
    let onSubtitlesChange: ([String]) -> Void
    @Binding var isAnyFieldFocused: Bool
    let onClearFocus: () -> Void

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case sessionName
        case subtitle(Int)
    }

    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
    }

    /// FullSessionEditContentの初期化
    /// - Parameters:
    ///   - sessionName: 初期のセッション名
    ///   - subtitles: 初期のSubtitleリスト
    ///   - onSessionNameChange: セッション名変更時のコールバック
    ///   - onSubtitlesChange: Subtitleリスト変更時のコールバック
    ///   - isAnyFieldFocused: 外部から制御するフォーカス状態
    ///   - onClearFocus: フォーカスクリア時のコールバック
    init(
        sessionName: String,
        subtitles: [String],
        onSessionNameChange: @escaping (String) -> Void,
        onSubtitlesChange: @escaping ([String]) -> Void,
        isAnyFieldFocused: Binding<Bool>,
        onClearFocus: @escaping () -> Void
    ) {
        _sessionName = State(initialValue: sessionName)
        _subtitles = State(initialValue: subtitles)
        self.onSessionNameChange = onSessionNameChange
        self.onSubtitlesChange = onSubtitlesChange
        self._isAnyFieldFocused = isAnyFieldFocused
        self.onClearFocus = onClearFocus
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionNameSection
            subtitlesSection
        }
        .onAppear {
            // モーダル表示時に自動でセッション名にフォーカス
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                self.focusedField = .sessionName
            }
        }
        .onChange(of: focusedField) { _, newValue in
            isAnyFieldFocused = newValue != nil
        }
    }

    // MARK: - Private Views

    /// セッション名編集部分
    private var sessionNameSection: some View {
        VStack(alignment: .leading) {
            Text("Session Name")
                .font(.headline)
            TextField("Enter session name", text: Binding(
                get: { [self] in self.sessionName },
                set: { [self] newValue in
                    self.sessionName = newValue
                    self.onSessionNameChange(newValue)
                }
            ))
            .textFieldStyle(.roundedBorder)
            .focused(self.$focusedField, equals: .sessionName)
        }
    }

    /// Subtitles編集部分
    private var subtitlesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Descriptions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // 追加ボタン
                Button(action: addSubtitle) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Add description")
            }

            ForEach(Array(subtitles.enumerated()), id: \.offset) { [self] index, subtitle in
                VStack(alignment: .leading) {
                    TextField("Description \(index + 1)", text: self.binding(for: index))
                        .textFieldStyle(.roundedBorder)
                        .focused(self.$focusedField, equals: .subtitle(index))
                        .submitLabel(index == self.subtitles.count - 1 ? .done : .next)
                        .onSubmit { [self] in
                            if index < self.subtitles.count - 1 {
                                self.focusedField = .subtitle(index + 1)
                            }
                        }

                    // 削除ボタン（最後の1つは削除不可）
                    if self.subtitles.count > 1 {
                        Button(action: { [self] in self.removeSubtitle(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            // 入力ヒント
            Text("Add descriptions for what you'll work on during this session")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Helper Methods

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { [self] in
                if index < self.subtitles.count {
                    return self.subtitles[index]
                } else {
                    return ""
                }
            },
            set: { [self] newValue in
                if index < self.subtitles.count {
                    self.subtitles[index] = newValue
                    self.onSubtitlesChange(self.subtitles)
                }
            }
        )
    }

    private func addSubtitle() {
        subtitles.append("")
        onSubtitlesChange(subtitles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            self.focusedField = .subtitle(self.subtitles.count - 1)
        }
    }

    private func removeSubtitle(at index: Int) {
        guard subtitles.count > 1, index < subtitles.count else { return }
        subtitles.remove(at: index)
        onSubtitlesChange(subtitles)

        // フォーカス調整
        if case .subtitle(let focusedIndex) = focusedField, focusedIndex >= index {
            if focusedIndex > 0 {
                focusedField = .subtitle(focusedIndex - 1)
            } else {
                focusedField = .sessionName
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SessionEditModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Subtitle編集のプレビュー
            EditableModal(
                title: "Manage Descriptions",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isKeyboardCloseVisible: false,
                onKeyboardClose: {}
            ) {
                SubtitleEditContent(
                    sessionName: "Work",
                    subtitles: ["SwiftUI development", "Code review"],
                    editingIndex: 0,
                    onSubtitlesChange: { newSubtitles in
                        print("Subtitles changed: \(newSubtitles)")
                    },
                    isAnyFieldFocused: .constant(false),
                    onClearFocus: {}
                )
            }
            .presentationDetents([.large])
            .previewDisplayName("Subtitle Edit")

            // Full Session編集のプレビュー
            EditableModal(
                title: "Edit Session",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isKeyboardCloseVisible: false,
                onKeyboardClose: {}
            ) {
                FullSessionEditContent(
                    sessionName: "My Custom Project",
                    subtitles: ["Task 1", "Task 2", "Task 3"],
                    onSessionNameChange: { newName in
                        print("Session name changed: \(newName)")
                    },
                    onSubtitlesChange: { newSubtitles in
                        print("Subtitles changed: \(newSubtitles)")
                    },
                    isAnyFieldFocused: .constant(false),
                    onClearFocus: {}
                )
            }
            .presentationDetents([.large])
            .previewDisplayName("Full Session Edit")
        }
    }
}
#endif
