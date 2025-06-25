import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel

    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("detailLabel") private var detailLabel: String = ""

    @FocusState private var isActivityFocused: Bool
    @FocusState private var isDetailFocused: Bool

    // Work minutes options: 1, 3, 5, 10, 15, ... 60
    private let workMinutesOptions: [Int] = [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))

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
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
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
                        customStepperForWorkMinutes()
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
                        HStack(alignment: .top) {
                            if isCustomActivity {
                                TextField("Enter session name...", text: $activityLabel)
                                    .foregroundColor(.moonTextPrimary)
                                    .padding(.horizontal, 12)
                                    .frame(height: labelHeight)
                                    .frame(minHeight: labelHeight)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(labelCornerRadius)
                                    .focused($isActivityFocused)
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
                                    .cornerRadius(labelCornerRadius)
                                }
                            }
                            Spacer(minLength: 8)
                            if isActivityFocused || isDetailFocused {
                                Button("Done") {
                                    isActivityFocused = false
                                    isDetailFocused = false
                                }
                                .foregroundColor(.moonTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.15))
                                )
                                .transition(.opacity)
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
                                .focused($isDetailFocused)
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
            .background(
                ZStack {
                    Color.moonBackground.ignoresSafeArea()
                    StaticStarsView().allowsHitTesting(false)
                    FlowingStarsView(mode: .diagonal(angle: 3 * .pi / 4))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .padding(.top, topPadding)
            .presentationDetents([.large])
            .modifier(DismissKeyboardOnTap())
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isActivityFocused = false
                    isDetailFocused = false
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

    // MARK: - Custom Stepper for Work Minutes
    @ViewBuilder
    private func customStepperForWorkMinutes() -> some View {
        // 現在値のインデックスを取得
        let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
        HStack {
            Text("\(workMinutes) minutes")
                .foregroundColor(.moonTextPrimary)

            Spacer()

            HStack(spacing: 20) {
                Button {
                    if currentIndex > 0 {
                        workMinutes = workMinutesOptions[currentIndex - 1]
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
                    if currentIndex < workMinutesOptions.count - 1 {
                        workMinutes = workMinutesOptions[currentIndex + 1]
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
        .onChange(of: workMinutes) {
            timerVM.refreshAfterSettingsChange()
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}
