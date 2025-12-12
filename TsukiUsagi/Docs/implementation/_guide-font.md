# TsukiUsagi アプリ：フォント統一ガイドライン

## Why Forbidden（なぜ直値フォント指定は禁止か）

直値フォント指定は将来的なデザイン統一を困難にし、保守コストが増大するためです。
- デザイン変更時に全画面一括修正が困難
- UIの一貫性が損なわれる
- LintやCIでの自動検知・修正が難しくなる
- アクセシビリティやDynamic Type対応の妨げになる

---

## Before / After（修正例）

**Before**
```swift
Text("Reset Timer").font(.system(size: 17, weight: .bold))
```

**After**
```swift
Text("Reset Timer").font(DesignTokens.Fonts.labelBold)
```

---

## パフォーマンスやUXへの影響

- 一貫したフォント指定により、ユーザー体験が向上
- Dynamic Typeやカスタムフォント導入時も柔軟に対応可能
- コードレビュー・運用・教育コストが大幅に削減

---

## QuickFix チートシート（実践例）

| NG例 | OK例 | 備考 |
|------|------|------|
| `.font(.system(size: 17))` | `.font(DesignTokens.Fonts.label)` | Semantic名で統一 |
| `.font(.custom("MyFont", size: 17))` | `.font(DesignTokens.Fonts.label)` | カスタムフォントも禁止（例外時はSuppress） |
| `let f = Font.system(size: 17); .font(f)` | `.font(DesignTokens.Fonts.label)` | 変数経由も禁止 |
| `.font(.caption)` | `.font(DesignTokens.Fonts.caption)` | TextStyleもSemantic名で |
| `.font(.headline)` | `.font(DesignTokens.Fonts.labelBold)` | TextStyleもSemantic名で |
| `.captionFont()` | `.font(DesignTokens.Fonts.caption)` | 独自拡張もSemantic名で |
| `.monospaceFont()` | `.font(DesignTokens.Fonts.numericLabel)` | 独自拡張もSemantic名で |

- **必ずSemantic名で指定すること！**
- 迷ったら `.font(DesignTokens.Fonts.label)` または `.labelBold` を使う
- 例外的にカスタムフォントを使う場合はSuppressコメント＋/docs/lint_exceptions.md記録必須

---

## 教育リンク

- 詳細な運用ルール・例外管理: [`/docs/lint_exceptions.md`](./lint_exceptions.md)
- なぜ禁止か・設計思想: [`/docs/font_guidelines.md#why-forbidden`](./font_guidelines.md#why-forbidden)

---

## 教育動画・補足資料（企画枠）

- [ ] フォント統一運用の解説動画（企画中）
    - NG例→OK例の実演
    - Lint・Suppress運用の流れ
- [ ] QuickFix実演動画（企画中）
    - 実際の修正手順を画面収録
    - チートシートの使い方解説

---

## Snapshot Test 運用ルール

### ファイル名命名規則

- `<View名>_<端末名>_<light|dark>.png` で統一
  - 例: `SettingsView_iPhone13Pro_light.png`
  - 例: `TimerPanel_iPhoneSE3_dark.png`

### 差分検知時の運用手順

1. 差分が発生した場合は必ず原因を確認する
2. 意図した変更であれば、ドキュメント（このファイルやPR説明）に記録する
3. バグや意図しない変更の場合は修正・再テストを行う

### ドキュメント更新フロー

- 意図したUI変更・仕様変更の場合は、必ずこのガイドラインや関連ドキュメントを更新すること
- 教育・運用のため、変更理由や背景も簡潔に記載すること

---

> 何か迷ったらこのガイドラインとチートシートを参照してください！

## セマンティックFont名 一覧

| Semantic名    | 用途例           | 備考                  |
| ------------- | ---------------- | --------------------- |
| title         | 大見出し         | 画面トップや重要見出し |
| sectionTitle  | セクションタイトル| カードや区切り見出し   |
| label         | 通常テキスト     | 汎用ラベル            |
| labelBold     | 太字ラベル       | 強調ラベル            |
| caption       | 注釈・小さな文字 | 補足、説明、日付など   |
| numericLabel  | 数字表示         | タイマー、合計値など   |

> **運用ルール**: 迷った場合はこの表を参照し、用途追加や新規semantic名は必ずPRで議論・追記してください。