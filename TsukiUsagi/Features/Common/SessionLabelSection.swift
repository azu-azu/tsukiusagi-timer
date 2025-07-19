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

    private var isCustomActivity: Bool {
        // 明示的なCustom Inputモードまたは空文字の場合
        return isCustomInputMode || activity.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                                .onChange(of: isActivityFocused) { _, newValue in
                                    if newValue {
                                        HapticManager.shared.heavyImpact()
                                    }
                                }
                        }
                        .frame(height: labelHeight)
                        .background(
                            (showEmptyError && activity.isEmpty) ?
                                Color.moonErrorBackground.opacity(0.3) :
                                Color.white.opacity(0.05)
                        )
                        .cornerRadius(labelCornerRadius)
                        .frame(maxWidth: .infinity)

                        Button {
                            activity = sessionManager.defaultEntries.first?.sessionName ?? "Work"
                            isActivityFocused = false
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
                                isCustomInputMode = false
                            } label: {
                                Text(entry.sessionName)
                            }
                        }
                        Divider()
                        // カスタムセッション
                        ForEach(sessionManager.customEntries) { entry in
                            Button {
                                activity = entry.sessionName
                                isCustomInputMode = false
                            } label: {
                                Text(entry.sessionName)
                            }
                        }
                        Divider()
                        Button("Custom Input...") {
                            activity = ""
                            isCustomInputMode = true
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

                Spacer(minLength: 8)

                if isActivityFocused || isSubtitleFocused {
                    Button("Done") {
                        isActivityFocused = false
                        isSubtitleFocused = false
                        onDone?()
                    }
                    .foregroundColor(.moonTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isActivityFocused || isSubtitleFocused)
                }
            }

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
                        if newValue {
                            HapticManager.shared.heavyImpact()
                        }
                    }
            }
        }
        .onAppear {
            // 初期状態で既存セッションが選択されている場合はCustom Inputモードを無効化
            let allSessionNames = sessionManager.allEntries.map { $0.sessionName }
            if allSessionNames.contains(activity) {
                isCustomInputMode = false
            }
        }
    }
}
