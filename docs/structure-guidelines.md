2025/07/27 7:04

# コード構造改善ガイドライン

## 概要

このドキュメントは、プロジェクトのディレクトリ構成とファイル命名における問題点の分析と、保守性・直感性向上のための改善提案をまとめたものです。

## 現状の問題分析

### 1. 命名規則の不統一

**問題の詳細**
- `Utils/` vs `Utilities/` - 同じ用途で異なる命名パターンが混在
- `Visual/` 配下で `Moon/`、`Usagi/` が単数形、他のディレクトリは複数形
- `Manager` vs `Store` の使い分け基準が不明確

**影響**
- 開発者がファイルを探す際の認知負荷が増加
- 新規ファイル作成時の命名判断に迷いが生じる
- コードレビュー時の一貫性チェックが困難

### 2. ファイル配置の問題

**具体的な配置ミス**
- `Components/OptimizedStarBackground.swift` → 星に関する視覚要素なので `Visual/Stars/` が適切
- `Foundation/AwakeEnablerView.swift` → Viewコンポーネントなので `Components/` 配下に配置すべき
- 時間フォーマット関連ファイルが4箇所に分散配置

**影響**
- 関連ファイルの発見性が低下
- 機能の責務境界が曖昧になる
- リファクタリング時の影響範囲把握が困難

### 3. Feature内構造の不統一

**現状の構造例**
```
History/
├── Stores/
├── ViewModels/
└── Views/

Settings/
├── Components/
├── Screens/
├── Sections/
└── SheetBuilders/

Timer/
├── Engine/
├── Managers/
├── Services/
├── Utils/
└── ViewModels/
```

**問題点**
- 機能ごとに異なる構造パターンを採用
- 新しい機能開発時の指針が不明確
- 横断的な変更時の一貫性確保が困難

## 改善提案

### 1. 命名規則の統一

#### ディレクトリ命名ルール

**基本原則**
- 汎用的なディレクトリ名は完全形を使用（略語を避ける）
- 複数のファイルを格納するディレクトリは複数形
- 単一エンティティを表すディレクトリは単数形

**具体的な変更**
```
現在: Utils/ → 推奨: Utilities/
現在: Visual/Moon/, Visual/Usagi/ → 推奨: Visual/Moons/, Visual/Usagis/
```

#### Manager vs Store の使い分け基準

**Manager（管理クラス）**
- システムリソースの管理
- 外部APIとの通信制御
- ライフサイクル管理

**Store（状態管理）**
- アプリケーション状態の保持
- データの永続化
- 状態変更の通知

### 2. ファイル配置の最適化

#### 推奨される移動

```
移動前: Components/OptimizedStarBackground.swift
移動後: Visual/Stars/OptimizedStarBackground.swift

移動前: Foundation/AwakeEnablerView.swift
移動後: Components/System/AwakeEnablerView.swift
```

#### 時間フォーマット機能の統合

**統合先: `Foundation/Formatters/`**
```
Foundation/Formatters/
├── TimeFormatters.swift          # 時間関連フォーマット（統合後）
├── DateFormatters.swift          # 日付関連フォーマット
├── TimeFormattingProtocols.swift # フォーマット共通インターフェース
└── FormatterConstants.swift     # フォーマット定数定義
```

### 3. Feature構造の標準化

#### 標準ディレクトリ構造

```
Features/[FeatureName]/
├── Components/     # UI コンポーネント
├── Models/         # データモデル・エンティティ
├── Services/       # ビジネスロジック・外部連携
├── ViewModels/     # プレゼンテーション層のロジック
├── Views/          # UI画面定義
└── Utilities/      # 機能固有のユーティリティ
```

**[FeatureName] の定義**
- 単一のユースケースまたは密結合した機能群を表す
- 例: `Timer`（タイマー機能）、`History`（履歴管理）、`Settings`（設定画面）
- 目安: 独立してテストできる、ユーザーから見て意味のある機能単位

#### 各ディレクトリの責務

**Components/**
- 再利用可能なUIパーツ
- 機能固有のカスタムビュー
- UIの構成要素

**Models/**
- データ構造の定義
- エンティティクラス
- データバリデーションロジック

**Services/**
- 外部API通信
- データ変換処理
- ビジネスルール実装

**ViewModels/**
- View層とModel層の橋渡し
- UI状態管理
- ユーザー操作の処理

**Views/**
- 画面レイアウト定義
- 画面遷移の実装
- ViewModelとの連携

**Utilities/**
- 機能固有のヘルパー関数
- 拡張機能
- 定数定義

## 実装計画

### Phase 1: 命名規則の統一（1-2週間）
1. `Utils/` → `Utilities/` のリネーム
2. `Visual/` 配下の単数形ディレクトリを複数形に変更
3. Manager/Store の責務定義と分類見直し

### Phase 2: ファイル配置の最適化（2-3週間）
1. 視覚要素ファイルの `Visual/` 配下への移動
2. 時間フォーマット機能の `Foundation/Formatters/` への統合
3. View関連ファイルの `Components/` への整理

### Phase 3: Feature構造の標準化（3-4週間）
1. 既存Feature構造の分析と移行計画策定
2. 標準構造への段階的移行
3. 新規機能開発ガイドラインの策定

## 期待される効果

### 短期的効果
- ファイル発見時間の短縮
- 新規開発者のオンボーディング効率向上
- コードレビュー時の構造チェック簡素化

### 長期的効果
- 機能追加時の設計判断速度向上
- リファクタリング作業の効率化
- コードベース全体の保守性向上

## 運用ガイドライン

### 新規ファイル作成時のチェックリスト
- [ ] 適切なFeature配下のディレクトリに配置されているか
- [ ] ファイル名が責務を適切に表現しているか
- [ ] 関連ファイルとの配置一貫性が保たれているか

### 定期メンテナンス
- 月次での構造乖離チェック
- 四半期でのガイドライン見直し
- 年次での大規模リファクタリング検討

---

**備考**: このガイドラインは継続的改善を前提としており、開発チームの合意形成を経て段階的に適用することを推奨します。