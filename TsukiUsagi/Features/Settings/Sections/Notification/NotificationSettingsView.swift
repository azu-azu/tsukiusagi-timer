import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    @AppStorage("time_sensitive_notifications_enabled") private var timeSensitiveEnabled = false
    @State private var showingPermissionAlert = false
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time-Sensitive通知の設定
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Time-Sensitive Notifications")
                        .font(DesignTokens.Fonts.labelBold)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $timeSensitiveEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: DesignTokens.MoonColors.accentBlue))
                }
                
                Text("Receive notifications even when Focus mode is active")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DesignTokens.MoonColors.surfaceSecondary)
            .cornerRadius(12)
            
            // 通知許可状態の表示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Notification Permission Status")
                        .font(DesignTokens.Fonts.labelBold)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    
                    Spacer()
                    
                    Text(permissionStatusText)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(permissionStatusColor)
                }
                
                if permissionStatus != .authorized {
                    Button("Open Settings") {
                        openAppSettings()
                    }
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DesignTokens.MoonColors.surfaceSecondary)
            .cornerRadius(12)
        }
        .onAppear {
            checkPermissionStatus()
        }
        .onChange(of: timeSensitiveEnabled) { oldValue, newValue in
            if newValue {
                checkPermissionStatus()
            }
        }
    }
    
    private var permissionStatusText: String {
        switch permissionStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var permissionStatusColor: Color {
        switch permissionStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional, .ephemeral:
            return .blue
        @unknown default:
            return .gray
        }
    }
    
    private func checkPermissionStatus() {
        Task {
            let status = await NotificationPermissionManager.shared.getCurrentPermissionStatus()
            await MainActor.run {
                self.permissionStatus = status
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    NotificationSettingsView()
        .padding()
        .background(DesignTokens.CosmosColors.background)
}