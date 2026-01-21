//
//  AppSettingsView.swift
//  TsukiUsagi
//
//  App-wide settings (language, etc.)
//

import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageProvider = LanguageProvider.shared

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.SkyToneColors.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Language Section
                        languageSettingsSection()

                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("settings_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.navigationStack)
            .navigationBackButton {
                dismiss()
            }
        }
        .id(languageProvider.language) // Force view refresh on language change
    }

    // MARK: - Language Settings Section

    @ViewBuilder
    private func languageSettingsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("settings.language.title".localized.uppercased())
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.SkyToneColors.textSecondary)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(AppLanguage.allCases) { lang in
                    languageOptionRow(lang)
                    if lang != AppLanguage.allCases.last {
                        Divider()
                            .background(DesignTokens.SkyToneColors.textQuaternary.opacity(0.3))
                    }
                }
            }
            .tsukiSoundCard(padding: 0)
        }
    }

    @ViewBuilder
    private func languageOptionRow(_ lang: AppLanguage) -> some View {
        Button {
            languageProvider.language = lang
        } label: {
            HStack(spacing: 12) {
                Image(systemName: languageProvider.language == lang ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(
                        languageProvider.language == lang
                            ? DesignTokens.MoonColors.accentBlue
                            : DesignTokens.SkyToneColors.textQuaternary
                    )

                Text(lang.displayName)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView()
    }
}
#endif
