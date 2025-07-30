import SwiftUI

struct DurationSectionView: View {
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    // workMinutesの選択肢: 1, 3, 5, 10, 15, ... 60
    private let workMinutesOptions: [Int] = [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))

    private let rowsSpacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
                // Work Duration
                DurationRowView(
                    title: "Work",
                    value: $workMinutes,
                    options: workMinutesOptions,
                    decrementAction: {
                        let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                        if currentIndex > 0 {
                            workMinutes = workMinutesOptions[currentIndex - 1]
                        }
                    },
                    incrementAction: {
                        let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                        if currentIndex < workMinutesOptions.count - 1 {
                            workMinutes = workMinutesOptions[currentIndex + 1]
                        }
                    }
                )

                // 区切り線
                Divider()

                // Break Duration
                DurationRowView(
                    title: "Break",
                    value: $breakMinutes,
                    options: nil,
                    decrementAction: {
                        if breakMinutes > 1 { breakMinutes -= 1 }
                    },
                    incrementAction: {
                        if breakMinutes < 30 { breakMinutes += 1 }
                    }
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.CosmosColors.cardBackground)
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
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .frame(width: plusMinusButtonSize, height: plusMinusButtonSize)
                .background(DesignTokens.CosmosColors.cardBackground)
                .clipShape(Circle())

                Button(action: incrementAction) {
                    Image(systemName: "plus")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .frame(width: plusMinusButtonSize, height: plusMinusButtonSize)
                .background(DesignTokens.CosmosColors.cardBackground)
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
