# Copy Classification Guide

## Overview

This guide defines the 3-layer classification system for text content in TsukiUsagi app.

## Classification Rules

### 1. Labels.swift = Labels (Name Tags)

**Purpose**: Names, headings, item names, state names (nouns/noun phrases, including colon-terminated row labels)

**Examples**:
- `"Session Management"`
- `"Session Info"`
- `"Reflection"`
- `"Session:"`
- `"Task:"`
- `"No task"`
- `"No records for this day"`

**✅ Allowed**:
- Section headings
- Information row prefixes
- Short state names
- Badge names (`"READ-ONLY"`)

**❌ Not Allowed**:
- Button text (OK/Save/Retry etc.)
- Explanatory text
- Questions
- Long text
- Placeholders

### 2. Copy.swift = Microcopy (Fixed Short Text for UI Elements)

**Purpose**: Fixed short text for UI elements (buttons, tabs, links, toggles, snack bar one/two-word displays, short formats)

**Examples**:
- Button: `Cancel / Save / Close / Reset`
- Tab: `Daily / Monthly`
- Link: `Open Daily Reflection`
- Label: `Time:`, `Total: %@`
- Timer format: `Start 🌕 %@ / Final 🌑 %@`

**✅ Allowed**:
- Reusable short action text
- Fixed format patterns
- UI conventional expressions

**❌ Not Allowed**:
- Screen headings (→ Labels)
- Explanatory text
- Questions
- Variable long text

### 3. Messages.swift = Context Messages

**Purpose**: Explanatory text, alerts, placeholders, toast messages, questions, long state descriptions

**Examples**:
- Explanatory/subtitle: `"Edit tasks for default sessions..."`
- Alert: `"Are you sure you want to delete '%@'?"`
- Placeholder: `"Enter session name"`, `"Select task..."`
- Status text: `"Saved..."`, error titles/content

**✅ Allowed**:
- Sentences
- Questions
- Variable templates
- Placeholders
- Toast messages

**❌ Not Allowed**:
- Name tags (headings/row labels)
- Fixed button text (→ Labels or Copy)

## Boundary Rules (Decision Guards)

- **Punctuation marks `? . ! …` included = Messages** (e.g., `"Delete Session?"` is treated as a message)
- **Colon `:` terminated row prefix = Labels** (e.g., `"Session:"`, `"Time:"`)
- **Verbs themselves (OK/Save/Delete/Retry) = Copy**
- **Screen titles**: If **noun/noun phrase** then Labels (e.g., `"Edit Tasks"` as fixed screen heading → Labels). If you want to change per language in the future, choose **Messages** (unify by design policy)
- **Short state displays** (No XXX yet… etc.): If heading-like then **Labels**, if accompanied by explanation then **Messages**
- **Format strings**: If **short and directly embedded in UI elements** then Copy (`"Total: %@"`, `"Start 🌕 %@"`). Long text templates or sentence construction → **Messages**

## Automatic Checks (Prevent Mistakes)

- **If Labels/Copy contains `? . ! …` → NG** (→ Move to Messages)
- **If Labels item exceeds 40 characters → Warning** (long text = suspected message)
- **If verbs appear outside Buttons/Tab/Link/Timer → Warning** (verbs → Copy/Messages)
- **"No … yet"**: If short heading then **Labels**, if accompanied by explanation then **Messages**

## Important Principles

- **Translation necessity is NOT a classification criterion**
- **All layers (Labels/Copy/Messages) can use NSLocalizedString for localization**
- **Classification is based on content type, not localization method**

## Current Copy.swift Structure

```swift
enum Copy {
    enum Button { /* Cancel/Save/Close/Reset */ }      // ✅ Button text → Copy
    enum Label  { /* Time:, Total:%@, Saved */ }       // ✅ Short labels/fixed formats → Copy
    enum Tab    { /* Daily/Monthly */ }                // ✅ Tab names → Copy
    enum Link   { /* Open Daily Reflection */ }        // ✅ Short link text → Copy
    enum Timer  { /* Start 🌕 %@ / Final 🌑 %@ */ }     // ✅ Short fixed formats → Copy
}
```

## Notes

