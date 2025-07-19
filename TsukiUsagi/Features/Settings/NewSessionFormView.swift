import SwiftUI

struct NewSessionFormView: View {
    @EnvironmentObject var sessionManager: SessionManagerV2
    @State private var name: String = ""
    @State private var subtitleTexts: [String] = [""]
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @State private var errorTitle: String = "Error"

        var isAddDisabled: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitles = subtitleTexts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        // Session Nameが空の場合は無効
        if trimmedName.isEmpty { return true }

        // 文字数超過
        if trimmedName.count > SessionManagerV2.maxNameLength { return true }
        if subtitles.contains(where: { $0.count > SessionManagerV2.maxSubtitleLength }) { return true }
        // 最大数超過
        if subtitles.count > SessionManagerV2.maxSubtitleCount { return true }
        // セッション数超過（空文字でない場合のみチェック）
        if !trimmedName.isEmpty && !sessionManager.defaultSessionNames.contains(trimmedName) && sessionManager.customEntries.count >= SessionManagerV2.maxSessionCount && sessionManager.sessionDatabase[trimmedName.lowercased()] == nil {
            return true
        }
        // 重複禁止（空文字でない場合のみチェック）
        if !trimmedName.isEmpty, let existing = sessionManager.sessionDatabase[trimmedName.lowercased()], !sessionManager.defaultSessionNames.contains(trimmedName) {
            if !existing.isDefault { return true }
        }
        return false
    }

    var saveButtonTitle: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // 既存のセッション名が選択されている場合
        if !trimmedName.isEmpty && sessionManager.allEntries.map({ $0.sessionName }).contains(trimmedName) {
            return "Update \"\(trimmedName)\""
        }

        // 新規セッション作成の場合
        return "Create Session"
    }

    var body: some View {
        RoundedCard(backgroundColor: DesignTokens.Colors.moonCardBG) {
            VStack(alignment: .leading, spacing: 8) {
                // Text("New Session Name")
                //     .font(DesignTokens.Fonts.labelBold)
                //     .foregroundColor(DesignTokens.Colors.moonTextPrimary)

                // Menu形式でセッション選択（SessionLabelSectionと同じ）
                if !name.isEmpty && !sessionManager.allEntries.map({ $0.sessionName }).contains(name) {
                    // カスタム入力モード（既存セッションにない場合のみ）
                    HStack(spacing: 8) {
                        ZStack(alignment: .topLeading) {
                            Text("Enter session name...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)

                            TextField("", text: $name)
                                .foregroundColor(.moonTextPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 28)
                                .focused($isNameFocused)
                                .onChange(of: isNameFocused) { _, newValue in
                                    if newValue {
                                        HapticManager.shared.heavyImpact()
                                    }
                                }
                        }
                        .frame(height: 28)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)

                        Button {
                            name = ""
                            isNameFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.moonTextMuted)
                                .font(DesignTokens.Fonts.label)
                        }
                    }
                } else {
                    // Menu選択モード（デフォルト）
                    Menu {
                        // デフォルトセッション
                        ForEach(sessionManager.defaultEntries) { entry in
                            Button {
                                name = entry.sessionName
                            } label: {
                                Text(entry.sessionName)
                            }
                        }
                        Divider()
                        // カスタムセッション
                        ForEach(sessionManager.customEntries) { entry in
                            Button {
                                name = entry.sessionName
                            } label: {
                                Text(entry.sessionName)
                            }
                        }
                        Divider()
                        Button("Custom Input...") {
                            name = ""
                            isNameFocused = true
                        }
                    } label: {
                        HStack {
                            Text(name.isEmpty ? "Select Session" : name)
                                .foregroundColor(name.isEmpty ? .secondary : .moonTextPrimary)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.moonTextMuted)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .cornerRadius(6)
                    }
                }

                ForEach(subtitleTexts.indices, id: \.self) { idx in
                    HStack {
                        TextField(idx == 0 ? "Subtitle (optional)" : "Subtitle \(idx + 1)", text: Binding(
                            get: { subtitleTexts[safe: idx] ?? "" },
                            set: { newValue in
                                if idx < subtitleTexts.count {
                                    subtitleTexts[idx] = newValue
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isSubtitleFocused)
                        .submitLabel(.done)
                        .onSubmit { hideKeyboard() }
                        .accessibilityIdentifier(AccessibilityIDs.SessionManager.subtitleField)
                        .onChange(of: isSubtitleFocused) { _, newValue in
                            if newValue {
                                HapticManager.shared.heavyImpact()
                            }
                        }

                        // 2個目以降にのみマイナスボタンを表示、1個目はスペース確保
                        if idx > 0 {
                            Button(action: { subtitleTexts.remove(at: idx) }, label: {
                                Image(systemName: "minus.circle")
                            })
                            .buttonStyle(.plain)
                        } else {
                            // 1個目は透明なスペーサーで横幅を統一
                            Color.clear
                                .frame(width: 24, height: 24)
                        }
                    }
                }

                Button(action: { subtitleTexts.append("") }, label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Add Subtitle")
                    }
                })
                .font(DesignTokens.Fonts.caption)
                .buttonStyle(.plain)
                .disabled(name.isEmpty || (subtitleTexts.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true))

                Button(saveButtonTitle, action: {
                    addSession()
                })
                .buttonStyle(.borderedProminent)
                .disabled(isAddDisabled)
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.addButton)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }

    private func addSession() {
        let trimmedName = name.trimmed
        let subtitles = subtitleTexts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        do {
            try sessionManager.addOrUpdateEntry(sessionName: trimmedName, subtitles: subtitles)
            name = ""
            subtitleTexts = [""]
            isNameFocused = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func hideKeyboard() {
        isNameFocused = false
        isSubtitleFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

#if DEBUG
struct NewSessionFormView_Previews: PreviewProvider {
    static var previews: some View {
        NewSessionFormView()
            .environmentObject(SessionManagerV2())
    }
}
#endif
