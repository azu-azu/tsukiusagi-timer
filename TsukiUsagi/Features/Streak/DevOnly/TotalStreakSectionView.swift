import SwiftUI

struct TotalStreakSectionView: View {
    @ObservedObject var streakManager: StreakManager

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🔥")
                    .font(DesignTokens.Fonts.title)
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
                            .font(DesignTokens.Fonts.sectionTitle)
                            .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    }
                )
            }

            HStack {
                Text("[\(streakManager.streakData.totalContinuousStreak)]")
                    .font(DesignTokens.Fonts.title)
                    .foregroundColor(DesignTokens.MoonColors.accentBlue)
                Spacer()
            }
        }
    }
}
