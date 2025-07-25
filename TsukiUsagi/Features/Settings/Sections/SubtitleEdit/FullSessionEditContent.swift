//
//  FullSessionEditContent.swift
//  TsukiUsagi
//
//  セッション全体編集用コンテンツView
//  責務：
//    - セッション名の編集機能
//    - 複数Descriptionの編集機能
//    - フォーカス状態管理（セッション名 + Description間）
//    - Description追加・削除機能
//

import SwiftUI

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

    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
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
        .onChange(of: focusedField) {  // ✅ iOS 17.0対応: 新しいonChange形式
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

            ForEach(Array(descriptions.enumerated()), id: \.offset) { index, _ in
                VStack(alignment: .leading) {
                    TextField(
                        "Description \(index + 1)",
                        text: self.binding(for: index)
                    )
                    .textFieldStyle(.roundedBorder)
                    .focused(self.$focusedField, equals: .description(index))
                    .submitLabel(index == self.descriptions.count - 1 ? .done : .next)
                    .onSubmit {
                        if index < self.descriptions.count - 1 {
                            self.focusedField = .description(index + 1)
                        }
                    }

                    // 削除ボタン（最後の1つは削除不可）
                    if self.descriptions.count > 1 {
                        Button(
                            action: { self.removeDescription(at: index) }
                        ) {
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
