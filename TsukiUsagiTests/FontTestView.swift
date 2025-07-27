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
                .font(.custom("Nunito-Regular", size: 17))

            Text("Nunito-Bold Direct")
                .font(.custom("Nunito-Bold", size: 17))

            Text("Nunito-Medium Direct")
                .font(.custom("Nunito-Medium", size: 17))

            Text("Nunito-Italic Direct")
                .font(.custom("Nunito-Italic", size: 17))

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

        for family in UIFont.familyNames {
            if family.lowercased().contains("nunito") {
                let fontNames = UIFont.fontNames(forFamilyName: family)
                nunitoFonts.append(contentsOf: fontNames)
            }
        }
        nunitoFonts.sort()
    }

    private func systemInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Information")
                .font(.headline)
                .foregroundColor(.blue)

            Text("iOS Version: \(UIDevice.current.systemVersion)")
                .font(.caption)

            Text("Bundle Identifier: \(Bundle.main.bundleIdentifier ?? "Unknown")")
                .font(.caption)

            if let infoPlist = Bundle.main.infoDictionary,
               let fonts = infoPlist["UIAppFonts"] as? [String] {
                Text("UIAppFonts in Info.plist: \(fonts.count) fonts")
                    .font(.caption)
                    .foregroundColor(.green)

                ForEach(fonts, id: \.self) { fontFile in
                    Text("  • \(fontFile)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                Text("❌ UIAppFonts not found in Info.plist")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Divider()
        }
    }

    private func postScriptNamesSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PostScript Font Names")
                .font(.headline)
                .foregroundColor(.purple)

            Text("These are the exact names to use in .custom() calls:")
                .font(.caption)
                .foregroundColor(.gray)

            if nunitoFonts.isEmpty {
                Text("❌ No Nunito fonts found in system")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                ForEach(nunitoFonts, id: \.self) { fontName in
                    HStack {
                        Text("✓ \(fontName)")
                            .font(.caption)
                            .foregroundColor(.green)

                        Spacer()

                        Text("Sample")
                            .font(.custom(fontName, size: 14))
                    }
                }
            }

            Divider()
        }
    }

    private func allFontFamiliesSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Font Families (\(allFontFamilies.count))")
                .font(.headline)
                .foregroundColor(.orange)

            Text("Looking for Nunito family...")
                .font(.caption)
                .foregroundColor(.gray)

            ForEach(allFontFamilies.prefix(10), id: \.self) { family in
                if family.lowercased().contains("nunito") {
                    Text("✅ \(family)")
                        .font(.caption)
                        .foregroundColor(.green)
                        .bold()
                } else {
                    Text("• \(family)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            if allFontFamilies.count > 10 {
                Text("... and \(allFontFamilies.count - 10) more families")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }

    private func bundleDebugSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bundle Debug")
                .font(.headline)
                .foregroundColor(.orange)

            Text("フォントファイルの実際の存在確認:")
                .font(.caption)
                .foregroundColor(.gray)

            let fontFiles = ["Nunito-Bold.ttf", "Nunito-Italic.ttf", "Nunito-Medium.ttf", "Nunito-Regular.ttf"]

            ForEach(fontFiles, id: \.self) { fontFile in
                HStack {
                    if Bundle.main.url(forResource: fontFile.replacingOccurrences(of: ".ttf", with: ""), withExtension: "ttf") != nil {
                        Text("✅ \(fontFile)")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("❌ \(fontFile)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
            }

            Button("手動フォント登録テスト") {
                registerFontsManually()
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.top, 4)

            Divider()
        }
    }

    private func registerFontsManually() {
        print("📝 手動フォント登録開始...")

        let fontFiles = ["Nunito-Bold.ttf", "Nunito-Italic.ttf", "Nunito-Medium.ttf", "Nunito-Regular.ttf"]

        for fontFile in fontFiles {
            guard let fontURL = Bundle.main.url(forResource: fontFile.replacingOccurrences(of: ".ttf", with: ""), withExtension: "ttf") else {
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
