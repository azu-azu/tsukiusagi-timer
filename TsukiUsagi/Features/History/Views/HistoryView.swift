import SwiftUI
import Foundation

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            HistoryContainerView()
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarRole(.navigationStack)
                .navigationBackButton {
                    // サイドメニューを開くリクエストを送る
                    sessionManager.requestSideMenuOnDismiss()
                    dismiss()
                }
        }
        .onAppear {
            // NavigationStackのbackスワイプを無効化
            disableBackSwipeGesture()
        }
        .onDisappear {
            // History画面を離れる際は何もしない（DailyTimelineViewで制御）
        }
    }

    private func disableBackSwipeGesture() {
        DispatchQueue.main.async {
            // NavigationStackのUINavigationControllerを取得してbackスワイプを無効化
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                findNavigationController(in: window.rootViewController)?
                    .interactivePopGestureRecognizer?
                    .isEnabled = false
            }
        }
    }

    private func enableBackSwipeGesture() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                findNavigationController(in: window.rootViewController)?
                    .interactivePopGestureRecognizer?
                    .isEnabled = true
            }
        }
    }

    private func findNavigationController(in viewController: UIViewController?) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }

        for child in viewController?.children ?? [] {
            if let found = findNavigationController(in: child) {
                return found
            }
        }

        return nil
    }
}
