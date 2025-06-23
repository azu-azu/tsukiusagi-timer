# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── App/
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
│   │   └── RecordedTimesView.swift
│   ├── History/
│   │   ├── Views/
│   │   │   └── HistoryView.swift
│   │   ├── ViewModels/
│   │   │   └── HistoryViewModel.swift
│   │   ├── Stores/
│   │   │   └── HistoryStore.swift
│   │   └── Models/
│   └── Settings/
│       └── SettingsView.swift
│
├── Components/
│   ├── Visual/
│   │   ├── Moon/
│   │   ├── Stars/
│   │   ├── Usagi/
│   │   └── Backgrounds/
│   └── Common/
│       ├── Buttons/
│       ├── Modals/
│       ├── Indicators/
│       └── TextStyles/
│
├── Core/
│   ├── Formatters/
│   │   ├── DateFormatters.swift
│   │   └── TimeFormatters.swift
│   ├── Services/
│   │   └── AwakeEnablerView.swift
│   ├── Extensions/
│   │   └── Color+Hex.swift
│   └── UIKitSupport/
│       ├── ViewModifiers.swift
│       ├── GlitterTextModifier.swift
│       ├── GearButtonToolbar.swift
│       └── UIKitWrappers/
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
├── .gitignore
└── README.md
```

## 改善されたディレクトリ構造の説明

- テストディレクトリ（TsukiUsagiTests, TsukiUsagiUITests）は省略していますが、実体には存在します。
- その他の構成は現状と一致

### 主な変更点

- Resources配下は実際の構成（gif, MoonMessage）に修正
- Features/Timer, Features/Settingsは実際のファイル直置きに修正
- Features/TimerにTimerEditView.swift, TimerTextView.swift, RecordedTimesView.swiftを追加
- Features/History/Models/のSessionRecord.swiftを削除（実体にファイルなし）
- 存在しないFonts/Localization等の記載を削除
- その他、実際のディレクトリ・ファイル構成に合わせて調整

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