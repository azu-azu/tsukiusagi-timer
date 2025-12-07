//
//  EditRecordSectionBuilder.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import SwiftUI

/// EditRecordViewのセクションUI構築を担当するBuilder
struct EditRecordSectionBuilder {

    /// セクションUIを構築するViewBuilder
    /// - Parameters:
    ///   - isHighlight: trueの場合、TsukiSoundのSoundカードと同じ明るい背景（白15%）を使用
    @ViewBuilder
    func section<Content: View>(
        title: String,
        isHighlight: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasTitle = !trimmedTitle.isEmpty

            if hasTitle {
                Text(title)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
            }

            content()
        }
        .padding(16)
        .background(
            ZStack {
                if isHighlight {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignTokens.SkyToneColors.cardGradient)
                }
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
    }
}
