# Nested Card Corner Issue Guide

## Problem

When nesting cards with rounded corners, dark background artifacts can appear at the corners.

```
Outer card (rounded corners, light gradient background)
└── Inner card (rounded corners, dark background)
    └── Corner artifacts visible (dark squares at corners)
```

**Visual Example:**
```
┌─────────────────────────┐
│ ┌─ dark corners ──────┐ │
│ │■                   ■│ │  ← Dark background visible
│ │   Inner content     │ │     at rounded corners
│ │■                   ■│ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

## Root Cause

1. Outer card uses `.tsukiSoundCard()` with `SkyToneColors.cardGradient`
2. Inner card uses separate `.background(RoundedRectangle...)` with different color (e.g., `CosmosColors.cardBackground`)
3. When both have rounded corners with different background colors, the outer background shows through at corners

## Solution

**Remove the inner card's background** when the component is always used inside another card.

### Before (Problematic)
```swift
struct EmbeddedView: View {
    var body: some View {
        VStack { ... }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmosColors.cardBackground)  // ← Causes corner artifacts
            )
    }
}

// Usage
EmbeddedView()
    .tsukiSoundCard(padding: 0)  // ← Outer card
```

### After (Fixed)
```swift
struct EmbeddedView: View {
    var body: some View {
        VStack { ... }
            // No background - parent provides card styling
    }
}

// Usage
EmbeddedView()
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .tsukiSoundCard(padding: 0)  // ← Single card background
```

## Alternative Solutions

### 1. clipShape (when inner background is required)
```swift
OuterView()
    .clipShape(RoundedRectangle(cornerRadius: 12))
```

### 2. Same background color
Use identical background colors for both cards.

### 3. Parameter-based background
```swift
struct EmbeddedView: View {
    let showBackground: Bool

    var body: some View {
        VStack { ... }
            .background(showBackground ? cardBackground : Color.clear)
    }
}
```

## Affected Files (Historical)

| Date | File | Issue | Fix |
|------|------|-------|-----|
| 2025-12-17 | EmbeddedSessionManagementView.swift | Dark corners when expanded in DurationSessionSettingsView | Removed inner card background |

## Prevention

1. **Single Card Rule**: When embedding views inside `.tsukiSoundCard()`, avoid adding separate card backgrounds
2. **Check Parent Context**: Before adding `.background(RoundedRectangle...)`, verify the component's usage context
3. **Preview Testing**: Always test in the actual parent view, not just isolated previews

## Related

- `TsukiSoundCardStyle.swift` - Standard card modifier
- `DesignTokens.swift` - Color definitions
