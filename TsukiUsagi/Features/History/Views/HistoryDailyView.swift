import SwiftUI

struct HistoryDailyView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        CalendarHistoryView()
            .background(DesignTokens.CosmosColors.background)
    }
}
