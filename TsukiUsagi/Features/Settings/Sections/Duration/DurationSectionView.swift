import SwiftUI

struct DurationSectionView: View {
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    // workMinutesの選択肢: 1, 3, 5, 10, 15, ... 60
    private let workMinutesOptions: [Int] = [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            // セクションタイトル
            Text("DURATION")
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                // Work Duration
                workDurationRow()

                // 区切り線
                Divider()

                // Break Duration
                breakDurationRow()
            }
            .padding(.all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.CosmosColors.cardBackground)
            )
        }
    }

    @ViewBuilder
    private func workDurationRow() -> some View {
        HStack(spacing: 0) {
            // 左ブロック
            Text("Work")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .frame(minWidth: 100, alignment: .leading)
                .lineLimit(1)
                .layoutPriority(1)

            // 中央ブロック
            HStack(spacing: 4) {
                Text(String(format: "%d", workMinutes))
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .frame(width: 24, alignment: .trailing)

                Text("min")
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // 右ブロック
            HStack(spacing: 12) {
                Button {
                    let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                    if currentIndex > 0 {
                        workMinutes = workMinutesOptions[currentIndex - 1]
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .frame(width: 28, height: 28)
                .background(DesignTokens.CosmosColors.cardBackground)
                .clipShape(Circle())

                Button {
                    let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                    if currentIndex < workMinutesOptions.count - 1 {
                        workMinutes = workMinutesOptions[currentIndex + 1]
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .frame(width: 28, height: 28)
                .background(DesignTokens.CosmosColors.cardBackground)
                .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func breakDurationRow() -> some View {
        HStack(spacing: 0) {
            // 左ブロック
            Text("Break")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .frame(minWidth: 100, alignment: .leading)
                .lineLimit(1)
                .layoutPriority(1)

            // 中央ブロック
            HStack(spacing: 4) {
                Text(String(format: "%d", breakMinutes))
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .frame(width: 24, alignment: .trailing) //固定幅で右寄せ

                Text("min")
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // 右ブロック
            HStack(spacing: 12) {
                Button {
                    if breakMinutes > 1 { breakMinutes -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .frame(width: 28, height: 28)
                .background(DesignTokens.CosmosColors.cardBackground)
                .clipShape(Circle())

                Button {
                    if breakMinutes < 30 { breakMinutes += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .frame(width: 28, height: 28)
                .background(DesignTokens.CosmosColors.cardBackground)
                .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
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
