# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── Entry/
│   ├── ContentView.swift
│   ├── TsukiUsagiApp.swift
│   └── AppDelegate.swift
│
├── Features/
│   ├── Timer/
│   │   ├── TimerViewModel.swift
│   │   ├── TimerPanel.swift
│   │   ├── NotificationManager.swift
│   │   ├── PomodoroPhase.swift
│   │   ├── TimerEditView.swift
│   │   ├── TimerTextView.swift
│   │   ├── RecordedTimesView.swift
│   │   └── HapticManager.swift
│   ├── History/
│   │   ├── Views/
│   │   │   └── HistoryView.swift
│   │   ├── ViewModels/
│   │   │   └── HistoryViewModel.swift
│   │   └── Stores/
│   │       └── HistoryStore.swift
│   └── Settings/
│       └── SettingsView.swift
│
├── Components/
│   └── Visual/
│       ├── Moon/
│       │   ├── QuietMoonView.swift
│       │   ├── MoonView.swift
│       │   ├── MoonShadow.swift
│       │   ├── MoonShape.swift
│       │   └── CraterView.swift
│       ├── Stars/
│       │   ├── FlowingStarsView.swift
│       │   ├── StaticStarsView.swift
│       │   ├── DiamondStarsView.swift
│       │   └── SparkleStarsView.swift
│       ├── Usagi/
│       │   ├── UsagiView_1.swift
│       │   └── UsagiView_2.swift
│       └── Backgrounds/
│           ├── BackgroundBlack.swift
│           ├── BackgroundBlue.swift
│           ├── BackgroundLightPurple.swift
│           ├── BackgroundPurple.swift
│           └── BackgroundGradientView.swift
│
├── Foundation/
│   ├── Formatters/
│   │   ├── DateFormatters.swift
│   │   └── TimeFormatters.swift
│   ├── Extensions/
│   │   ├── Color+Hex.swift
│   │   └── View+SessionVisibility.swift
│   ├── UIKitSupport/
│   │   ├── ViewModifiers.swift
│   │   ├── GlitterTextModifier.swift
│   │   ├── GearButtonToolbar.swift
│   │   └── UIKitWrappers/
│   │       └── SelectableTextView.swift
│   └── AwakeEnablerView.swift
│
├── Constants/
│   └── LayoutConstants.swift
│
├── Resources/
│   ├── gif/
│   │   ├── gold.gif
│   │   ├── black_yellow.gif
│   │   ├── black_red.gif
│   │   └── blue.gif
│   └── MoonMessage/
│       └── MoonMessage.swift
│
├── Assets.xcassets/
│
├── TsukiUsagiTests/
│   ├── ContentViewTests.swift
│   └── TsukiUsagiTests.swift
│
├── TsukiUsagiUITests/
│   ├── TsukiUsagiUITests.swift
│   └── TsukiUsagiUITestsLaunchTests.swift
│
├── .gitignore
├── README.md
├── Package.resolved
└── directory_structure.md
```

## プロジェクト構造の説明

### 主要ディレクトリ

#### Entry/
アプリケーションのエントリーポイントとなるファイル群
- `ContentView.swift`: メインのコンテンツビュー
- `TsukiUsagiApp.swift`: アプリケーションのメインファイル
- `AppDelegate.swift`: アプリケーションのデリゲート

#### Features/
機能別に整理されたモジュール群

**Timer/**
- `TimerViewModel.swift`: タイマーのビジネスロジック
- `TimerPanel.swift`: タイマーパネルのUI
- `NotificationManager.swift`: 通知管理
- `PomodoroPhase.swift`: ポモドーロフェーズ定義
- `TimerEditView.swift`: タイマー編集画面
- `TimerTextView.swift`: タイマーテキスト表示
- `RecordedTimesView.swift`: 記録された時間の表示
- `HapticManager.swift`: 触覚フィードバック管理

**History/**
- `Views/HistoryView.swift`: 履歴表示画面
- `ViewModels/HistoryViewModel.swift`: 履歴のビジネスロジック
- `Stores/HistoryStore.swift`: 履歴データの管理

**Settings/**
- `SettingsView.swift`: 設定画面
- `元.swift`: 設定関連の補助ファイル

#### Components/Visual/
UIコンポーネント群

**Moon/**
月の視覚効果コンポーネント
- `QuietMoonView.swift`: 静かな月の表示
- `MoonView.swift`: メインの月表示
- `MoonShadow.swift`: 月の影効果
- `MoonShape.swift`: 月の形状定義
- `CraterView.swift`: クレーター表示

**Stars/**
星の視覚効果コンポーネント
- `FlowingStarsView.swift`: 流れる星の表示
- `StaticStarsView.swift`: 静的な星の表示
- `DiamondStarsView.swift`: ダイヤモンド型の星
- `SparkleStarsView.swift`: きらめく星の表示

**Usagi/**
うさぎのコンポーネント
- `UsagiView_1.swift`: うさぎ表示1
- `UsagiView_2.swift`: うさぎ表示2

**Backgrounds/**
背景コンポーネント
- `BackgroundBlack.swift`: 黒背景
- `BackgroundBlue.swift`: 青背景
- `BackgroundLightPurple.swift`: 薄紫背景
- `BackgroundPurple.swift`: 紫背景
- `BackgroundGradientView.swift`: グラデーション背景

#### Foundation/
基盤となるユーティリティ群

**Formatters/**
- `DateFormatters.swift`: 日付フォーマッター
- `TimeFormatters.swift`: 時間フォーマッター

**Extensions/**
- `Color+Hex.swift`: カラー拡張（Hex対応）
- `View+SessionVisibility.swift`: セッション可視性拡張

**UIKitSupport/**
- `ViewModifiers.swift`: ビューモディファイア
- `GlitterTextModifier.swift`: きらめきテキスト効果
- `GearButtonToolbar.swift`: ギアボタンのツールバー
- `UIKitWrappers/SelectableTextView.swift`: 選択可能テキストビュー

#### Constants/
- `LayoutConstants.swift`: レイアウト定数

#### Resources/
リソースファイル群
- `gif/`: アニメーションGIFファイル
- `MoonMessage/`: 月のメッセージ関連

### テストディレクトリ

#### TsukiUsagiTests/
- `ContentViewTests.swift`: ContentViewのテスト
- `TsukiUsagiTests.swift`: 基本テスト

#### TsukiUsagiUITests/
- `TsukiUsagiUITests.swift`: UIテスト
- `TsukiUsagiUITestsLaunchTests.swift`: 起動テスト

### 特徴

1. **機能別分離**: Featuresディレクトリで機能ごとに整理
2. **コンポーネント化**: Visualディレクトリで再利用可能なUIコンポーネントを管理
3. **基盤分離**: Foundationディレクトリで共通ユーティリティを管理
4. **テスト対応**: 単体テストとUIテストを適切に分離
5. **リソース管理**: 画像やメッセージを専用ディレクトリで管理

この構造により、保守性と拡張性を両立した開発が可能です。