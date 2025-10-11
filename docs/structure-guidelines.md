2025/08/13 10:00

# コード構造ガイドライン（現状同期版）

## 概要
このドキュメントは、TsukiUsagi のディレクトリ構造・命名規則・責務分離ルールを定義し、実リポジトリの現状に同期した方針を示します。

- 参照: docs/_arch-guidelines.md
- 参照: docs/structure-directory.md（実ディレクトリ一覧）

## 状態サマリ（現状との整合）
- Visual 配下の単複不一致は解消済み（Mois/Usagis/Stars の複数形統一）
- `OptimizedStarBackground.swift` は `Visual/Stars/` に移動済み
- 時間フォーマットは `Foundation/Formatters/` に統合済み
- `AwakeEnablerView.swift` は全体共通 UI として `GlobalComponents/System/` に配置（従来の "Foundation 配下" 想定を修正）

## 現状の構造（要点）
- Global 共通 UI: `GlobalComponents/`（Buttons, Headers, Modals, System, RoundedCard）
- 機能横断 UI: `CrossFeatureUI/`（Cards, Controls, Navigation）
- 機能別: `Features/[FeatureName]/`（下記の標準＋許容バリアント）
- 基盤: `Foundation/`（DesignTokens, Formatters, Extensions, Managers, UIKitSupport など）
- モデル: `Models/Core/`（アプリ共通のエンティティ）
- 視覚要素: `Visual/`（Backgrounds, Moons, Stars, Usagis）

## 命名規則
- ディレクトリは完全形（略語を避ける）
- 複数のファイルを含むディレクトリは複数形（例: `Stars/`, `Usagis/`）
- 単一エンティティのディレクトリは単数形を許容（実態に合わせる）

### Manager vs Store vs Service
- Manager: システムリソース、ライフサイクル、外部 API 連携などの調整役
  - 例: `Foundation/Managers/SessionManager.swift`
  - Feature 内での Manager はサブシステム調整目的に限り許容（例: `Features/Streak/Manager/`）
- Store: 状態保持や永続化、通知（現状は Manager が主）
- Service: ビジネスロジックや外部連携を担うユースケース単位の処理
  - 例: `Features/Timer/Services/TimerEngine.swift` ほか

## Feature 構造の標準と許容バリアント
標準構造:
```
Features/[FeatureName]/
├── Components/     # UI コンポーネント
├── Models/         # ドメインモデル
├── Services/       # ビジネスロジック・外部連携
├── ViewModels/     # プレゼンテーション層ロジック
├── Views/          # 画面定義
└── Utilities/      # 機能固有ユーティリティ（必要時）
```

現状反映の許容バリアント（代表例）:
- Settings
  - `Components/`, `Sections/`, `SheetBuilders/`（`Screens/` は現状空で必要時に追加）
- History
  - `Helpers/`, `Models/`, `Services/`, `ViewModels/`, `Views/`
- Timer
  - `Components/`, `Models/`, `Services/`, `ViewModels/`, `Views/`
  - かつての `Engine/Managers/Utils/` は廃止し、`Services/` へ集約
- Streak
  - `Manager/`, `Views/`（連続記録システムの調整ロジックを Manager として分離）
- App/Common
  - 共通 UI は `GlobalComponents/`、機能横断は `CrossFeatureUI/` を優先

## ファイル配置ルール（要点）
- 視覚要素は `Visual/[Category]/` に配置（背景・月・星・うさぎなど）
- 再利用 UI は `GlobalComponents/`、機能横断 UI は `CrossFeatureUI/`、機能固有 UI は `Features/*/Components/`
- 時間フォーマットは `Foundation/Formatters/` に集約
- UIKit 連携コードは `Foundation/UIKitSupport/` 配下に階層化（Modifiers/Toolbars/Wrappers）

## 運用ガイドライン
- 新規ファイル作成時チェック
  - [ ] 適切なレイヤー/機能配下にあるか（Global/CrossFeature/Feature）
  - [ ] 命名が責務を明確に表し、既存と一貫か
  - [ ] 近縁ファイルと同じ階層規則に従っているか
- 定期メンテ
  - 月次: ディレクトリ乖離チェック
  - 四半期: ガイドライン見直し

## 付記（差分履歴の扱い）
- 以前の課題として記載していた以下は解消済み:
  - Visual 配下の単複不一致
  - `OptimizedStarBackground.swift` の配置
  - 時間フォーマットの分散
  - `AwakeEnablerView` の配置（現: `GlobalComponents/System/`）
- ドキュメントの古い表記（例: `architecture/architecture_guidelines.md`）は `docs/_arch-guidelines.md` に統一
