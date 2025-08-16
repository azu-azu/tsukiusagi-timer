# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── build/                                   # Xcode ビルド成果物（ローカル）
├── CLAUDE.md                                # リポジトリ作業ガイド
├── docs/                                    # プロジェクトドキュメント
│   ├── ARCHITECTURE_GUIDELINES.md
│   ├── cursor_swift_troubleshooting.md
│   ├── directory_structure.md               # 本ファイル
│   ├── font_guidelines.md
│   ├── font_installation_guide.md
│   ├── lint_exceptions.md
│   ├── README.md
│   ├── structure-guidelines.md
│   └── todo_refactor_plan.md
├── README.md                                # ルート README
├── scripts/
│   └── setup.sh
├── tools/
│   └── swiftlint_ast_font_check.swift
├── TsukiUsagi/                              # アプリ本体
│   ├── Assets.xcassets/                     # 画像・色アセット
│   ├── CrossFeatureUI/                      # 機能横断 UI
│   │   ├── Cards/
│   │   │   ├── CardContainer.swift
│   │   │   ├── NavigationCardView.swift
│   │   │   └── TotalCard.swift
│   │   ├── Controls/
│   │   │   ├── PlusMinusButton.swift
│   │   │   └── StartPulseAnimationModifier.swift
│   │   └── Navigation/
│   │       ├── HamburgerMenuButton.swift
│   │       ├── NavigationBackModifier.swift
│   │       └── SideMenu/
│   │           ├── SideMenuDurationView.swift
│   │           └── SideMenuView.swift
│   ├── DeveloperTools/
│   │   └── Debug/
│   │       └── PerformanceDebugView.swift
│   ├── Entry/                               # アプリエントリポイント
│   │   ├── AppDelegate.swift
│   │   ├── ContentView.swift
│   │   └── TsukiUsagiApp.swift
│   ├── Features/
│   │   ├── App/
│   │   │   └── Components/
│   │   │       └── FooterBar.swift
│   │   ├── Common/
│   │   │   └── SessionLabelSection.swift
│   │   ├── History/
│   │   │   ├── Helpers/
│   │   │   ├── Models/
│   │   │   ├── Services/
│   │   │   ├── ViewModels/
│   │   │   └── Views/
│   │   │       ├── CalendarHistoryView.swift
│   │   │       ├── DailyDetailView.swift
│   │   │       ├── DailyTimelineView.swift
│   │   │       └── HistoryView.swift
│   │   ├── Settings/
│   │   │   ├── Components/                       # 再利用 UI
│   │   │   │   ├── Sessions/
│   │   │   │   │   ├── Descriptions/
│   │   │   │   │   │   └── SessionDescriptionsView.swift
│   │   │   │   │   ├── Forms/
│   │   │   │   │   │   ├── SessionNameCustomInputView.swift
│   │   │   │   │   │   └── SessionNameSelectionView.swift
│   │   │   │   │   ├── Rows/
│   │   │   │   │   │   ├── SessionRowDisplayView.swift
│   │   │   │   │   │   ├── SessionRowEditingView.swift
│   │   │   │   │   │   └── SessionRowView.swift
│   │   │   │   │   └── EmbeddedSessionManagementView.swift
│   │   │   │   └── SettingsHeaderView.swift
│   │   │   ├── Screens/                          # 画面（Screen）
│   │   │   │   ├── NewSessionFormView.swift      # 新規作成シート
│   │   │   │   ├── SessionEditView.swift         # 編集画面
│   │   │   │   └── SessionManagementView.swift   # 一覧・管理画面
│   │   │   ├── Sections/
│   │   │   │   ├── Duration/
│   │   │   │   │   ├── DurationHelpers.swift
│   │   │   │   │   └── DurationSessionSettingsView.swift
│   │   │   │   ├── ResetStop/
│   │   │   │   │   └── ResetStopSectionView.swift
│   │   │   │   ├── SubtitleEdit/
│   │   │   │   │   ├── DescriptionEditContent.swift
│   │   │   │   │   ├── FullSessionEditContent.swift
│   │   │   │   │   ├── SessionEditModal+Preview.swift
│   │   │   │   │   └── SubtitleEditModels.swift
│   │   │   │   └── ViewHistory/
│   │   │   │       └── ViewHistorySectionView.swift
│   │   │   └── SheetBuilders/
│   │   │       └── SessionEditSheetBuilder.swift
│   │   ├── Streak/
│   │   │   ├── Manager/
│   │   │   └── Views/
│   │   │       ├── AchievementsView.swift
│   │   │       ├── Components/
│   │   │       ├── Screens/
│   │   │       └── Sections/
│   │   └── Timer/
│   │       ├── Components/
│   │       ├── Models/
│   │       ├── Services/
│   │       ├── ViewModels/
│   │       └── Views/
│   │           ├── RecordedTimesView.swift
│   │           ├── TimerEditView.swift
│   │           ├── TimerPanel.swift
│   │           └── TimerTextView.swift
│   ├── Foundation/
│   │   ├── AccessibilityIDs.swift
│   │   ├── Animation/
│   │   ├── Constants/
│   │   │   └── AppConstants.swift
│   │   ├── DesignTokens.swift
│   │   ├── Extensions/
│   │   │   ├── Array+Safe.swift
│   │   │   ├── Color+Hex.swift
│   │   │   ├── Date+Streak.swift
│   │   │   ├── String+Trimmed.swift
│   │   │   ├── View+Debug.swift
│   │   │   ├── View+Debug+Dynamic.swift
│   │   │   ├── View+Debug+Hierarchical.swift
│   │   │   ├── View+Debug+Menu.swift
│   │   │   ├── View+Keyboard.swift
│   │   │   └── View+SessionVisibility.swift
│   │   ├── FeatureFlags.swift
│   │   ├── Formatters/
│   │   │   ├── DateFormatters.swift
│   │   │   ├── FormatterConstants.swift
│   │   │   ├── TimeFormatters.swift
│   │   │   └── TimeFormattingProtocols.swift
│   │   ├── Managers/
│   │   │   ├── SessionManager.swift
│   │   │   └── SessionManagerValidator.swift
│   │   ├── PreviewData.swift
│   │   ├── UIKitSupport/
│   │   │   ├── Modifiers/
│   │   │   │   ├── GlitterTextModifier.swift
│   │   │   │   ├── GradientGlitterTextModifier.swift
│   │   │   │   └── ViewModifiers.swift
│   │   │   ├── Toolbars/
│   │   │   │   └── GearButtonToolbar.swift
│   │   │   └── Wrappers/
│   │   │       └── SelectableTextView.swift
│   │   ├── Validators/
│   │   │   └── (各種バリデータ定義)
│   │   └── (他、Foundation 配下の補助モジュール)
│   ├── GlobalComponents/
│   │   ├── Buttons/
│   │   │   └── KeyboardCloseButton.swift
│   │   ├── Headers/
│   │   │   ├── CommonHeaderView.swift
│   │   │   └── HeaderConfiguration.swift
│   │   ├── Modals/
│   │   │   └── EditableModal.swift
│   │   ├── System/
│   │   │   └── AwakeEnablerView.swift
│   │   └── RoundedCard.swift
│   ├── Models/
│   │   └── Core/
│   │       ├── MoonMessage.swift
│   │       ├── SessionEntry.swift
│   │       ├── SessionItem.swift
│   │       └── SessionName.swift
│   ├── Resources/
│   │   ├── en.lproj/
│   │   │   ├── Localizable.strings
│   │   │   └── Localizable.stringsdict
│   │   ├── ja.lproj/
│   │   │   ├── Localizable.strings
│   │   │   └── Localizable.stringsdict
│   │   ├── Fonts/
│   │   │   ├── Nunito-Bold.ttf
│   │   │   ├── Nunito-Italic.ttf
│   │   │   ├── Nunito-Medium.ttf
│   │   │   └── Nunito-Regular.ttf
│   │   └── Gifs/
│   │       ├── black_red.gif
│   │       ├── black_yellow.gif
│   │       ├── blue.gif
│   │       └── gold.gif
│   └── Visual/                              # テーマ特化視覚要素
│       ├── Backgrounds/
│       ├── Moons/
│       ├── Stars/
│       └── Usagis/
├── TsukiUsagi.xcodeproj/
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   │   └── contents.xcworkspacedata
│   └── Package.resolved
├── TsukiUsagiTests/
│   ├── ContentViewTests.swift
│   ├── DailyHistoryTests.swift
│   ├── DebugTestView.swift
│   ├── FontTestHelpers.swift
│   ├── FontTestView.swift
│   ├── SimpleSubtitleTest.swift
│   └── TsukiUsagiTests.swift
└── TsukiUsagiUITests/
    ├── TsukiUsagiUITests.swift
    └── TsukiUsagiUITestsLaunchTests.swift
```

## メモ
- 本ドキュメントは実際のリポジトリ構造に同期済みです（最終更新: 自動化ツールにより最新コミット時点）。
- Settings の新規作成シートは `NewSessionFormView` を使用し、Edit 画面は `SessionEditView` です。
- Foundation 層は `DesignTokens` と拡張系ユーティリティを中核に、UIKit 連携は `UIKitSupport` 配下に整理されています。