- `Label.saved = "Saved"` should be **Messages** if used as toast text. If used as badge/status short label (context-free, constant display) then **Copy** is also OK.
- **Decide placement by usage** (whether displayed as "text" or "name tag")

## Automated Guards

### SwiftLint Rules (2 rules)
- `labels_no_sentence`: Prevents sentence-like text (?, !, …, period endings) in Labels.swift
- `copy_no_paragraph`: Prevents long text (>40 chars) in Copy.swift

### Tests
- `LabelsPresenceTests`: Verifies namespace separation (Sections.reflection vs InfoRow.reflection) and content rules with NSLocalizedString comparison
- `MessagesLocalizationSmokeTests`: Verifies message content is properly classified

### Naming Convention
- Labels.State: Use `noRecordsToday` (short, memorable)
- Reflection: Dual namespace (Sections.reflection for headings, InfoRow.reflection for row labels)

### Key Principle
All layers can use NSLocalizedString. Classification is based on content type, not localization method.

Run tests: `xcodebuild test -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16'`

-------------------------------------------------------------------------------------------------

# 日本語版

## 3層テキスト分類システムの設計レビュー（最終版）

### 概要
TsukiUsagiアプリのテキストを3層で分類する設計。

### 設計原則

#### 1. 分類基準
- 翻訳の要否は分類基準ではない
- 内容の性質（ラベル/マイクロコピー/メッセージ）で分類
- 全層で `NSLocalizedString` を使用可能

#### 2. 3層の役割分担

**Labels.swift（名札）**
- 目的: 名称・見出し・項目名・状態名
- 例: `"Session Management"`, `"Session:"`, `"No task"`
- 禁止: ボタンテキスト、説明文、疑問文、長文、プレースホルダ

**Copy.swift（マイクロコピー）**
- 目的: UI要素の定型短文
- 例: `Cancel/Save`, `Daily/Monthly`, `Time:`, `Start 🌕 %@`
- 禁止: 画面見出し、説明文、疑問文、可変長文

**Messages.swift（文脈メッセージ）**
- 目的: 説明文、アラート、プレースホルダ、トースト、疑問文
- 例: `"Edit tasks for default sessions..."`, `"Are you sure...?"`, `"Enter session name"`
- 禁止: 名札、固定ボタンテキスト

### 境界ルール（判定ガード）

#### 句読点ルール
- `? . ! …` を含む → Messages
- `:` で終わる行プレフィックス → Labels
- 動詞（OK/Save/Delete/Retry）→ Copy

#### 長さルール
- 40文字超 → Messages
- 短い固定フォーマット → Copy

#### 用途ルール
- 画面タイトル（名詞句）→ Labels
- 状態表示（短い見出し）→ Labels
- 説明付き状態表示 → Messages

### 自動ガード

#### SwiftLintルール（2つ）
1. `labels_no_sentence`: Labels.swift の疑問符・感嘆符・文末ピリオドを検出
2. `copy_no_paragraph`: Copy.swift の40文字超文字列リテラルを検出

#### テスト
1. `LabelsPresenceTests`: 名前空間分離と NSLocalizedString 比較
2. `MessagesLocalizationSmokeTests`: メッセージ分類の確認

### 設計の評価

#### 良い点
1. 分類基準が明確（内容の性質）
2. 境界ルールが実用的（句読点・長さ・用途）
3. 自動ガードで誤分類を防止
4. 全層で `NSLocalizedString` を使用可能
5. 名前空間で役割を分離
6. ドキュメントと実装が一致

#### 改善点
1. 境界ルールの優先順位を明示
2. 移行ガイドラインを追加

### 実装との整合性

#### 一致
- 全層で `NSLocalizedString` を使用
- 分類基準は内容の性質
- 自動ガードは期待どおりに動作
- ドキュメントは実装と一致

#### 不一致
- なし

### 総合評価

#### 設計品質: A
- 明確な分類基準と境界ルール
- 自動ガードで品質を担保
- 実装と整合

#### 実装品質: A
- SwiftLintルールは適切
- テストで検証
- ドキュメントは実装と一致

#### 保守性: A
- 名前空間で役割を分離
- 自動ガードで誤分類を防止
- 移行・運用ガイドが明確

### 結論
3層分類システムは妥当で、自動ガードも機能している。設計と実装は一致し、運用可能な状態。