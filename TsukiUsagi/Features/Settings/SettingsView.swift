import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel

    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("detailLabel") private var detailLabel: String = ""

    private let topPadding: CGFloat = 8
    private let labelHeight: CGFloat = 28
    private let inputHeight: CGFloat = 42
    private let plusMinusSize: CGFloat = 12
    private let cardCornerRadius: CGFloat = 8
    private let labelCornerRadius: CGFloat = 6

    private var isCustomActivity: Bool {
        !["Work", "Study", "Read"].contains(activityLabel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moonBackground.ignoresSafeArea()
                StarView().allowsHitTesting(false)

                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .leading, spacing: geo.size.height * 0.05) { // 例：高さのY%ずつ間をあける
                            // ヘッダー
                            HStack {
                                Button("Close") { dismiss() }
                                    .foregroundColor(.moonTextSecondary)
                                Spacer()
                                Text("Settings")
                                    .font(.headline)
                                    .foregroundColor(.moonTextPrimary)
                                Spacer()
                                Button("Done") { dismiss() }
                                    .foregroundColor(.moonAccentBlue)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)

                            // Work Length
                            section(title: "Work Length", isCompact: true) {
                                customStepper(
                                    value: $workMinutes,
                                    range: 1...60,
                                    step: 5
                                )
                                .onChange(of: workMinutes) {
                                    timerVM.refreshAfterSettingsChange()
                                }
                            }

                            // Break Length
                            section(title: "Break Length", isCompact: true) {
                                customStepper(
                                    value: $breakMinutes,
                                    range: 1...30,
                                    step: 1
                                )
                            }

                            // Session Label
                            section(title: "Session Label") {
                                if isCustomActivity {
                                    HStack {
                                        TextField("Enter session name...", text: $activityLabel)
                                            .foregroundColor(.moonTextPrimary)
                                            .padding(.horizontal, 12)
                                            .frame(height: labelHeight)
                                            .frame(minHeight: labelHeight)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(labelCornerRadius)

                                        Button {
                                            activityLabel = "Work"
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.moonTextMuted)
                                        }
                                    }
                                } else {
                                    Menu {
                                        ForEach(["Work", "Study", "Read"], id: \.self) { label in
                                            Button {
                                                activityLabel = label
                                            } label: {
                                                Text(label)
                                            }
                                        }

                                        Divider()

                                        Button("Custom Input...") {
                                            activityLabel = ""
                                        }
                                    } label: {
                                        HStack {
                                            Text(activityLabel)
                                                .foregroundColor(.moonTextPrimary)
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.moonTextMuted)
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(height: labelHeight)
                                        .frame(minHeight: labelHeight)
                                        // .background(Color.white.opacity(0.05))
                                        .cornerRadius(labelCornerRadius)
                                    }
                                }

                                ZStack(alignment: .topLeading) {
                                    if detailLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text("Detail (optional)")
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                    }

                                    TextEditor(text: $detailLabel)
                                        .frame(height: inputHeight)
                                        .padding(8)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.white.opacity(0.05))
                                        // .overlay(
                                        //     RoundedRectangle(cornerRadius: labelCornerRadius)
                                        //         .stroke(Color.gray.opacity(0.4))
                                        // )
                                }
                            }

                            // Session Control
                            section(title: "Session Control") {
                                Button(role: .destructive) {
                                    timerVM.resetTimer()
                                    dismiss()
                                } label: {
                                    Label(timerVM.isWorkSession ? "Reset Timer (No Save)" : "Reset Timer (already saved)", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.red)

                                Button {
                                    timerVM.forceFinishWorkSession()
                                    dismiss()
                                } label: {
                                    Label("Stop", systemImage: "forward.end")
                                }
                                .disabled(!(timerVM.isRunning && timerVM.isWorkSession))
                                .tint(.blue)
                                .foregroundStyle((timerVM.isRunning && timerVM.isWorkSession) ? .blue : Color.gray.opacity(0.6))
                            }

                            // Logs
                            section(title: "Logs", isCompact: true) {
                                NavigationLink(destination: HistoryView().environmentObject(historyVM)) {
                                    HStack {
                                        Text("View History")
                                            .foregroundColor(.moonTextPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.moonTextMuted)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding(.top, topPadding)
                    .presentationDetents([.large])
                }
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.moonTextSecondary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(isCompact ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12) : EdgeInsets())
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color.moonCardBackground.opacity(0.15))
            )
        }
    }

    @ViewBuilder
    private func customStepper(value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1) -> some View {
        HStack {
            Text("\(value.wrappedValue) minutes")
                .foregroundColor(.moonTextPrimary)

            Spacer()

            HStack(spacing: 20) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= step
                    }
                } label: {
                    Image(systemName: "minus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: plusMinusSize, height: plusMinusSize)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += step
                    }
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: plusMinusSize, height: plusMinusSize)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
        }
    }
}
