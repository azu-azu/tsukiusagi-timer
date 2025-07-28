import SwiftUI
import UIKit
import CoreText

struct FontTestView: View {
    @State private var allFontFamilies: [String] = []
    @State private var nunitoFonts: [String] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Font Loading Test")
                        .font(.largeTitle)
                        .padding(.bottom)

                    // System info
                    systemInfoSection()

                    // Test each Nunito font individually
                    fontTestSection(
                        title: "DesignTokens.Fonts.label",
                        font: DesignTokens.Fonts.label,
                        expectedFont: "Nunito-Regular"
                    )

                    fontTestSection(
                        title: "DesignTokens.Fonts.labelBold",
                        font: DesignTokens.Fonts.labelBold,
                        expectedFont: "Nunito-Bold"
                    )

                    fontTestSection(
                        title: "DesignTokens.Fonts.caption",
                        font: DesignTokens.Fonts.caption,
                        expectedFont: "Nunito-Regular"
                    )

                    fontTestSection(
                        title: "DesignTokens.Fonts.title",
                        font: DesignTokens.Fonts.title,
                        expectedFont: "Nunito-Bold"
                    )

                    fontTestSection(
                        title: "DesignTokens.Fonts.navigationTitle",
                        font: DesignTokens.Fonts.navigationTitle,
                        expectedFont: "Nunito-Bold"
                    )

                    // Direct font tests
                    directFontTestSection()

                    // Available fonts list
                    availableFontsSection()

                    // PostScript names section
                    postScriptNamesSection()

                    // Bundle debug section
                    bundleDebugSection()

                    // All font families
                    allFontFamiliesSection()
                }
                .padding()
            }
            .navigationTitle("Font Test")
        }
        .onAppear {
            loadFontInfo()
        }
    }

    private func fontTestSection(title: String, font: Font, expectedFont: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)

            Text("The quick brown fox jumps over the lazy dog")
                .font(font)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            Text("Expected: \(expectedFont)")
                .font(.caption)
                .foregroundColor(.gray)

            Divider()
        }
    }

    private func directFontTestSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direct Font Tests")
                .font(.headline)
                .foregroundColor(.green)

            Text("Nunito-Regular Direct")
                .font(DesignTokens.Fonts.label)

            Text("Nunito-Bold Direct")
                .font(DesignTokens.Fonts.labelBold)

            Text("Nunito-Medium Direct")
                .font(DesignTokens.Fonts.label)

            Text("Nunito-Italic Direct")
                .font(DesignTokens.Fonts.label)

            Divider()
        }
    }

    private func availableFontsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available Fonts")
                .font(.headline)
                .foregroundColor(.purple)

            Text("Checking for Nunito fonts...")
                .font(.caption)

            ForEach(checkAvailableFonts(), id: \.self) { fontName in
                Text("✓ \(fontName)")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            let missingFonts = checkMissingFonts()
            if !missingFonts.isEmpty {
                Text("Missing Fonts:")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top)

                ForEach(missingFonts, id: \.self) { fontName in
                    Text("✗ \(fontName)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func checkAvailableFonts() -> [String] {
        let requiredFonts = ["Nunito-Regular", "Nunito-Bold", "Nunito-Medium", "Nunito-Italic"]
        return requiredFonts.filter { fontName in
            UIFont(name: fontName, size: 17) != nil
        }
    }

    private func checkMissingFonts() -> [String] {
        let requiredFonts = ["Nunito-Regular", "Nunito-Bold", "Nunito-Medium", "Nunito-Italic"]
        return requiredFonts.filter { fontName in
            UIFont(name: fontName, size: 17) == nil
        }
    }

    private func loadFontInfo() {
        allFontFamilies = UIFont.familyNames.sorted()
        nunitoFonts = []

        for family in UIFont.familyNames where family.lowercased().contains("nunito") {
            let fontNames = UIFont.fontNames(forFamilyName: family)
            nunitoFonts.append(contentsOf: fontNames)
        }
        nunitoFonts.sort()
    }

    private func systemInfoSection() -> some View {
        SystemInfoSectionView()
    }

    private func postScriptNamesSection() -> some View {
        PostScriptNamesSectionView(nunitoFonts: nunitoFonts)
    }

    private func allFontFamiliesSection() -> some View {
        FontInfoSectionView(allFontFamilies: allFontFamilies)
    }

    private func bundleDebugSection() -> some View {
        BundleDebugSectionView()
    }

    private func registerFontsManually() {
        print("📝 手動フォント登録開始...")

        let fontFiles = ["Nunito-Bold.ttf", "Nunito-Italic.ttf", "Nunito-Medium.ttf", "Nunito-Regular.ttf"]

        for fontFile in fontFiles {
            guard let fontURL = Bundle.main.url(
                forResource: fontFile.replacingOccurrences(of: ".ttf", with: ""),
                withExtension: "ttf"
            ) else {
                print("❌ フォントファイルが見つかりません: \(fontFile)")
                continue
            }

            print("📂 フォントURL: \(fontURL)")

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if success {
                print("✅ フォント登録成功: \(fontFile)")
            } else {
                let errorDescription = error?.takeRetainedValue().localizedDescription ?? "不明なエラー"
                print("❌ フォント登録失敗: \(fontFile) - \(errorDescription)")
            }
        }

        print("🔄 フォント情報を再読み込み中...")
        loadFontInfo()
    }
}

#if DEBUG
struct FontTestView_Previews: PreviewProvider {
    static var previews: some View {
        FontTestView()
    }
}
#endif
