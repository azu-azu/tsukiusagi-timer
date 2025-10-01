import SwiftUI
import UIKit
@testable import TsukiUsagi

struct FontDebugTestView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Nunito Bold Test")
                .font(DesignTokens.Fonts.title)
                .foregroundColor(.blue)

            Text("System Font Test")
                .font(DesignTokens.Fonts.title)
                .foregroundColor(.gray)
        }
        .onAppear {
            #if DEBUG
            print("🟢 FontDebugTestView appeared")

            print("🔍 フォント一覧:")
            for family in UIFont.familyNames.sorted() {
                print("📂 \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("    🔤 \(name)")
                }
            }
            #endif
        }
    }
}

#Preview {
    FontDebugTestView()
}
