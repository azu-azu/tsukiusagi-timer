//
//  GearButtonToolbar.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

import SwiftUI

struct GearButtonToolbar: ViewModifier {
    @Binding var showing: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                // ─── ① bottomBar に差し替え ───
                ToolbarItem(placement: .bottomBar) {
                    // ─── ② Spacer で右端に押し出す ───
                    HStack {
                        Spacer()
                        Button {
                            HapticManager.shared.buttonTapFeedback() // ハプティックフィードバック
                            showing = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                        }
                    }
                }
            }
    }
}

// sugary extension stays the same
extension View {
    func gearButtonToolbar(showing: Binding<Bool>) -> some View {
        modifier(GearButtonToolbar(showing: showing))
    }
}
