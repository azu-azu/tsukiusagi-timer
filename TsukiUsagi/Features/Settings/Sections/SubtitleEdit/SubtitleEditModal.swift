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

// MARK: - DescriptionEditContent

/// Description編集専用のコンテンツView
///
/// セッション名の固定表示とDescriptionの編集フィールドを提供
/// 視覚的に「何が固定で何が編集可能か」を明確に示す
struct DescriptionEditContent: View {
    let sessionName: String
    @State private var descriptions: [String]  // 単一ではなく配列で管理
    let editingIndex: Int?  // 編集中のインデックス（新規の場合はnil）
    let onDescriptionsChange: ([String]) -> Void
    @Binding var isAnyFieldFocused: Bool
    let onClearFocus: () -> Void

    @FocusState private var focusedField: Int?

    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
    }

    /// DescriptionEditContentの初期化
    /// - Parameters:
    ///   - sessionName: セッション名（編集不可・参考表示用）
    ///   - descriptions: 全てのDescriptionリスト
    ///   - editingIndex: 編集対象のインデックス（新規追加の場合はnil）
    ///   - onDescriptionsChange: Descriptionリスト変更時のコールバック
    ///   - isAnyFieldFocused: 外部から制御するフォーカス状態
    ///   - onClearFocus: フォーカスクリア時のコールバック
    init(
        sessionName: String,
        descriptions: [String],
        editingIndex: Int? = nil,
        onDescriptionsChange: @escaping ([String]) -> Void,
        isAnyFieldFocused: Binding<Bool>,
        onClearFocus: @escaping () -> Void
    ) {
        self.sessionName = sessionName
        self.editingIndex = editingIndex
        _descriptions = State(initialValue: descriptions)
        self.onDescriptionsChange = onDescriptionsChange
        self._isAnyFieldFocused = isAnyFieldFocused
        self.onClearFocus = onClearFocus
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionCategorySection
            descriptionsSection
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                if let editingIndex = self.editingIndex {
                    self.focusedField = editingIndex
                } else if !self.descriptions.isEmpty {
                    self.focusedField = self.descriptions.count - 1
                }
            }
        }
        .onChange(of: focusedField) { _ in
            isAnyFieldFocused = focusedField != nil
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

    /// Descriptions編集部分（複数対応）
    private var descriptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Descriptions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // 追加ボタン
                Button(action: addDescription) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Add description")
            }

            ForEach(Array(descriptions.enumerated()), id: \.offset) { [self] index, description in
                VStack(alignment: .leading) {
                    TextField("Description \(index + 1)", text: self.binding(for: index))
                        .textFieldStyle(.roundedBorder)
                        .focused(self.$focusedField, equals: index)
                        .submitLabel(index == self.descriptions.count - 1 ? .done : .next)
                        .onSubmit { [self] in
                            if index < self.descriptions.count - 1 {
                                self.focusedField = index + 1
                            }
                        }

                    // 削除ボタン（最後の1つは削除不可）
                    if self.descriptions.count > 1 {
                        Button(action: { [self] in self.removeDescription(at: index) }) {
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

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { [self] in
                if index < self.descriptions.count {
                    return self.descriptions[index]
                } else {
                    return ""
                }
            },
            set: { [self] newValue in
                if index < self.descriptions.count {
                    self.descriptions[index] = newValue
                    self.onDescriptionsChange(self.descriptions)
                }
            }
        )
    }

    private func addDescription() {
        descriptions.append("")
        onDescriptionsChange(descriptions)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            self.focusedField = self.descriptions.count - 1
        }
    }

    private func removeDescription(at index: Int) {
        guard descriptions.count > 1, index < descriptions.count else { return }
        descriptions.remove(at: index)
        onDescriptionsChange(descriptions)

        // フォーカス調整
        if focusedField == index {
            if index > 0 {
                focusedField = index - 1
            } else if !descriptions.isEmpty {
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
/// セッション名とすべてのDescriptionを編集可能にする
struct FullSessionEditContent: View {
    @State private var sessionName: String
    @State private var descriptions: [String]
    let onSessionNameChange: (String) -> Void
    let onDescriptionsChange: ([String]) -> Void
    @Binding var isAnyFieldFocused: Bool
    let onClearFocus: () -> Void

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case sessionName
        case description(Int)
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
    ///   - descriptions: 初期のDescriptionリスト
    ///   - onSessionNameChange: セッション名変更時のコールバック
    ///   - onDescriptionsChange: Descriptionリスト変更時のコールバック
    ///   - isAnyFieldFocused: 外部から制御するフォーカス状態
    ///   - onClearFocus: フォーカスクリア時のコールバック
    init(
        sessionName: String,
        descriptions: [String],
        onSessionNameChange: @escaping (String) -> Void,
        onDescriptionsChange: @escaping ([String]) -> Void,
        isAnyFieldFocused: Binding<Bool>,
        onClearFocus: @escaping () -> Void
    ) {
        _sessionName = State(initialValue: sessionName)
        _descriptions = State(initialValue: descriptions)
        self.onSessionNameChange = onSessionNameChange
        self.onDescriptionsChange = onDescriptionsChange
        self._isAnyFieldFocused = isAnyFieldFocused
        self.onClearFocus = onClearFocus
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionNameSection
            descriptionsSection
        }
        .onAppear {
            // モーダル表示時に自動でセッション名にフォーカス
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                self.focusedField = .sessionName
            }
        }
        .onChange(of: focusedField) { _ in
            isAnyFieldFocused = focusedField != nil
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

    /// Descriptions編集部分
    private var descriptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Descriptions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // 追加ボタン
                Button(action: addDescription) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Add description")
            }

            ForEach(Array(descriptions.enumerated()), id: \.offset) { [self] index, description in
                VStack(alignment: .leading) {
                    TextField("Description \(index + 1)", text: self.binding(for: index))
                        .textFieldStyle(.roundedBorder)
                        .focused(self.$focusedField, equals: .description(index))
                        .submitLabel(index == self.descriptions.count - 1 ? .done : .next)
                        .onSubmit { [self] in
                            if index < self.descriptions.count - 1 {
                                self.focusedField = .description(index + 1)
                            }
                        }

                    // 削除ボタン（最後の1つは削除不可）
                    if self.descriptions.count > 1 {
                        Button(action: { [self] in self.removeDescription(at: index) }) {
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
                if index < self.descriptions.count {
                    return self.descriptions[index]
                } else {
                    return ""
                }
            },
            set: { [self] newValue in
                if index < self.descriptions.count {
                    self.descriptions[index] = newValue
                    self.onDescriptionsChange(self.descriptions)
                }
            }
        )
    }

    private func addDescription() {
        descriptions.append("")
        onDescriptionsChange(descriptions)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            self.focusedField = .description(self.descriptions.count - 1)
        }
    }

    private func removeDescription(at index: Int) {
        guard descriptions.count > 1, index < descriptions.count else { return }
        descriptions.remove(at: index)
        onDescriptionsChange(descriptions)

        // フォーカス調整
        if case .description(let focusedIndex) = focusedField, focusedIndex >= index {
            if focusedIndex > 0 {
                focusedField = .description(focusedIndex - 1)
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
            // Description編集のプレビュー
            EditableModal(
                title: "Manage Descriptions",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isKeyboardCloseVisible: false,
                onKeyboardClose: {},
                content: {
                    DescriptionEditContent(
                        sessionName: "Work",
                        descriptions: ["SwiftUI development", "Code review"],
                        editingIndex: 0,
                        onDescriptionsChange: { newDescriptions in
                            print("Descriptions changed: \(newDescriptions)")
                        },
                        isAnyFieldFocused: .constant(false),
                        onClearFocus: {}
                    )
                }
            )
            .presentationDetents([.large])
            .previewDisplayName("Description Edit")

            // Full Session編集のプレビュー
            EditableModal(
                title: "Edit Session",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isKeyboardCloseVisible: false,
                onKeyboardClose: {},
                content: {
                    FullSessionEditContent(
                        sessionName: "My Custom Project",
                        descriptions: ["Task 1", "Task 2", "Task 3"],
                        onSessionNameChange: { newName in
                            print("Session name changed: \(newName)")
                        },
                        onDescriptionsChange: { newDescriptions in
                            print("Descriptions changed: \(newDescriptions)")
                        },
                        isAnyFieldFocused: .constant(false),
                        onClearFocus: {}
                    )
                }
            )
            .presentationDetents([.large])
            .previewDisplayName("Full Session Edit")
        }
    }
}
#endif
