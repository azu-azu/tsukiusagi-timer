//
//  TsukiSoundCardStyle.swift
//  TsukiUsagi
//
//  Shared card style modifier for TsukiSound-style cards
//

import SwiftUI

/// TsukiSound風カードスタイルのViewModifier
struct TsukiSoundCardStyle: ViewModifier {
    let isHighlight: Bool
    let cornerRadius: CGFloat
    let padding: CGFloat

    init(isHighlight: Bool = false, cornerRadius: CGFloat = 12, padding: CGFloat = 16) {
        self.isHighlight = isHighlight
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    if isHighlight {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(DesignTokens.SkyToneColors.cardGradient)
                    }
                    RoundedRectangle(cornerRadius: cornerRadius)
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

extension View {
    /// TsukiSound風カードスタイルを適用
    /// - Parameters:
    ///   - isHighlight: trueの場合、明るい背景（白15%）を使用
    ///   - cornerRadius: 角丸のサイズ（デフォルト: 12）
    ///   - padding: 内部パディング（デフォルト: 16）
    func tsukiSoundCard(
        isHighlight: Bool = false,
        cornerRadius: CGFloat = 12,
        padding: CGFloat = 16
    ) -> some View {
        modifier(TsukiSoundCardStyle(
            isHighlight: isHighlight,
            cornerRadius: cornerRadius,
            padding: padding
        ))
    }
}
