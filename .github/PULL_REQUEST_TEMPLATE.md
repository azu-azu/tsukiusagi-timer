# Pull Request Template

## Core Rules Compliance Check

### Core Rules Updates
- [ ] Core Rules touched? [ ] yes  [ ] no
- [ ] Updated Sections: (List policy IDs, e.g., TXT-01, UI-02, ARCH-01)
- [ ] Synced files: [ ] CLAUDE.md  [ ] .cursorrules

### Version Sync Verification
- [ ] ENGINEERING_RULES.md version: `v1.0`
- [ ] CLAUDE.md version: `v1.0` (Synced with Core)
- [ ] .cursorrules version: `v1.0` (Synced with Core)

---

## Changes Made

### Summary
Brief description of changes made.

### Files Modified
- List all modified files
- Indicate if any new files were created

### Core Rules Compliance
- [ ] Follows Clean Architecture principles (ARCH-01, ARCH-02)
- [ ] Uses DesignTokens instead of direct font/color specs (UI-01)
- [ ] Implements 3-layer text classification for new code (TXT-01)
- [ ] Follows feature-based file organization (STRUCT-01)
- [ ] Uses iPhone 16 simulator for testing (BUILD-01)

---

## Testing

### Build Verification
- [ ] Built successfully on iPhone 16 simulator
- [ ] Tests pass on iPhone 16 simulator
- [ ] Tested in both light and dark mode

### Code Quality
- [ ] SwiftLint passes without new violations
- [ ] No direct NSLocalizedString calls in new code
- [ ] No direct font/color specifications in new code
- [ ] Proper FocusState.Binding usage for .focused()

---

## Documentation Updates

### Core Rules References
If this PR updates core rules, list the specific policy IDs that were modified:
- Policy ID: Description of change

### Sync Requirements
If core rules were updated, ensure:
- [ ] CLAUDE.md references updated policy IDs
- [ ] .cursorrules references updated policy IDs
- [ ] Version numbers are synchronized across all files

---

## Review Checklist

### Architecture Compliance
- [ ] UI → Application → Domain dependency direction maintained
- [ ] No direct external dependencies in Domain layer
- [ ] UseCase follows single responsibility principle
- [ ] View contains only rendering and input handling

### SwiftUI Best Practices
- [ ] iOS 17+ onChange syntax used correctly
- [ ] FocusState.Binding used for .focused()
- [ ] @State used for UI switching (not computed properties)
- [ ] ScrollView content properly placed inside

### Text System
- [ ] New text uses 3-layer classification (Labels/Copy/Messages)
- [ ] No direct NSLocalizedString calls in new code
- [ ] Appropriate layer used based on content type

### File Organization
- [ ] Files placed according to feature-based structure
- [ ] Naming conventions followed
- [ ] Manager vs Store distinction respected

---

## Additional Notes

Any additional context, concerns, or notes for reviewers.

---

## Core Rules Reference

For detailed rules and guidelines, see:
- **ENGINEERING_RULES.md** - Single Source of Truth for all engineering standards
- **CLAUDE.md** - AI assistant guidance and project overview
- **.cursorrules** - Editor-specific guidelines and lint rules