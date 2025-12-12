# Lint Suppress例外管理・運用ルール

## 1. Suppress運用の基本原則

### 🚨 重要：Suppressは「やむを得ない場合のみ」
- Suppressは技術的負債の一時的な延期
- 必ず解消計画を立て、Issueで管理する
- 無制限なSuppressは禁止

### 📝 Suppressコメントの必須要素
```swift
// swiftlint:disable:next type_body_length // Issue #123: TimerViewModel分割リファクタ予定（2024年7月目標）
```

**必須要素：**
- Issue番号（#123）
- 理由（TimerViewModel分割リファクタ予定）
- 目標月（2024年7月目標）

### 🔄 Suppress運用フロー
1. **Suppressコメント追加** → Issue番号・理由・目標月を明記
2. **Issue作成** → 進捗・影響範囲を記載
3. **PR作成** → Suppress理由・影響範囲を記載
4. **解消計画実行** → 目標月までにリファクタ完了

## 2. Suppressコメント例

### 構造的リファクタ用
```swift
// swiftlint:disable:next type_body_length // Issue #123: TimerViewModel分割リファクタ予定（2024年7月目標）
// swiftlint:disable:next function_parameter_count // Issue #124: add関数の引数整理予定（2024年8月目標）
```

### 特殊用途用
```swift
// swiftlint:disable:next forbidden-font-direct
Text("特殊用途")
    .font(.system(size: 99, weight: .bold)) // [理由] Apple審査用の一時的な特殊表示
```

- 必ず suppress コメントと理由を明記してください

---

## 3. PR運用フロー

### 📋 PRテンプレート必須項目
- [ ] **Suppress理由欄**：このPRでSuppressしたLint違反と理由
- [ ] **影響範囲欄**：View層・テスト・Previewsへの影響
- [ ] **補足・備考欄**：Suppress理由の詳細、今後のリファクタ方針

### 🔄 PR運用ステップ
1. PR内に suppress コメントを記載
2. **Suppress理由・影響範囲をPRテンプレートに記載**
3. PRレビューで例外の妥当性を必ず議論
4. マージ前に /docs/lint_exceptions.md を更新

---

## 4. Issue管理フォーマット例

### 📝 Issueテンプレート必須項目
- **現状**：Lint違反の詳細
- **やりたいこと**：リファクタの目的
- **Suppressコメント例**：Issue番号・理由・目標月を含む
- **目標**：解消予定月
- **担当**：責任者
- **進捗**：チェックリスト形式
- **影響範囲**：View層・テスト・Previewsへの影響

### 📊 suppress記録フォーマット例

- File: TsukiUsagi/Foundation/DesignTokens.swift
- Line: 131,135,139,143,147,151,155
- Reason: セマンティック名の実体定義用途
- Issue: #3
- Why Forbidden: 直値フォント指定は将来的なデザイン統一を困難にし、保守コストが増大するため。
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Foundation/UIKitSupport/ViewModifiers.swift
- Line: 83
- Reason: フォールバック用途
- Issue: #3
- Why Forbidden: AvenirNext取得失敗時の一時的なフォールバック
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Foundation/DesignTokens.swift
- Line: 131,135,139,143,147,151,155
- Reason: セマンティック名の実体定義用途
- Issue: #3
- Why Forbidden: DesignTokens.Fonts の実体定義として、セマンティック名を提供するため
- Date: 2024/07/12
- Author: Kazumi

- File: TsukiUsagi/Components/Visual/Stars/DiamondStarsView.swift
- Line: 91
- Reason: 一時変数用途の命名ルール明確化
- Issue: #4
- Why Forbidden: forEach内の一時変数（s等）は許容範囲として明文化
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Components/Visual/Stars/FlowingStarsView.swift
- Line: 110
- Reason: 一時変数用途の命名ルール明確化
- Issue: #4
- Why Forbidden: ループカウンタ等の一時変数は許容範囲として明文化
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Features/Shared/SessionManager.swift
- Line: 56
- Reason: 一時変数用途の命名ルール明確化
- Issue: #4
- Why Forbidden: 一時的なSet等の変数は許容範囲として明文化
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Features/Timer/TimerViewModel.swift
- Line: 107
- Reason: 一時変数用途の命名ルール明確化
- Issue: #4
- Why Forbidden: Timerクロージャの未使用引数（_）は許容範囲として明文化
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Features/Settings/SettingsView.swift
- Line: 20
- Reason: TODO管理のためSuppress
- Issue: #5
- Why Forbidden: 将来的な中間バッファ導入等のTODO管理のため
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Features/History/ViewModels/HistoryViewModel.swift
- Line: 23
- Reason: TODO管理のためSuppress
- Issue: #5
- Why Forbidden: add関数のパラメータ数整理等のTODO管理のため
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Features/History/ViewModels/HistoryViewModel.swift
- Line: 23
- Reason: TODO管理のためSuppress
- Issue: #5
- Why Forbidden: add関数のパラメータ数整理等のTODO管理のため
- Date: 2024/07/11
- Author: Kazumi

