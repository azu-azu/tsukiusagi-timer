import SwiftUI

struct NewSessionFormView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var name: String = ""
    @State private var descriptionTexts: [String] = [""]
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @State private var errorTitle: String = "Error"

    // SessionLabelSectionと同じ状態管理
    @State private var isCustomInputMode: Bool = false

    // SessionLabelSectionと同じ定数
    private let inputHeight: CGFloat = 28
    private let labelHeight: CGFloat = 28
    private let labelCornerRadius: CGFloat = 6

    private var isCustomActivity: Bool {
        // NewSessionFormView用に調整：明示的にCustom Inputが選択された場合のみtrue
        return isCustomInputMode
    }

    var isAddDisabled: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptions = descriptionTexts.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // Session Nameが空の場合は無効
        if trimmedName.isEmpty { return true }

        // descriptionが1つも入力されていない場合は無効
        if descriptions.isEmpty { return true }

        // 文字数超過
        if trimmedName.count > SessionManager.maxNameLength { return true }
        if descriptions.contains(where: { $0.count > SessionManager.maxDescriptionLength }) { return true }
        // 最大数超過
        if descriptions.count > SessionManager.maxDescriptionCount { return true }
        // セッション数超過（空文字でない場合のみチェック）
        if !trimmedName.isEmpty &&
            !sessionManager.defaultSessionNames.contains(trimmedName) &&
            sessionManager.customEntries.count >= SessionManager.maxSessionCount &&
            sessionManager.sessionDatabase[trimmedName.lowercased()] == nil {
            return true
        }
        // 重複禁止（空文字でない場合のみチェック）
        if !trimmedName.isEmpty,
            let existing = sessionManager.sessionDatabase[trimmedName.lowercased()],
            !sessionManager.defaultSessionNames.contains(trimmedName) {
            if !existing.isDefault { return true }
        }
        return false
    }

    var saveButtonTitle: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // 既存のセッション名が選択されている場合
        if !trimmedName.isEmpty &&
            sessionManager.allEntries.map({ $0.sessionName }).contains(trimmedName) {
            return "Update \"\(trimmedName)\""
        }

        // 新規セッション作成の場合
        return "Create Session"
    }

    var body: some View {
        RoundedCard(backgroundColor: DesignTokens.Colors.cosmosCardBG) {
            VStack(alignment: .leading, spacing: 12) {
                // SessionLabelSectionと同じ構造のSession Name選択部分
                HStack(alignment: .top) {
                    if isCustomActivity {
                        HStack(spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                if name.isEmpty {
                                    Text("Enter session name...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                }

                                TextField("", text: $name)
                                    .foregroundColor(.moonTextPrimary)
                                    .padding(.horizontal, 12)
                                    .frame(height: labelHeight)
                                    .focused($isNameFocused)
                                    .onChange(of: isNameFocused) { _, newValue in
                                        if newValue {
                                        }
                                    }
                            }
                            .frame(height: labelHeight)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(labelCornerRadius)
                            .frame(maxWidth: .infinity)

                            Button {
                                name = sessionManager.defaultEntries.first?.sessionName ?? "Work"
                                isCustomInputMode = false
                                isNameFocused = false
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
                                    name = entry.sessionName
                                    isCustomInputMode = false
                                } label: {
                                    Text(entry.sessionName)
                                }
                            }
                            Divider()
                            // カスタムセッション
                            ForEach(sessionManager.customEntries) { entry in
                                Button {
                                    name = entry.sessionName
                                    isCustomInputMode = false
                                } label: {
                                    Text(entry.sessionName)
                                }
                            }
                            Divider()
                            Button("Custom Input...") {
                                name = ""
                                isCustomInputMode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isNameFocused = true
                                }
                            }
                        } label: {
                            HStack {
                                Text(name.isEmpty ? "Select Session" : name)
                                    .foregroundColor(name.isEmpty ? .secondary : .moonTextPrimary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.moonTextMuted)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: labelHeight)
                            .cornerRadius(labelCornerRadius)
                        }
                    }

                    Spacer(minLength: 8)
                }

                // Subtitle入力欄もSessionLabelSectionと同じスタイルに統一
                ForEach(descriptionTexts.indices, id: \.self) { idx in
                    HStack {
                        ZStack(alignment: .topLeading) {
                            if descriptionTexts[safe: idx]?
                                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                                Text(idx == 0 ? "Description (optional)" : "Description \(idx + 1)")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }

                            TextEditor(text: Binding(
                                get: { descriptionTexts[safe: idx] ?? "" },
                                set: { newValue in
                                    if idx < descriptionTexts.count {
                                        descriptionTexts[idx] = newValue
                                    }
                                }
                            ))
                            .frame(height: inputHeight)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(labelCornerRadius)
                            .focused($isDescriptionFocused)
                            .onChange(of: isDescriptionFocused) { _, newValue in
                                if newValue {
                                }
                            }
                        }

                        // 2個目以降にのみマイナスボタンを表示、1個目はスペース確保
                        if idx > 0 {
                            Button(
                                action: {
                                    descriptionTexts.remove(at: idx)
                                },
                                label: {
                                    Image(systemName: "minus.circle")
                                }
                            )
                            .buttonStyle(.plain)
                        } else {
                            // 1個目は透明なスペーサーで横幅を統一
                            Color.clear
                                .frame(width: 24, height: 24)
                        }
                    }
                }

                Button(
                    action: {
                        descriptionTexts.append("")
                    },
                    label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Add Description")
                        }
                    }
                )
                .font(DesignTokens.Fonts.caption)
                .buttonStyle(.plain)
                .disabled(
                    name.isEmpty ||
                    (
                        descriptionTexts.first?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty ?? true
                    )
                )

                Button(saveButtonTitle, action: {
                    addSession()
                })
                .buttonStyle(.borderedProminent)
                .disabled(isAddDisabled)
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.addButton)
            }
        }
        .debugForm(String(describing: Self.self), position: .topLeading)
        .keyboardCloseButton(
            isVisible: isNameFocused || isDescriptionFocused,
            action: {
                KeyboardManager.hideKeyboard {
                    isNameFocused = false
                    isDescriptionFocused = false
                }
            }
        )
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // NewSessionFormView用：初期状態は常にMenu選択モード
            isCustomInputMode = false
        }
    }

    func addSession() {
        let trimmedName = name.trimmed
        let descriptions = descriptionTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            if sessionManager.sessionDatabase[trimmedName.lowercased()] != nil {
                // 既存セッションの場合：descriptionを1つずつ追加
                for description in descriptions where !description.isEmpty {
                    try sessionManager.addDescriptionToSession(
                        sessionName: trimmedName,
                        newDescription: description
                    )
                }
            } else {
                // 新規セッションの場合
                try sessionManager.addOrUpdateEntry(
                    originalKey: "",
                    sessionName: trimmedName,
                    descriptions: descriptions
                )
            }

            // 成功時のリセット
            name = ""
            descriptionTexts = [""]
            isCustomInputMode = false
            isNameFocused = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    func hideKeyboard() {
        KeyboardManager.hideKeyboard {
            isNameFocused = false
            isDescriptionFocused = false
        }
    }
}

#if DEBUG
struct NewSessionFormView_Previews: PreviewProvider {
    static var previews: some View {
        NewSessionFormView()
            .environmentObject(SessionManager())
    }
}
#endif
