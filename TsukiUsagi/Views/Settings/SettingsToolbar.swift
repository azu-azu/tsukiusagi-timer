//
//  SettingsToolbar.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/13.
//

// SettingsToolbar.swift  (TSUKIUSAGI/TsukiUsagi/)
import SwiftUI

struct SettingsToolbar: ViewModifier {
	@Binding var showing: Bool

	func body(content: Content) -> some View {
		content
			.toolbar {                       // ← the original toolbar lives here
				ToolbarItem(placement: .navigationBarTrailing) {
					Button { showing = true } label: {
						Image(systemName: "gearshape.fill")
							.symbolRenderingMode(.hierarchical)
							.foregroundColor(Color.white.opacity(1.0))
					}
				}
			}
	}
}

// sugary extension so the call site reads nicely
extension View {
	func settingsToolbar(showing: Binding<Bool>) -> some View {
		self.modifier(SettingsToolbar(showing: showing))
	}
}

