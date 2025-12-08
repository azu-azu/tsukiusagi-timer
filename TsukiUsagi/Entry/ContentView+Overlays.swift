import SwiftUI

// MARK: - Overlay Views

extension ContentView {
    @ViewBuilder
    func diamondStarsOverlay(showDiamondStars: Bool, onFinished: @escaping () -> Void) -> some View {
        if showDiamondStars {
            DiamondStarsOnceView(onFinished: onFinished)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func savedToast(show: Bool, safeAreaInsets: EdgeInsets) -> some View {
        if show {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Text("Saved")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            }
            .accessibilityIdentifier("savedToast")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignTokens.CosmosColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.WhiteColors.stroke)
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .padding(.bottom, safeAreaInsets.bottom + AppConstants.footerBarHeight + 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(3000)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func historyToast(show: Bool, message: String, safeAreaInsets: EdgeInsets) -> some View {
        if show {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Text(message)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            }
            .accessibilityIdentifier("historySaveToast")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignTokens.CosmosColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.WhiteColors.stroke)
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .padding(.bottom, safeAreaInsets.bottom + AppConstants.footerBarHeight + 64)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(3001)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func historySaveBanner(show: Bool, safeAreaInsets: EdgeInsets, onRetry: @escaping () -> Void) -> some View {
        if show {
            HStack(spacing: 12) {
                Image(systemName: "icloud.slash")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Couldn't save history")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Text("You can retry in background.")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary.opacity(0.8))
                }
                Spacer()
                Button("Retry", action: onRetry)
                    .accessibilityIdentifier("historySaveRetryButton")
                    .buttonStyle(.bordered)
            }
            .accessibilityIdentifier("historySaveBanner")
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DesignTokens.CosmosColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.WhiteColors.stroke)
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .padding(.bottom, safeAreaInsets.bottom + AppConstants.footerBarHeight + 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(3002)
        }
    }

    @ViewBuilder
    func silentCompleteChip(show: Bool, safeAreaInsets: EdgeInsets) -> some View {
        if show {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(DesignTokens.Fonts.symbolMedium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Text("Completed")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignTokens.CosmosColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.WhiteColors.stroke)
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .padding(.bottom, safeAreaInsets.bottom + AppConstants.footerBarHeight + 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(3000)
            .allowsHitTesting(false)
        }
    }
}
