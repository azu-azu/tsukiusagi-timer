//
//  DescriptionEditContent.swift
//  TsukiUsagi
//
//  Description編集専用コンテンツView
//  責務：
//    - セッション名の固定表示（編集不可）
//    - 複数Descriptionの編集機能
//    - フォーカス状態管理
//    - Description追加・削除機能
//

import SwiftUI

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

    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionCategorySection
            descriptionsSection
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let editingIndex {
                    focusedField = editingIndex
                } else if !descriptions.isEmpty {
                    focusedField = descriptions.count - 1
                }
            }
        }
        .onChange(of: focusedField) {
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
                        text: binding(for: index)
                    )
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: index)
                    .submitLabel(index == descriptions.count - 1 ? .done : .next)
                    .onSubmit {
                        if index < descriptions.count - 1 {
                            focusedField = index + 1
                        }
                    }

                    if self.descriptions.count > 1 {
                        Button(
                            action: { self.removeDescription(at: index) },
                            label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        )
                    }
                }
            }

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
                if index < descriptions.count {
                    return descriptions[index]
                } else {
                    return ""
                }
            },
            set: { newValue in
                if index < descriptions.count {
                    descriptions[index] = newValue
                    onDescriptionsChange(descriptions)
                }
            }
        )
    }

    private func addDescription() {
        descriptions.append("")
        onDescriptionsChange(descriptions)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = descriptions.count - 1
        }
    }

    private func removeDescription(at index: Int) {
        guard descriptions.count > 1, index < descriptions.count else { return }
        descriptions.remove(at: index)
        onDescriptionsChange(descriptions)

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
