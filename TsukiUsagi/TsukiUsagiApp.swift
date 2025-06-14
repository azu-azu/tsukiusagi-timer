//
//  TsukiUsagiApp.swift
//  TsukiUsagi
//
//  Created by 松本和実 on 2025/06/11.
//

import SwiftUI

@main
struct TsukiUsagiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var historyVM = HistoryViewModel()
    init() {
        NotificationManager.shared.requestAuthorization(completion: { success in
            if success {
                print("Notification authorization granted.")
            } else {
                print("Notification authorization denied.")
            }
        })
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyVM)
        }
    }
}
