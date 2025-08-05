import SwiftUI

struct DurationSectionView: View {
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @EnvironmentObject private var timerVM: TimerViewModel

    private let rowsSpacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
                // Work Duration
                DurationRowView(
                    title: "Work",
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

                // 区切り線
                Divider()

                // Break Duration
                DurationRowView(
                    title: "Break",
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.BlackColors.surface)
        )
    }

}

// MARK: - Duration Row Component

struct DurationRowView: View {
    let title: String
    @Binding var value: Int
    let options: [Int]? // Work用のオプション配列（Break用はnil）
    let decrementAction: () -> Void
    let incrementAction: () -> Void

    let leftBlockMinWidth: CGFloat = 100
    let centerBlockWidth: CGFloat = 24
    let plusMinusButtonSize: CGFloat = 28

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 左ブロック
            Text(title)
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .frame(minWidth: leftBlockMinWidth, alignment: .leading)
                .lineLimit(1)
                .layoutPriority(1)

            // 中央ブロック
            HStack(alignment: .center, spacing: 4) {
                Text("\(value)")
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .frame(width: centerBlockWidth, alignment: .trailing)

                Text("min")
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // 右ブロック
            HStack(alignment: .center, spacing: 12) {
                Button(action: decrementAction) {
                    Image(systemName: "minus")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(.white)
                }
                .frame(width: plusMinusButtonSize, height: plusMinusButtonSize)
                .background(DesignTokens.MoonColors.accentOrange)
                .clipShape(Circle())

                Button(action: incrementAction) {
                    Image(systemName: "plus")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(.white)
                }
                .frame(width: plusMinusButtonSize, height: plusMinusButtonSize)
                .background(DesignTokens.MoonColors.accentGreen)
                .clipShape(Circle())
            }
        }
    }
}

#if DEBUG
struct DurationSectionView_Previews: PreviewProvider {
    static var previews: some View {
        DurationSectionView()
            .padding()
            .background(DesignTokens.CosmosColors.background)
    }
}
#endif
