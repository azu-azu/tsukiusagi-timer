//
//  TimerEditSectionBuilder.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/01.
//

import SwiftUI

/// TimerEditViewのセクションUI構築を担当するBuilder
struct TimerEditSectionBuilder {

    // MARK: - Constants

    private let topPadding: CGFloat = 8
    private let cardCornerRadius: CGFloat = 8
    private let labelCornerRadius: CGFloat = 6

    // MARK: - Section Builder

    /// セクションUIを構築するViewBuilder
    @ViewBuilder
    func section<Content: View>(
        title: String,
        showDone: Bool = false,
        doneAction: (() -> Void)? = nil,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 10) {
            HStack {
                Text(title)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .padding(.horizontal, 4)
                Spacer()
                if showDone, let action = doneAction {
                    Button("Done") {
                        action()
                    }
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
            }

            content()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, isCompact ? 8 : 16)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
    }

    // MARK: - Helper Methods

    /// セクション間のスペーシングを取得
    func sectionSpacing() -> CGFloat {
        return 24
    }
}
