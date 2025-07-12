---
name: 🔧 Lint違反リファクタ
about: Lint違反の構造的リファクタリング用Issue
title: '[Lint Refactor] '
labels: ['lint', 'refactor', 'technical-debt']
assignees: ''
---

## 現状
（例：TimerViewModel.swift が type_body_length 違反。400行超。分割設計未着手）

## やりたいこと
（例：TimerViewModelを責務ごとに分割し、可読性・保守性を向上させる）

## Suppressコメント例
```swift
// swiftlint:disable:next type_body_length // Issue #123: TimerViewModel分割リファクタ予定（2024年7月目標）
```

## 目標
（例：2024年7月中に分割完了）

## 担当
（例：Kazumi）

## 進捗
- [ ] 分割方針検討
- [ ] 分割対象の切り出し範囲決定
- [ ] 新ファイルの作成
- [ ] テスト修正・追加
- [ ] PR作成

## 影響範囲
- View層の呼び出しコード
- UnitTest
- SwiftUI Previews
- App全体の挙動（TimerViewModelは重要ロジック）

## 補足・備考
（例：分割方針の詳細、技術的考慮事項など）