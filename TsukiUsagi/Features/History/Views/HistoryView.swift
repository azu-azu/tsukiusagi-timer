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
    }
}
