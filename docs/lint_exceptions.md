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

---

## 5. 命名規則（短すぎる変数名の例外）

原則として、変数名・定数名は意味のある名前を付けること。
ただし、以下の場合は例外として単一文字の変数名を許可する。

- `i`, `j`, `k`：ループカウンタ等、短いスコープでのみ許可
- `x`, `y`：座標や数学的意味での使用は許可
- `t`, `p`：一時的な値で、かつコメントで意味が明示されている場合のみ許可
- それ以外（`f`, `m`, `r`, `g`, `b`, `s` など）は descriptive name にリネームすること

Suppressや例外コメントには、必ず理由を明記すること。

### 例
```swift
// x, y: 中央付近の座標（数学的意味で許容）
let x = CGFloat.random(in: 0.48 ... 0.52)
let y = CGFloat.random(in: areaToUse.minYRatio ... areaToUse.maxYRatio)

// t: 一時的なタイマー（用途をコメントで明示）
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in ... }

// NG例（リネーム推奨）
let f = DateFormatter() // → let dateFormatter = DateFormatter()
let r = ... // → let red = ...
```