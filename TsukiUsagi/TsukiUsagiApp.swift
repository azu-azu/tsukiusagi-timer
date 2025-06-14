//
//  TsukiUsagiApp.swift
//  TsukiUsagi
//
//  Created by 松本和実 on 2025/06/11.
//

import SwiftUI

@main
struct TsukiUsagiApp: App {
    @StateObject private var historyVM = HistoryViewModel()
    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyVM)
        }
    }
}
