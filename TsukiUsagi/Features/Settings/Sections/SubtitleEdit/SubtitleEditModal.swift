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

    var body: some View {
        NavigationView {
            VStack {
                content()
                Spacer()
            }
            .padding()
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

    @FocusState private var focusedField: Int?

    /// SubtitleEditContentの初期化
    /// - Parameters:
    ///   - sessionName: セッション名（編集不可・参考表示用）
    ///   - subtitles: 全てのSubtitleリスト
    ///   - editingIndex: 編集対象のインデックス（新規追加の場合はnil）
    ///   - onSubtitlesChange: Subtitleリスト変更時のコールバック
    init(sessionName: String, subtitles: [String], editingIndex: Int? = nil, onSubtitlesChange: @escaping ([String]) -> Void) {
        self.sessionName = sessionName
        self.editingIndex = editingIndex
        self._subtitles = State(initialValue: subtitles)
        self.onSubtitlesChange = onSubtitlesChange
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionCategorySection
            subtitlesSection
        }
        .onAppear {
            // モーダル表示時に適切なフィールドにフォーカス
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let editingIndex = editingIndex {
                    focusedField = editingIndex
                } else if !subtitles.isEmpty {
                    focusedField = subtitles.count - 1
                }
            }
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

            ForEach(Array(subtitles.enumerated()), id: \.offset) { index, subtitle in
                HStack {
                    TextField("Description \(index + 1)", text: binding(for: index))
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: index)
                        .submitLabel(index == subtitles.count - 1 ? .done : .next)
                        .onSubmit {
                            if index < subtitles.count - 1 {
                                focusedField = index + 1
                            }
                        }

                    // 削除ボタン
                    if subtitles.count > 1 {
                        Button(action: { removeSubtitle(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Remove description")
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
            get: {
                if index < subtitles.count {
                    return subtitles[index]
                } else {
                    return ""
                }
            },
            set: { newValue in
                if index < subtitles.count {
                    subtitles[index] = newValue
                    onSubtitlesChange(subtitles)
                }
            }
        )
    }

    private func addSubtitle() {
        subtitles.append("")
        onSubtitlesChange(subtitles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = subtitles.count - 1
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

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case sessionName
        case subtitle(Int)
    }

    /// FullSessionEditContentの初期化
    /// - Parameters:
    ///   - sessionName: 初期のセッション名
    ///   - subtitles: 初期のSubtitleリスト
    ///   - onSessionNameChange: セッション名変更時のコールバック
    ///   - onSubtitlesChange: Subtitleリスト変更時のコールバック
    init(sessionName: String, subtitles: [String], onSessionNameChange: @escaping (String) -> Void, onSubtitlesChange: @escaping ([String]) -> Void) {
        self._sessionName = State(initialValue: sessionName)
        self._subtitles = State(initialValue: subtitles)
        self.onSessionNameChange = onSessionNameChange
        self.onSubtitlesChange = onSubtitlesChange
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionNameSection
            subtitlesSection
        }
        .onAppear {
            // モーダル表示時に自動でセッション名にフォーカス
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .sessionName
            }
        }
    }

    // MARK: - Private Views

    /// セッション名編集部分
    private var sessionNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Session Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // "編集可能" を示すペンシルアイコン
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .accessibilityLabel("Editable session name")
            }

            TextField("Enter session name", text: $sessionName)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .sessionName)
                .onChange(of: sessionName) { _, newValue in
                    onSessionNameChange(newValue)
                }
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .subtitle(0)
                }
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

            ForEach(Array(subtitles.enumerated()), id: \.offset) { index, subtitle in
                HStack {
                    TextField("Description \(index + 1)", text: binding(for: index))
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .subtitle(index))
                        .submitLabel(index == subtitles.count - 1 ? .done : .next)
                        .onSubmit {
                            if index < subtitles.count - 1 {
                                focusedField = .subtitle(index + 1)
                            }
                        }

                    // 削除ボタン
                    if subtitles.count > 1 {
                        Button(action: { removeSubtitle(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Remove description")
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
            get: {
                if index < subtitles.count {
                    return subtitles[index]
                } else {
                    return ""
                }
            },
            set: { newValue in
                if index < subtitles.count {
                    subtitles[index] = newValue
                    onSubtitlesChange(subtitles)
                }
            }
        )
    }

    private func addSubtitle() {
        subtitles.append("")
        onSubtitlesChange(subtitles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .subtitle(subtitles.count - 1)
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
                onCancel: { print("Cancel tapped") }
            ) {
                SubtitleEditContent(
                    sessionName: "Work",
                    subtitles: ["SwiftUI development", "Code review"],
                    editingIndex: 0
                ) { newSubtitles in
                    print("Subtitles changed: \(newSubtitles)")
                }
            }
            .presentationDetents([.large])
            .previewDisplayName("Subtitle Edit")

            // Full Session編集のプレビュー
            EditableModal(
                title: "Edit Session",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") }
            ) {
                FullSessionEditContent(
                    sessionName: "My Custom Project",
                    subtitles: ["Task 1", "Task 2", "Task 3"]
                ) { newName in
                    print("Session name changed: \(newName)")
                } onSubtitlesChange: { newSubtitles in
                    print("Subtitles changed: \(newSubtitles)")
                }
            }
            .presentationDetents([.large])
            .previewDisplayName("Full Session Edit")
        }
    }
}
#endif
