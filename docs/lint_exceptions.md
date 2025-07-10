# Lint Suppress例外管理・運用ルール

## 1. Suppressコメント例

```swift
// swiftlint:disable:next forbidden-font-direct
Text("特殊用途")
    .font(.system(size: 99, weight: .bold)) // [理由] Apple審査用の一時的な特殊表示
```

- 必ず suppress コメントと理由を明記してください

---

## 2. PR運用フロー

1. PR内に suppress コメントを記載
2. PRレビューで例外の妥当性を必ず議論
3. マージ前に /docs/lint_exceptions.md を更新

---

## 3. suppress記録フォーマット例

- File: TsukiUsagi/SettingsView.swift
- Line: 45
- Reason: Apple審査用の一時的な特殊表示
- Why Forbidden: 直値フォント指定は将来的なデザイン統一を困難にし、保守コストが増大するため。
- Date: 2025/07/10
- Author: Kazumi

---

## 4. なぜ禁止か（教育的解説）

直値フォント指定は将来的なデザイン統一を困難にし、保守コストが増大するためです。
- デザイン変更時に全画面一括修正が困難
- UIの一貫性が損なわれる
- LintやCIでの自動検知・修正が難しくなる
- アクセシビリティやDynamic Type対応の妨げになる

---

Suppressの多用は禁止。例外は最小限に抑えてください。