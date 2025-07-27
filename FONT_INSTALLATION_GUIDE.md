# 🔧 Nunito Font Installation Guide for Xcode

## Current Status
✅ Font files exist in: `/TsukiUsagi/Resources/Fonts/`
✅ Enhanced `FontTestView.swift` created for debugging
⚠️ Fonts need proper Xcode project integration

## 📋 Step-by-Step Instructions

### Step 1: Remove Current Font References (if any)
1. Open Xcode
2. In Project Navigator, look for any `.ttf` files with red "A" icons
3. Right-click each red font file → "Delete" → "Move to Trash"

### Step 2: Add Fonts with "Copy Items If Needed"
1. Right-click on `TsukiUsagi` project in navigator
2. Select **"Add Files to 'TsukiUsagi'"**
3. Navigate to: `/Users/mypc/AI_develop/TsukiUsagi/TsukiUsagi/Resources/Fonts/`
4. Select ALL 4 font files:
   - `Nunito-Bold.ttf`
   - `Nunito-Italic.ttf`
   - `Nunito-Medium.ttf`
   - `Nunito-Regular.ttf`
5. **IMPORTANT**: Check ✅ **"Copy items if needed"**
6. **IMPORTANT**: Under "Add to target", ensure ✅ **TsukiUsagi** is checked
7. Click **"Add"**

### Step 3: Verify Info.plist Configuration
The `UIAppFonts` array should already be configured in `project.pbxproj`:
```xml
<key>UIAppFonts</key>
<array>
    <string>Nunito-Bold.ttf</string>
    <string>Nunito-Italic.ttf</string>
    <string>Nunito-Medium.ttf</string>
    <string>Nunito-Regular.ttf</string>
</array>
```

### Step 4: Clean and Rebuild
1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

### Step 5: Test Font Loading
1. Run the app in Simulator
2. Navigate to `FontTestView` (add it to your main navigation)
3. Check the output for:
   - ✅ "UIAppFonts in Info.plist: 4 fonts"
   - ✅ PostScript names section showing Nunito fonts
   - ✅ Green checkmarks for available fonts

## 🧪 Testing Code

Add this to your main view for testing:
```swift
NavigationLink("Font Test") {
    FontTestView()
}
```

## 🔍 Debugging Output

The `FontTestView` will show:

### Expected Success Output:
```
✅ UIAppFonts in Info.plist: 4 fonts
  • Nunito-Bold.ttf
  • Nunito-Italic.ttf
  • Nunito-Medium.ttf
  • Nunito-Regular.ttf

PostScript Font Names:
✓ Nunito-Bold        [Sample]
✓ Nunito-Italic      [Sample]
✓ Nunito-Medium      [Sample]
✓ Nunito-Regular     [Sample]
```

### If Fonts Are Missing:
```
❌ UIAppFonts not found in Info.plist
❌ No Nunito fonts found in system
```

## 📝 PostScript Names for DesignTokens

Once working, use these exact names in `DesignTokens.Fonts`:
```swift
static var label: Font {
    Font.custom("Nunito-Regular", size: FontSize.body)
}

static var labelBold: Font {
    Font.custom("Nunito-Bold", size: FontSize.body)
}

static var labelMedium: Font {
    Font.custom("Nunito-Medium", size: FontSize.body)
}

static var labelItalic: Font {
    Font.custom("Nunito-Italic", size: FontSize.body)
}
```

## 🚨 Common Issues

1. **Red A Icons**: Fonts linked but not copied
   - Solution: Re-add with "Copy items if needed" ✅

2. **Fonts Not Loading**: Missing from app bundle
   - Check: Target membership in Xcode
   - Verify: Build phases → Copy Bundle Resources

3. **Wrong PostScript Names**: Case sensitivity matters
   - Use: Exact names from `FontTestView` output
   - NOT: Generic names like "Nunito Regular"

## ✅ Success Criteria

- [ ] No red A icons in Xcode project navigator
- [ ] FontTestView shows 4 fonts in UIAppFonts
- [ ] PostScript names section shows all 4 Nunito variants
- [ ] Visual samples render with Nunito (not system font)
- [ ] DesignTokens.Fonts.label shows Nunito in app

After completing these steps, your Nunito fonts should be properly integrated and ready for use throughout the TsukiUsagi app! 🎨