import Foundation
import SwiftUI
import UIKit

// MARK: - Share Manager

class ShareManager: ObservableObject {

    /// Generate a share message for the current streak
    static func generateShareMessage(
        streakData: StreakData,
        currentLevel: UserLevel,
        achievements: [Achievement]
    ) -> String {
        let streak = streakData.totalContinuousStreak
        var message = "🔥 I'm on a \(streak)-day streak using the TsukiUsagi timer!"

        // Add achievements (first 1-2 unlocked)
        let unlockedAchievements = achievements.filter { $0.isUnlocked }.prefix(2)
        if !unlockedAchievements.isEmpty {
            let achievementTitles = unlockedAchievements.map { $0.title }.joined(separator: ", ")
            message += "\n🎖 Achievements: \(achievementTitles)"
        }

        // Add level info
        message += "\n⭐ Level \(currentLevel.level) - \(currentLevel.title)"

        // Add hashtags
        message += "\n\n#TimerStreak #TsukiUsagi"

        return message
    }

    /// Present the system share sheet
    static func presentShareSheet(message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first,
                let rootViewController = window.rootViewController else {
            print("❌ Could not find root view controller for share sheet")
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // Find the top-most view controller
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        topViewController.present(activityViewController, animated: true)
    }
}

// MARK: - SwiftUI ActivityView Wrapper

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - SwiftUI Share Sheet Modifier

struct ShareSheet: ViewModifier {
    @Binding var isPresented: Bool
    let activityItems: [Any]

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ActivityView(activityItems: activityItems)
                    .presentationDetents([.medium, .large])
            }
    }
}

extension View {
    func shareSheet(isPresented: Binding<Bool>, activityItems: [Any]) -> some View {
        modifier(ShareSheet(isPresented: isPresented, activityItems: activityItems))
    }
}