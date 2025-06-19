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
│   │   │   ├── Views/
│   │   │   │   └── TimerPanel.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── TimerViewModel.swift
│   │   │   ├── Services/
│   │   │   │   └── NotificationManager.swift
│   │   │   └── Models/
│   │   │       └── PomodoroPhase.swift
│   │   │
│   │   ├── History/
│   │   │   ├── Views/
│   │   │   │   └── HistoryView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── HistoryViewModel.swift
│   │   │   ├── Services/
│   │   │   │   └── HistoryStore.swift
│   │   │   └── Models/
│   │   │       └── SessionRecord.swift
│   │   │
│   │   └── Settings/
│   │       ├── Views/
│   │       │   └── SettingsView.swift
│   │       ├── ViewModels/
│   │       │   └── SettingsViewModel.swift
│   │       └── Models/
│   │           └── AppSettings.swift
│   │
│   ├── Components/
│   │   ├── Visual/
│   │   │   ├── Moon/
│   │   │   ├── Stars/
│   │   │   ├── Usagi/
│   │   │   └── Backgrounds/
│   │   │
│   │   └── Common/
│   │       ├── Buttons/
│   │       ├── Modals/
│   │       ├── Indicators/
│   │       └── TextStyles/
│   │
│   ├── Views/
│   │   ├── Moon/
│   │   │   ├── MoonView.swift
│   │   │   ├── MoonShape.swift
│   │   │   ├── MoonShadow.swift
│   │   │   └── CraterView.swift
│   │   │
│   │   ├── Backgrounds/
│   │   │   ├── BackgroundGradientView.swift
│   │   │   ├── BackgroundBlack.swift
│   │   │   ├── BackgroundLightPurple.swift
│   │   │   ├── BackgroundPurple.swift
│   │   │   └── BackgroundBlue.swift
│   │   │
│   │   ├── StarView.swift
│   │   ├── DiamondStarsView.swift
│   │   ├── SparkleStarsView.swift
│   │   ├── UsagiView_1.swift
│   │   └── UsagiView_2.swift
│   │
│   ├── Core/
│   │   ├── Services/
│   │   │   └── AwakeEnablerView.swift
│   │   └── Utilities/
│   │       └── AppFormatters.swift
│   │
│   ├── UI/
│   │   ├── ViewModifiers.swift
│   │   ├── GearButtonToolbar.swift
│   │   └── Styles/
│   │       ├── ColorTheme.swift
│   │       └── Typography.swift
│   │
│   ├── Resources/
│   │   ├── Animations/
│   │   │   ├── gold.gif
│   │   │   ├── black_yellow.gif
│   │   │   ├── black_red.gif
│   │   │   └── blue.gif
│   │   ├── Fonts/
│   │   │   └── CustomFonts.swift
│   │   └── Localization/
│   │       └── Localizable.strings
│   │
│   ├── Assets.xcassets/
│   │
│   └── Extensions/
│       ├── Color+Hex.swift
│       ├── View+Extensions.swift
│       └── Date+Extensions.swift
│
├── TsukiUsagi.xcodeproj/
├── TsukiUsagiTests/
│   ├── Features/
│   │   ├── TimerTests/
│   │   ├── HistoryTests/
│   │   └── SettingsTests/
│   ├── Components/
│   └── Core/
├── TsukiUsagiUITests/
├── .build/
├── Package.resolved
├── README.md
└── .gitignore
```

## 改善されたディレクトリ構造の説明

### 主な変更点

#### 1. **新規追加されたフォルダ構造**
- `Components/`: 新しいコンポーネント構造
  - `Visual/`: アプリ世界観を彩る専用コンポーネント（空フォルダ）
    - `Moon/`
    - `Stars/`
    - `Usagi/`
    - `Backgrounds/`
  - `Common/`: 汎用 UI（空フォルダ）
    - `Buttons/`
    - `Modals/`
    - `Indicators/`
    - `TextStyles/`

#### 2. **既存のコンポーネント（現在の場所）**
- `Views/`: 現在のビューコンポーネント
  - `Moon/`: 月関連のコンポーネント
  - `Backgrounds/`: 背景関連のコンポーネント
  - 星関連のコンポーネント（直下）
  - うさぎ関連のコンポーネント（直下）

#### 3. **Features ディレクトリの統一**
各機能（Timer, History, Settings）で以下の構造を統一：
- `Views/`: ビューコンポーネント
- `ViewModels/`: ビジネスロジック
- `Services/`: データアクセス・外部サービス
- `Models/`: データモデル

#### 4. **Core ディレクトリの拡張**
- `Services/`: アプリケーション全体で使用されるサービス
- `Utilities/`: ユーティリティクラス

#### 5. **UI ディレクトリの改善**
- `Styles/`: デザインシステム関連
- 共通のUIコンポーネントを整理

#### 6. **Resources ディレクトリの整理**
- `Animations/`: GIFファイル
- `Fonts/`: フォント関連
- `Localization/`: 多言語対応

#### 7. **Extensions ディレクトリの拡張**
- 機能別に拡張を整理

#### 8. **テスト構造の改善**
- 機能別にテストを整理

### 命名規則の改善

#### Before:
- `UsagiView_1.swift`, `UsagiView_2.swift`

#### After:
- `UsagiView.swift`, `UsagiSleepingView.swift`, `UsagiAnimations.swift`

### メリット

1. **一貫性**: 各機能で同じディレクトリ構造を使用
2. **保守性**: 関連するファイルが近くに配置
3. **拡張性**: 新しい機能を追加しやすい構造
4. **可読性**: ファイル名が機能を明確に表現
5. **テスト容易性**: テストも機能別に整理

この構造により、プロジェクトの成長に合わせて効率的に開発を進めることができます。