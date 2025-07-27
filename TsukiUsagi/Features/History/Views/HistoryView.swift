import SwiftUI
import Foundation

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        CalendarHistoryView()
    }
}