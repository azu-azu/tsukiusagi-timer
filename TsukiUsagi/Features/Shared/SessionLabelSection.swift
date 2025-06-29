import SwiftUI

struct SessionLabelSection: View {
    @Binding var activity: String
    @Binding var detail: String
    @FocusState.Binding var isActivityFocused: Bool
    @FocusState.Binding var isDetailFocused: Bool
    let labelHeight: CGFloat
    let labelCornerRadius: CGFloat
    let inputHeight: CGFloat
    let onDone: (() -> Void)?

    private var isCustomActivity: Bool {
        !["Work", "Study", "Read"].contains(activity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                if isCustomActivity {
                    HStack(spacing: 8) {
                        TextField("Enter session name...", text: $activity)
                            .foregroundColor(.moonTextPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: labelHeight)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(labelCornerRadius)
                            .focused($isActivityFocused)
                            .frame(maxWidth: .infinity)

                        Button {
                            activity = "Work"
                            isActivityFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.moonTextMuted)
                                .font(.system(size: 16))
                        }
                    }
                } else {
                    Menu {
                        ForEach(["Work", "Study", "Read"], id: \.self) { label in
                            Button {
                                activity = label
                            } label: {
                                Text(label)
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

                if isActivityFocused || isDetailFocused {
                    Button("Done") {
                        isActivityFocused = false
                        isDetailFocused = false
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
                    .animation(.easeInOut(duration: 0.2), value: isActivityFocused || isDetailFocused)
                }
            }

            ZStack(alignment: .topLeading) {
                if detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Detail (optional)")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $detail)
                    .frame(height: inputHeight)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.05))
                    .focused($isDetailFocused)
            }
        }
    }
}