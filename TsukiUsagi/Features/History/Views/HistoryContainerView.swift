import SwiftUI

/// Container view for History with Daily/Monthly tabs
struct HistoryContainerView: View {
    enum Tab: Int, CaseIterable, Identifiable { case daily, monthly; var id: Int { rawValue } }

    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    @State private var selectedTab: Tab = .daily

    var body: some View {
        VStack(spacing: 6) {
            // Segmented control
            Picker("History Mode", selection: $selectedTab) {
                Text("Daily").tag(Tab.daily)
                Text("Monthly").tag(Tab.monthly)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            // Content
            Group {
                switch selectedTab {
                case .daily:
                    HistoryDailyView()
                case .monthly:
                    HistoryMonthlyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
    }
}
