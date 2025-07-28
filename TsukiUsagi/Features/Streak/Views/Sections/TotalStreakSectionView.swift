import SwiftUI

struct TotalStreakSectionView: View {
    @ObservedObject var streakManager: StreakManager

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🔥")
                    .font(.title2)
                Text("Your streak")
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Spacer()

                Button(
                    action: {
                        streakManager.shareStreak()
                    },
                    label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.pink)
                    }
                )
            }

            HStack {
                Text("[\(streakManager.streakData.totalContinuousStreak)]")
                    .font(DesignTokens.Fonts.title)
                    .foregroundColor(.pink)
                Spacer()
            }
        }
    }
}
