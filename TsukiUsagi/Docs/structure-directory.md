# TsukiUsagi プロジェクト構造

```
TsukiUsagi/
├── build/                                   # Xcode ビルド成果物（ローカル）
├── CLAUDE.md                                # リポジトリ作業ガイド
├── docs/                                    # プロジェクトドキュメント
│   ├── _arch-guidelines.md
│   ├── trouble-cursor-swift.md
│   ├── structure-directory.md               # 本ファイル
│   ├── _guide-font.md
│   ├── _guide-font-installation.md
│   ├── lint_exceptions.md
│   ├── README.md
│   ├── structure-guidelines.md
│   └── plan-todo-refactor.md
├── README.md                                # ルート README
├── scripts/
│   └── replace_fonts.sh
├── tools/
│   └── swiftlint_ast_font_check.swift
├── TsukiUsagi/                              # アプリ本体
│   ├── Assets.xcassets/                     # 画像・色アセット
│   │   ├── AccentColor.colorset/
│   │   ├── AppIcon.appiconset/
│   │   ├── moonCardBG.colorset/
│   │   ├── moonTextMuted.colorset/
│   │   ├── moonTextPrimary.colorset/
│   │   ├── moonTextSecondary.colorset/
│   │   ├── usagi_1.imageset/
│   │   └── usagi_2.imageset/
│   ├── CrossFeatureUI/                      # 機能横断 UI
│   │   ├── Cards/
│   │   │   ├── CardContainer.swift
│   │   │   ├── NavigationCardView.swift
│   │   │   └── TotalCard.swift
│   │   ├── Controls/
│   │   │   ├── PencilIcon.swift
│   │   │   ├── PlusMinusButton.swift
│   │   │   ├── SessionLabelSection.swift
│   │   │   └── StartPulseAnimationModifier.swift
│   │   └── Navigation/
│   │       ├── HamburgerMenuButton.swift
│   │       ├── NavigationBackModifier.swift
│   │       ├── NavigationCardView.swift
│   │       └── SideMenu/
│   │           ├── SideMenuDurationView.swift
│   │           └── SideMenuView.swift
│   ├── DeveloperTools/
│   │   └── Debug/
│   │       ├── PerformanceDebugView.swift
│   │       └── DebugTestView.swift
│   ├── Entry/                               # アプリエントリポイント
│   │   ├── AppDelegate.swift
│   │   ├── ContentView.swift
│   │   └── TsukiUsagiApp.swift
│   ├── Features/
│   │   ├── App/
│   │   │   └── Components/
│   │   │       ├── FooterBar.swift
│   │   │       └── MainPanel.swift
│   │   ├── History/
│   │   │   ├── Helpers/
│   │   │   ├── Models/
│   │   │   │   ├── ActivityIntensity.swift
│   │   │   │   ├── DailyHistory.swift
│   │   │   │   └── Month.swift              # 新規追加：TabView用の安定ID管理
│   │   │   ├── Services/
│   │   │   ├── ViewModels/
│   │   │   └── Views/
│   │   │       ├── CalendarDayCell.swift
│   │   │       ├── CalendarHistoryView.swift
│   │   │       ├── DailyDetailView.swift
│   │   │       ├── DailyTimelineView.swift
│   │   │       ├── HistoryContainerView.swift
│   │   │       ├── HistoryDailyView.swift
│   │   │       ├── HistoryMonthlyView.swift # 更新：Month モデル使用
│   │   │       ├── HistoryView.swift
│   │   │       └── MemoEditView.swift
│   │   ├── Settings/
│   │   │   ├── Components/                       # 再利用 UI
│   │   │   │   ├── Sessions/
│   │   │   │   │   ├── Descriptions/
│   │   │   │   │   │   └── SessionDescriptionsView.swift
│   │   │   │   │   ├── Forms/
│   │   │   │   │   │   ├── SessionNameCustomInputView.swift
│   │   │   │   │   │   └── SessionNameSelectionView.swift
│   │   │   │   │   ├── Management/
│   │   │   │   │   │   └── EmbeddedSessionManagementView.swift   # 更新：UI改善
│   │   │   │   │   ├── Rows/
│   │   │   │   │   │   ├── SessionRowDisplayView.swift
│   │   │   │   │   │   ├── SessionRowEditingView.swift
│   │   │   │   │   │   └── SessionRowView.swift
│   │   │   │   │   └── SettingsHeaderView.swift
│   │   │   ├── Screens/                          # 画面（Screen）
│   │   │   │   ├── NewSessionFormView.swift      # 新規作成シート
│   │   │   │   ├── SessionEditView.swift         # 編集画面
│   │   │   │   └── SessionManagementView.swift   # 更新：UI改善
│   │   │   ├── Sections/
│   │   │   │   ├── Duration/
│   │   │   │   │   ├── DurationHelpers.swift
│   │   │   │   │   └── DurationSessionSettingsView.swift
│   │   │   │   ├── Notification/                  # 新規追加
│   │   │   │   │   └── NotificationSettingsView.swift
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
│   │   │   ├── DevOnly/                          # 開発専用機能
│   │   │   │   ├── AchievementsView.swift
│   │   │   │   ├── AchievementManager.swift
│   │   │   │   ├── ShareManager.swift
│   │   │   │   ├── SmartNotificationManager.swift
│   │   │   │   ├── SmartNotificationToggleView.swift
│   │   │   │   ├── StreakView.swift
│   │   │   │   ├── TotalStreakSectionView.swift
│   │   │   │   ├── WeeklyUsageSectionView.swift
│   │   │   │   └── XPManager.swift
│   │   │   ├── Manager/
│   │   │   │   └── StreakManager.swift
│   │   │   └── Views/
│   │   │       ├── Components/
│   │   │       │   └── DayCircleView.swift
│   │   │       ├── Screens/
│   │   │       └── Sections/
│   │   │           └── WeeklyCalendarSectionView.swift
│   │   └── Timer/
│   │       ├── Components/
│   │       │   └── TimerEditHeaderView.swift
│   │       ├── Models/
│   │       │   └── PomodoroPhase.swift
│   │       ├── Services/
│   │       ├── ViewModels/
│   │       │   ├── TimerSessionManager.swift
│   │       │   ├── TimerStateManager.swift
│   │       │   └── TimerViewModel.swift
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
│   │   ├── Utilities/
│   │   └── Validators/
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
│   ├── NotificationAndHistorySpiesTests.swift
│   ├── SimpleSubtitleTest.swift
│   ├── TimerPersistenceTests.swift
│   ├── TimerViewModelTests.swift
│   ├── TimerViewModelTransitionsTests.swift
│   └── TsukiUsagiTests.swift
└── TsukiUsagiUITests/
    ├── TsukiUsagiUITests.swift
    └── TsukiUsagiUITestsLaunchTests.swift
```

## メモ
- 本ドキュメントは実際のリポジトリ構造に同期済みです（最終更新: 2025-10-01）。
- Settings の新規作成シートは `NewSessionFormView` を使用し、Edit 画面は `SessionEditView` です。
- Foundation 層は `DesignTokens` と拡張系ユーティリティを中核に、UIKit 連携は `UIKitSupport` 配下に整理されています。
- History 機能に `Month.swift` モデルを追加し、TabView の安定したページ管理を実現しています。
- Streak 機能は開発専用機能を `DevOnly` ディレクトリに分離しています。
- 全148個のSwiftファイルで構成されています。