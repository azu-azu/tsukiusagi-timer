import SwiftUI

struct LevelView: View {
    let level: UserLevel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("⭐")
                    .font(.title2)
                Text("Level \\(level.level) - \\(level.title)")
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\\(level.currentXP) / \\(level.requiredXP) XP")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    Spacer()
                    Text("\\(Int(level.progress * 100))%")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(.pink)
                }

                ProgressView(value: level.progress)
                    .progressViewStyle(.linear)
                    .tint(.pink)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct AchievementsView: View {
    let achievements: [Achievement]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementCardView(achievement: achievement)
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        }
    }
}

struct AchievementCardView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Text(achievement.iconName)
                .font(.system(size: 40))
                .opacity(achievement.isUnlocked ? 1.0 : 0.3)

            // Title
            Text(achievement.title)
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(
                    achievement.isUnlocked
                        ? DesignTokens.MoonColors.textPrimary
                        : DesignTokens.MoonColors.textSecondary
                )
                .multilineTextAlignment(.center)

            // Description
            Text(achievement.description)
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            // Unlock date
            if achievement.isUnlocked {
                Text("Unlocked \\(formatDate(achievement.unlockedAt!))")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(.pink)
            } else {
                Text("Locked")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    achievement.isUnlocked
                        ? DesignTokens.CosmosColors.cardBackground
                        : DesignTokens.CosmosColors.cardBackground.opacity(0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(achievement.isUnlocked ? Color.pink.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: achievement.isUnlocked)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Integration with StreakView

struct AchievementsSectionView: View {
    @ObservedObject var streakManager: StreakManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🏆")
                    .font(.title3)
                Text("Achievements")
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Spacer()

                Button(
                    action: {
                        streakManager.shareStreak()
                    },
                    label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                )

                NavigationLink(destination: AchievementsView(achievements: streakManager.achievements)) {
                    Text("View All")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(.pink)
                }
            }

            // Show unlocked achievements in a horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(streakManager.achievements.filter { $0.isUnlocked }) { achievement in
                        VStack(spacing: 4) {
                            Text(achievement.iconName)
                                .font(.system(size: 24))
                            Text(achievement.title)
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignTokens.CosmosColors.cardBackground)
                        )
                        .frame(width: 60)
                    }

                    // Add achievement count if no unlocked achievements
                    if streakManager.achievements.filter({ $0.isUnlocked }).isEmpty {
                        VStack(spacing: 4) {
                            Text("🎯")
                                .font(.system(size: 24))
                                .opacity(0.3)
                            Text("Start your first session!")
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(8)
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleAchievements = [
            Achievement(
                type: .firstDay,
                title: "First Timer",
                description: "Complete your first timer session",
                iconName: "🎯",
                unlockedAt: Date()
            ),
            Achievement(
                type: .weekWarrior,
                title: "Week Warrior",
                description: "Use the timer all 7 days in a week",
                iconName: "🗓️",
                unlockedAt: nil
            ),
            Achievement(
                type: .centurion,
                title: "Centurion",
                description: "Achieve a 100-day streak",
                iconName: "💯",
                unlockedAt: nil
            )
        ]

        Group {
            // Level View Preview
            LevelView(level: UserLevel.calculateLevel(from: 250))
                .padding()
                .previewDisplayName("Level View - Level 2")

            // Achievements View Preview
            AchievementsView(achievements: sampleAchievements)
                .previewDisplayName("Achievements View")

            // High Level Preview
            LevelView(level: UserLevel.calculateLevel(from: 5000))
                .padding()
                .previewDisplayName("Level View - Level 8 Expert")
        }
        .background(DesignTokens.CosmosColors.background)
    }
}
#endif
