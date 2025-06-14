# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── Views/
│   ├── Timer/
│   │   └── TimerPanel.swift
│   ├── Settings/
│   │   ├── Toolbar.swift
│   │   └── View.swift
│   ├── UsagiView_1.swift
│   ├── MoonView.swift
│   ├── ContentView.swift
│   ├── BackgroundGradientView.swift
│   └── UsagiView.swift
│
├── Assets.xcassets/
│   ├── Contents.json
│   ├── usagi_1.imageset/
│   ├── usagi_2.imageset/
│   ├── AppIcon.appiconset/
│   └── AccentColor.colorset/
│
├── ViewModels/
│   ├── TimerViewModel.swift
│   └── HistoryViewModel.swift
│
├── Models/
│   └── PomodoroPhase.swift
│
├── Managers/
│   ├── NotificationManager.swift
│   └── HistoryStore.swift
│
├── Extensions/
│   └── Color+Hex.swift
│
└── TsukiUsagiApp.swift
```

## ディレクトリ構造の説明

### Views/
- メインのビューコンポーネント
  - `ContentView.swift`: メインビュー
  - `MoonView.swift`: 月の表示用ビュー
  - `UsagiView.swift`, `UsagiView_1.swift`: うさぎの表示用ビュー
  - `BackgroundGradientView.swift`: 背景グラデーション用ビュー
- 機能別サブディレクトリ
  - `Timer/`: タイマー機能関連のビュー
    - `TimerPanel.swift`: タイマーパネル表示用ビュー
  - `Settings/`: 設定画面関連のビュー
    - `Toolbar.swift`: ツールバー表示用ビュー
    - `View.swift`: 設定画面のメインビュー

### Assets.xcassets/
- アプリケーションのアセット管理
  - `AppIcon.appiconset/`: アプリケーションアイコン
  - `usagi_1.imageset/`, `usagi_2.imageset/`: うさぎの画像アセット
  - `AccentColor.colorset/`: アクセントカラー設定
  - `Contents.json`: アセットカタログの設定ファイル

### ViewModels/
- ビジネスロジックの管理
  - `TimerViewModel.swift`: タイマー機能のビジネスロジック
  - `HistoryViewModel.swift`: セッション履歴の管理と表示

### Models/
- データモデルの定義
  - `PomodoroPhase.swift`: ポモドーロタイマーのフェーズ（集中/休憩）を管理する列挙型

### Managers/
- アプリケーション全体で使用される機能の管理
  - `NotificationManager.swift`: 通知機能を管理するシングルトンクラス
  - `HistoryStore.swift`: セッション履歴の永続化を担当

### Extensions/
- Swift標準型の拡張機能
  - `Color+Hex.swift`: カラー関連の拡張機能

### TsukiUsagiApp.swift
- アプリケーションのエントリーポイント
- アプリケーションの初期化と設定を担当