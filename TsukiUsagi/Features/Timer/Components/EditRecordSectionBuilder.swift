//
//  EditRecordSectionBuilder.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import SwiftUI

/// EditRecordViewのセクションUI構築を担当するBuilder
struct EditRecordSectionBuilder {

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
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasTitle = !trimmedTitle.isEmpty
            let canShowHeader = hasTitle || (showDone && doneAction != nil)

            if canShowHeader {
                HStack {
                    if hasTitle {
                        Text(title)
                            .font(DesignTokens.Fonts.sectionTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                            .padding(.horizontal, 4)
                    }
                    Spacer()
                    if showDone, let action = doneAction {
                        Button("Done") {
                            action()
                        }
                        .font(DesignTokens.Fonts.sectionTitle)
                        .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                    }
                }
            }

            content()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, isCompact ? 8 : 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.SkyToneColors.cardGradient)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.SkyToneColors.cardBorderGradient, lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }

    // MARK: - Helper Methods

    /// セクション間のスペーシングを取得
    func sectionSpacing() -> CGFloat {
        return 24
    }
}