- File: TsukiUsagi/Features/History/ViewModels/HistoryViewModel.swift
- Line: 6
- Reason: SessionRecord の memberwise initializer は設計上許容するため suppress
- Issue: #6
- Why Forbidden: struct の memberwise initializer は設計上の意図的なものであり、責務がごちゃついているわけではないため
- Date: 2024/07/11
- Author: Kazumi

---

## 5. なぜ禁止か（教育的解説）

直値フォント指定は将来的なデザイン統一を困難にし、保守コストが増大するためです。
- デザイン変更時に全画面一括修正が困難
- UIの一貫性が損なわれる
- LintやCIでの自動検知・修正が難しくなる
- アクセシビリティやDynamic Type対応の妨げになる

---

## 6. 技術的負債管理のベストプラクティス

### 🎯 目標
- **技術的負債の見える化**：Suppress箇所をIssueで管理
- **未来の自分も迷わない**：理由・目標月・影響範囲を明記
- **チーム透明性**：PRテンプレートで理由を共有

### 📈 成功指標
- Suppress箇所の100% Issue化
- 目標月内の解消率80%以上
- 新規Suppressの事前レビュー実施率100%

### 🚫 禁止事項
- Suppressの多用
- 理由・目標月なしのSuppress
- Issue化しないSuppress
- 影響範囲不明のSuppress

---

**Suppressの多用は禁止。例外は最小限に抑えてください。**

---

## 7. 命名規則（短すぎる変数名の例外）

原則として、変数名・定数名は意味のある名前を付けること。
ただし、以下の場合は例外として単一文字の変数名を許可する。

### 許可される単一文字変数名

#### 1. ループ・イテレーション用
- `i`, `j`, `k`：ループカウンタ等、短いスコープでのみ許可
- `s`：forEach内の一時変数（SparkleSpec等の短命なオブジェクト）

#### 2. 座標・数学的意味
- `x`, `y`：座標や数学的意味での使用は許可
- `t`：Timerクロージャの未使用引数（`_`の代替）

#### 3. 一時的な値（コメント必須）
- `t`, `p`：一時的な値で、かつコメントで意味が明示されている場合のみ許可

### 禁止される単一文字変数名
- `f`, `m`, `r`, `g`, `b` など：descriptive name にリネームすること

### Suppressコメント例
```swift
// swiftlint:disable:next identifier_name
// Issue #4: 一時変数用途の命名ルール明確化（2024年8月目標）
// s: SparkleSpecの短命な一時変数（forEach内のみ許容）
ForEach(stars) { s in ... }

// swiftlint:disable:next identifier_name
// Issue #4: 一時変数用途の命名ルール明確化（2024年8月目標）
// t: Timerクロージャの一時変数（用途明示）
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in ... }

// swiftlint:disable:next identifier_name
// Issue #4: 一時変数用途の命名ルール明確化（2024年8月目標）
// _: 使用しない引数（用途明示）
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in ... }
```

### 例
```swift
// x, y: 中央付近の座標（数学的意味で許容）
let x = CGFloat.random(in: 0.48 ... 0.52)
let y = CGFloat.random(in: areaToUse.minYRatio ... areaToUse.maxYRatio)

// t: 一時的なタイマー（用途をコメントで明示）
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in ... }

// s: SparkleSpecの短命な一時変数（forEach内のみ許容）
ForEach(stars) { s in ... }

// NG例（リネーム推奨）
let f = DateFormatter() // → let dateFormatter = DateFormatter()
let r = ... // → let red = ...
```