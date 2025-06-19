# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── TsukiUsagi/
│   ├── App/
│   │   ├── ContentView.swift
│   │   ├── TsukiUsagiApp.swift
│   │   └── AppDelegate.swift
│   │
│   ├── Features/
│   │   ├── Timer/
│   │   │   ├── TimerPanel.swift
│   │   │   ├── TimerViewModel.swift
│   │   │   ├── NotificationManager.swift
│   │   │   └── PomodoroPhase.swift
│   │   ├── History/
│   │   │   ├── ViewModels/
│   │   │   │   └── HistoryViewModel.swift
│   │   │   ├── Stores/
│   │   │   │   └── HistoryStore.swift
│   │   │   ├── Models/
│   │   │   └── Views/
│   │   │       └── HistoryView.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   │
│   ├── Views/
│   │   ├── Moon/
│   │   │   ├── MoonView.swift
│   │   │   ├── MoonShape.swift
│   │   │   ├── MoonShadow.swift
│   │   │   └── CraterView.swift
│   │   ├── Backgrounds/
│   │   │   ├── BackgroundGradientView.swift
│   │   │   ├── BackgroundBlack.swift
│   │   │   ├── BackgroundLightPurple.swift
│   │   │   ├── BackgroundPurple.swift
│   │   │   └── BackgroundBlue.swift
│   │   ├── StarView.swift
│   │   ├── DiamondStarsView.swift
│   │   ├── SparkleStarsView.swift
│   │   ├── UsagiView_1.swift
│   │   └── UsagiView_2.swift
│   │
│   ├── Core/
│   │   └── AwakeEnablerView.swift
│   │
│   ├── UI/
│   │   ├── ViewModifiers.swift
│   │   ├── DateToolbar.swift
│   │   ├── AppFormatters.swift
│   │   ├── GlitterTextModifier.swift
│   │   └── GearButtonToolbar.swift
│   │
│   ├── Resources/
│   │   ├── gif/
│   │   │   ├── gold.gif
│   │   │   ├── black_yellow.gif
│   │   │   ├── black_red.gif
│   │   │   └── blue.gif
│   │   └── Fonts/
│   │
│   ├── Assets.xcassets/
│   │
│   └── Extensions/
│       └── Color+Hex.swift
│
├── TsukiUsagi.xcodeproj/
├── TsukiUsagiTests/
├── TsukiUsagiUITests/
├── .build/
├── Package.resolved
├── README.md
└── .gitignore
```

## ディレクトリ構造の説明

### TsukiUsagi/
- メインのアプリケーションコード
  - `App/`: アプリケーションのエントリーポイントとメインビュー
    - `ContentView.swift`: メインビュー
    - `TsukiUsagiApp.swift`: アプリケーションのエントリーポイント
    - `AppDelegate.swift`: アプリケーションのライフサイクル管理

  - `Features/`: 機能ごとにまとめられたモジュール
    - `Timer/`: タイマー機能関連
      - `TimerPanel.swift`: タイマーパネル表示用ビュー
      - `TimerViewModel.swift`: タイマー機能のビジネスロジック
      - `NotificationManager.swift`: 通知機能を管理するシングルトンクラス
      - `PomodoroPhase.swift`: ポモドーロタイマーのフェーズ（集中/休憩）を管理する列挙型
    - `History/`: 履歴機能関連
      - `ViewModels/`: 履歴表示用のビューモデル
        - `HistoryViewModel.swift`: セッション履歴の管理と表示
      - `Stores/`: データ永続化関連
        - `HistoryStore.swift`: セッション履歴の永続化を担当
      - `Models/`: 履歴データモデル（準備中）
      - `Views/`: 履歴表示用ビュー
        - `HistoryView.swift`: セッション履歴の表示画面
    - `Settings/`: 設定機能関連
      - `SettingsView.swift`: アプリケーション設定画面

  - `Views/`: 共通のビューコンポーネント
    - `UsagiView_1.swift`, `UsagiView_2.swift`: うさぎの表示用ビュー
    - `StarView.swift`: 星の表示用ビュー
    - `DiamondStarsView.swift`: ダイヤモンド型の星の表示用ビュー
    - `SparkleStarsView.swift`: キラキラ星の表示用ビュー
    - `Moon/`: 月関連のビューコンポーネント
      - `MoonView.swift`: 月のメインビュー
      - `MoonShape.swift`: 月の形状を定義するビュー
      - `MoonShadow.swift`: 月の影を表示するビュー
      - `CraterView.swift`: 月のクレーターを表示するビュー
    - `Backgrounds/`: 背景関連のビューコンポーネント
      - `BackgroundGradientView.swift`: 背景グラデーション用ビュー
      - `BackgroundBlack.swift`: 黒色の背景グラデーション
      - `BackgroundLightPurple.swift`: 薄紫色の背景グラデーション
      - `BackgroundPurple.swift`: 紫色の背景グラデーション
      - `BackgroundBlue.swift`: 青色の背景グラデーション

  - `Core/`: アプリケーションのコア機能を管理するディレクトリ
    - `AwakeEnablerView.swift`: 画面のスリープを防止する機能を提供するビュー

  - `UI/`: 共通のUIコンポーネントを格納するディレクトリ
    - `ViewModifiers.swift`: 共通のビューモディファイアを定義
    - `DateToolbar.swift`: 日付表示用のツールバーモディファイア
    - `AppFormatters.swift`: アプリケーション全体で使用するフォーマッター
    - `GlitterTextModifier.swift`: キラキラテキスト表示用のモディファイア
    - `GearButtonToolbar.swift`: 設定ボタン用のツールバーモディファイア

  - `Resources/`: アプリケーションのリソースファイルを格納するディレクトリ
    - `gif/`: GIFアニメーションファイル
      - `gold.gif`: 金色のアニメーション
      - `black_yellow.gif`: 黒と黄色のアニメーション
      - `black_red.gif`: 黒と赤のアニメーション
      - `blue.gif`: 青色のアニメーション
    - `Fonts/`: フォントファイル（準備中）

  - `Assets.xcassets/`: アプリケーションのアセット管理

  - `Extensions/`: Swift標準型の拡張機能
    - `Color+Hex.swift`: カラー関連の拡張機能

### プロジェクト関連ファイル
- `TsukiUsagi.xcodeproj/`: Xcodeプロジェクト設定
- `TsukiUsagiTests/`: ユニットテスト
- `TsukiUsagiUITests/`: UIテスト
- `.build/`: Swift Package Managerのビルドディレクトリ
- `Package.resolved`: Swift Package Managerの依存関係管理ファイル
- `README.md`: プロジェクトの説明ドキュメント
- `.gitignore`: Gitの除外設定ファイル