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
    @State private var isCustomInputMode: Bool = false

    private let inputHeight: CGFloat = 28
    private let labelHeight: CGFloat = 28
    private let labelCornerRadius: CGFloat = 6

    private var isCustomActivity: Bool {
        return isCustomInputMode
    }

    var isAddDisabled: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptions = descriptionTexts.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if trimmedName.isEmpty { return true }
        if descriptions.isEmpty { return true }
        if trimmedName.count > SessionManager.maxNameLength { return true }
        if descriptions.contains(where: { $0.count > SessionManager.maxDescriptionLength }) {
            return true
        }
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
        if !trimmedName.isEmpty &&
            sessionManager.allEntries.map({ $0.sessionName }).contains(trimmedName) {
            return "Update \"\(trimmedName)\""
        }
        return "Create Session"
    }

    var body: some View {
        RoundedCard(backgroundColor: DesignTokens.CosmosColors.cardBackground) {
            VStack(alignment: .leading, spacing: 12) {
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
                                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
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
                                    .foregroundColor(DesignTokens.MoonColors.textMuted)
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
                                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
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
                                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
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
                            .foregroundColor(DesignTokens.MoonColors.textPrimary)
                            } label: {
                                HStack {
                                Text(name.isEmpty ? "Select Session" : name)
                                    .foregroundColor(name.isEmpty ? DesignTokens.MoonColors.textSecondary : .moonTextPrimary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: labelHeight)
                            .cornerRadius(labelCornerRadius)
                        }
                    }

                    Spacer(minLength: 8)
                }

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
                                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                                }
                            )
                            .buttonStyle(.plain)
                        } else {
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
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
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
                for description in descriptions where !description.isEmpty {
                    try sessionManager.addDescriptionToSession(
                        sessionName: trimmedName,
                        newDescription: description
                    )
                }
            } else {
                try sessionManager.addOrUpdateEntry(
                    originalKey: "",
                    sessionName: trimmedName,
                    descriptions: descriptions
                )
            }

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
