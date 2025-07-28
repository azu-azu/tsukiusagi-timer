import SwiftUI
import UIKit
import CoreText

// MARK: - Font Test Helper Views

struct FontInfoSectionView: View {
    let allFontFamilies: [String]

    var body: some View {
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
}

struct PostScriptNamesSectionView: View {
    let nunitoFonts: [String]

    var body: some View {
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
                            .font(DesignTokens.Fonts.caption)
                    }
                }
            }

            Divider()
        }
    }
}

struct BundleDebugSectionView: View {
    var body: some View {
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
                    if Bundle.main.url(
                        forResource: fontFile.replacingOccurrences(of: ".ttf", with: ""),
                        withExtension: "ttf"
                    ) != nil {
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

        print("🔄 フォント再読み込み...")
    }
}

struct SystemInfoSectionView: View {
    var body: some View {
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

    private func checkAvailableFonts() -> [String] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let fontPath = "\(resourcePath)/Fonts"

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: fontPath)
            return contents.filter { $0.hasSuffix(".ttf") || $0.hasSuffix(".otf") }
        } catch {
            return []
        }
    }

    private func checkMissingFonts() -> [String] {
        let expectedFonts = ["Nunito-Bold.ttf", "Nunito-Italic.ttf", "Nunito-Medium.ttf", "Nunito-Regular.ttf"]
        let availableFonts = checkAvailableFonts()

        return expectedFonts.filter { !availableFonts.contains($0) }
    }
}

