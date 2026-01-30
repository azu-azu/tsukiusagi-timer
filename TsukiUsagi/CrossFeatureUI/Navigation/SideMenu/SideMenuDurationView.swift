import SwiftUI

struct SideMenuDurationView: View {
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("taskLabel") private var taskLabel: String = ""

    @EnvironmentObject private var timerVM: TimerViewModel
    @Binding var isPresented: Bool

    private let blockHorizontalPadding: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Work Duration
            SideMenuDurationRowView(
                title: "Work Duration",
                value: $workMinutes,
                options: DurationConstants.workMinutesOptions,
                decrementAction: DurationActions.makeDecrementWorkAction(
                    workMinutes: $workMinutes,
                    options: DurationConstants.workMinutesOptions,
                    timerVM: timerVM
                ),
                incrementAction: DurationActions.makeIncrementWorkAction(
                    workMinutes: $workMinutes,
                    options: DurationConstants.workMinutesOptions,
                    timerVM: timerVM
                )
            )

            // Break Duration
            SideMenuDurationRowView(
                title: "Break Duration",
                value: $breakMinutes,
                options: nil,
                decrementAction: DurationActions.makeDecrementBreakAction(
                    breakMinutes: $breakMinutes,
                    timerVM: timerVM
                ),
                incrementAction: DurationActions.makeIncrementBreakAction(
                    breakMinutes: $breakMinutes,
                    timerVM: timerVM
                )
            )

            // Session種類表示
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("Session")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .frame(minWidth: 50, alignment: .leading)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(activityLabel.withSessionEmoji)
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if !taskLabel.isEmpty {
                            Text(taskLabel.withTaskEmoji)
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.MoonColors.textMuted)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.trailing, blockHorizontalPadding)

                // 鉛筆マークでの編集リンク
                HStack {
                    Spacer()
                    NavigationLink(destination: SessionConfigView()) {
                        PencilIcon(size: .medium)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Session Control セクション
            Divider()
                .background(DesignTokens.MoonColors.surfaceSecondary)
                .padding(.vertical, 8)

            sessionControlSection()
        }
        .padding(.vertical, 4)
        .onChange(of: workMinutes) { _, _ in
            // 初回起動直後を含め、変更時に即時反映
            timerVM.refreshAfterSettingsChange()
        }
    }

    // MARK: - Session Control Section

    @ViewBuilder
    private func sessionControlSection() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            resetButton()
            stopButton()
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func resetButton() -> some View {
        if timerVM.canForceFinish {
            Button {
                Task { @MainActor in
                    await timerVM.resetTimer(to: timerVM.workMinutes * 60)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                    Text(timerVM.isWorkSession
                        ? "Reset Timer (No Save)"
                        : "Reset Timer (already saved)"
                    )
                    .font(DesignTokens.Fonts.label)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tint(DesignTokens.MoonColors.errorBackground)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                Text(timerVM.isWorkSession
                    ? "Reset Timer (No Save)"
                    : "Reset Timer (already saved)"
                )
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func stopButton() -> some View {
        if timerVM.canStopNow {
            Button {
                Task { @MainActor in
                    await timerVM.forceFinish()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "forward.end")
                    Text("Stop (Save)")
                        .font(DesignTokens.Fonts.label)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tint(DesignTokens.MoonColors.accentBlue)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "forward.end")
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                Text("Stop (Save)")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Side Menu Duration Row Component

struct SideMenuDurationRowView: View {
    let title: String
    @Binding var value: Int
    let options: [Int]? // Work用のオプション配列（Break用はnil）
    let decrementAction: () -> Void
    let incrementAction: () -> Void

    private let minWidth: CGFloat = 50
    private let buttonSize: CGFloat = 24
    private let buttonSpacing: CGFloat = 8
    private let blockHorizontalPadding: CGFloat = 12

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .frame(minWidth: minWidth, alignment: .leading)

            Spacer()

            // 時間の+/-ボタンと値表示（統一デザイン）
            HStack(spacing: buttonSpacing) {
                PlusMinusButton(
                    minus: decrementAction
                )
                .frame(width: buttonSize, height: buttonSize)

                Text("\(value)")
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .frame(width: buttonSize, alignment: .center)

                PlusMinusButton(
                    plus: incrementAction
                )
                .frame(width: buttonSize, height: buttonSize)
            }
            .padding(.horizontal, blockHorizontalPadding)
            .padding(.vertical, 6)

            // ボタン部分のカード背景（デザイントークン）
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(DesignTokens.CosmosColors.cardBackgroundAlt)
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper Methods
    // durationButton removed - now using PlusMinusButton component
}

#if DEBUG
#Preview {
    SideMenuDurationView(isPresented: .constant(true))
        .environmentObject(PreviewData.MockServices.makeTimerViewModel())
        .padding()
        .background(DesignTokens.CosmosColors.background)
}
#endif
