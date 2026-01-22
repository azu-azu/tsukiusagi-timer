import SwiftUI
import UserNotifications

struct SmartNotificationToggleView: View {
    @ObservedObject var streakManager: StreakManager
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🤖")
                    .font(DesignTokens.Fonts.sectionTitle)
                Text("Smart Reminders")
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Spacer()

                Toggle("", isOn: Binding(
                    get: { streakManager.isSmartNotificationEnabled },
                    set: { enabled in
                        if enabled {
                            Task {
                                await enableNotifications()
                            }
                        } else {
                            streakManager.disableSmartNotifications()
                        }
                    }
                ))
                .tint(DesignTokens.MoonColors.accentBlue)
            }

            // Status and description
            VStack(alignment: .leading, spacing: 4) {
                if streakManager.isSmartNotificationEnabled {
                    Text("✅ AI-powered reminders active")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.statusSuccess)

                    Text("We'll remind you at your optimal focus time based on your usage patterns.")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                } else {
                    Text("💡 Get personalized reminders")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)

                    Text("Enable to receive smart notifications at your most productive times.")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }

                // Show usage pattern insights if enabled
                if streakManager.isSmartNotificationEnabled {
                    UsagePatternInsightsView(pattern: streakManager.getCurrentUsagePattern())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignTokens.MoonColors.accentBlue.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            checkNotificationStatus()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive smart reminders.")
        }
    }

    private func enableNotifications() async {
        let manager = SmartNotificationManager.shared
        let hasPermission = await manager.requestNotificationPermissions()

        await MainActor.run {
            if hasPermission {
                streakManager.enableSmartNotifications()
            } else {
                showingPermissionAlert = true
            }
            checkNotificationStatus()
        }
    }

    private func checkNotificationStatus() {
        Task {
            let manager = SmartNotificationManager.shared
            let status = await manager.checkNotificationStatus()
            await MainActor.run {
                notificationStatus = status
            }
        }
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct UsagePatternInsightsView: View {
    let pattern: UsagePattern

    var body: some View {
        if !pattern.isNewUser {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("📊 Your Pattern:")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    Spacer()
                }

                if pattern.weekdayConsistency > 0.6 {
                    Text("Strong weekday consistency (\(Int(pattern.weekdayConsistency * 100))%)")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }

                if pattern.totalUsageDays > 7 {
                    Text("\(pattern.totalUsageDays) total focus days")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }
            }
            .padding(.top, 4)
        }
    }
}

#Preview("Smart Notification Toggle") {
    SmartNotificationToggleView(streakManager: StreakManager())
        .padding()
        .background(DesignTokens.CosmosColors.background)
}
