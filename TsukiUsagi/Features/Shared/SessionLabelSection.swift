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

    private var isCustomActivity: Bool {
        !sessionManager.allSessions.map { $0.name }.contains(activity)
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
                            activity = sessionManager.fixedSessions.first?.name ?? "Work"
                            isActivityFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.moonTextMuted)
                                .font(.system(size: 16))
                        }
                    }
                } else {
                    Menu {
                        // 固定3種
                        ForEach(sessionManager.fixedSessions) { item in
                            Button {
                                activity = item.name
                            } label: {
                                Text(item.name)
                            }
                        }
                        Divider()
                        // カスタムSession Name
                        ForEach(sessionManager.customSessions) { item in
                            Button {
                                activity = item.name
                            } label: {
                                Text(item.name)
                            }
                        }
                        Divider()
                        Button("Custom Input...") {
                            activity = ""
                            isActivityFocused = true
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
                    .focused($isSubtitleFocused)
            }
        }
    }
}