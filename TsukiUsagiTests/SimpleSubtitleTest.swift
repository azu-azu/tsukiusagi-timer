import SwiftUI
import UIKit
@testable import TsukiUsagi

struct DirectDescriptionEditTest: View {
    @State private var testDescriptions: [String] = ["First item", "Second item"]
    @State private var isAnyFieldFocused: Bool = false

    var body: some View {
        // ✅ まずはNavigationStackなしで試してみる
        VStack {
            Text("Direct Test - Count: \(testDescriptions.count)")
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary) // ✅ 月光色
                .padding()

            Text("Direct Test - Count: \(testDescriptions.count)")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textPrimary) // ✅ 月光色
                .padding()

            DescriptionEditContent(
                sessionName: "Test Session",
                descriptions: testDescriptions,
                editingIndex: nil,
                onDescriptionsChange: { newDescriptions in
                    #if DEBUG
                    print("🟦🟦🟦 Direct test received change: \(newDescriptions)")
                    #endif
                    testDescriptions = newDescriptions
                },
                isAnyFieldFocused: $isAnyFieldFocused,
                onClearFocus: {
                    isAnyFieldFocused = false
                }
            )

            Spacer()

            // 状態確認用
            Text("Current descriptions: \(testDescriptions.joined(separator: ", "))")
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary) // ✅ セカンダリ月光色
                .padding()
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea()) // ✅ 宇宙背景色
        .navigationTitle("Direct Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ✅ カスタムナビゲーションタイトル（デザイントークンのフォント適用）
            ToolbarItem(placement: .principal) {
                Text("Direct Test")
                    .font(DesignTokens.Fonts.labelBold) // Nunito太字
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            }

            // Font Test Navigation
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Debug") {
                    FontTestView()
                }
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.accentBlue)
            }
        }
        .onAppear {
            #if DEBUG
            print("📝 📦 Available Fonts:")
            for family in UIFont.familyNames.sorted() {
                print("📂 Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("  🔤 Font: \(name)")
                }
            }
            #endif
        }
    }
}

#if DEBUG
struct DirectDescriptionEditTest_Previews: PreviewProvider {
    static var previews: some View {
        // ✅ プレビューでNavigationStackを提供
        NavigationStack {
            DirectDescriptionEditTest()
        }
    }
}
#endif
