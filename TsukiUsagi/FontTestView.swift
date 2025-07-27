import SwiftUI
import UIKit

struct FontTestView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Font Loading Test")
                        .font(.largeTitle)
                        .padding(.bottom)
                    
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
                }
                .padding()
            }
            .navigationTitle("Font Test")
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
}

#if DEBUG
struct FontTestView_Previews: PreviewProvider {
    static var previews: some View {
        FontTestView()
    }
}
#endif