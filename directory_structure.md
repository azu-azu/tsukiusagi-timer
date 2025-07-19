# TsukiUsagi プロジェクト構造（最新版）

```
TsukiUsagi/
├── Assets.xcassets
├── Components/
│   └── Visual/
│       ├── Backgrounds/
│       │   ├── BackgroundBlack.swift
│       │   ├── BackgroundBlue.swift
│       │   ├── BackgroundGradientView.swift
│       │   ├── BackgroundLightPurple.swift
│       │   └── BackgroundPurple.swift
│       ├── Moon/
│       │   ├── CraterView.swift
│       │   ├── MoonShadow.swift
│       │   ├── MoonShape.swift
│       │   ├── MoonView.swift
│       │   └── QuietMoonView.swift
│       ├── Stars/
│       │   ├── DiamondStarsView.swift
│       │   ├── FlowingStarsView.swift
│       │   ├── SparkleStarsView.swift
│       │   └── StaticStarsView.swift
│       └── Usagi/
│           ├── MoonUsagiView.swift
│           └── JumpingUsagiView.swift
├── Entry/
│   ├── Components/
│   │   ├── FooterBar.swift
│   │   └── MainPanel.swift
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   └── TsukiUsagiApp.swift
├── Features/
│   ├── Common/
│   │   └── SessionLabelSection.swift
│   ├── History/
│   │   ├── Stores/
│   │   │   └── HistoryStore.swift
│   │   ├── ViewModels/
│   │   │   └── HistoryViewModel.swift
│   │   └── Views/
│   │       └── HistoryView.swift
│   ├── Settings/
│   │   ├── Screens/
│   │   │   ├── SettingsView.swift
│   │   │   └── SessionNameManagerView.swift
│   │   ├── Sections/
│   │   │   ├── WorkTimeSectionView.swift
│   │   │   ├── BreakTimeSectionView.swift
│   │   │   ├── ResetStopSectionView.swift
│   │   │   ├── ViewHistorySectionView.swift
│   │   │   ├── ManageSessionNamesSectionView.swift
│   │   │   └── SessionListSectionView.swift
│   │   ├── Components/
│   │   │   ├── SessionRowView.swift
│   │   │   └── SettingsHeaderView.swift
│   │   └── Forms/
│   │       └── NewSessionFormView.swift
│   └── Timer/
│       ├── Views/
│       │   ├── RecordedTimesView.swift
│       │   ├── TimerEditView.swift
│       │   ├── TimerPanel.swift
│       │   └── TimerTextView.swift
│       ├── ViewModels/
│       │   ├── TimerViewModel.swift
│       │   ├── TimerStateManager.swift
│       │   └── TimerSessionManager.swift
│       ├── Engine/
│       │   ├── TimerEngine.swift
│       │   └── TimerPersistenceManager.swift
│       ├── Services/
│       │   ├── NotificationManager.swift
│       │   ├── PhaseNotificationService.swift
│       │   ├── SessionHistoryService.swift
│       │   └── HapticService.swift
│       ├── Managers/
│       │   ├── HapticManager.swift
│       │   └── TimerAnimationManager.swift
│       ├── Modifiers/
│       │   └── StartPulseAnimationModifier.swift
│       ├── Utils/
│       │   └── TimeFormatterUtil.swift
│       └── Models/
│           └── PomodoroPhase.swift
├── Foundation/
│   ├── Components/
│   │   ├── HiddenKeyboardWarmer.swift
│   │   ├── OptimizedStarBackground.swift
│   │   ├── PlusMinusButton.swift
│   │   ├── RoundedCard.swift
│   │   └── TotalCard.swift
│   ├── Constants/
│   │   └── AppConstants.swift
│   ├── Extensions/
│   │   ├── Array+Safe.swift
│   │   ├── Color+Hex.swift
│   │   ├── String+Trimmed.swift
│   │   └── View+SessionVisibility.swift
│   ├── Managers/
│   │   ├── SessionManager.swift
│   │   └── SessionManagerV2.swift
│   ├── Utilities/
│   │   └── TimeFormatting.swift
│   ├── AccessibilityIDs.swift
│   ├── AwakeEnablerView.swift
│   ├── DesignTokens.swift
│   ├── FeatureFlags.swift
│   ├── PreviewData.swift
│   └── Formatters/
│       ├── DateFormatters.swift
│       └── TimeFormatters.swift
├── UIKitSupport/
│   ├── UIKitWrappers/
│   │   └── SelectableTextView.swift
│   ├── GearButtonToolbar.swift
│   ├── GlitterTextModifier.swift
│   ├── GradientGlitterTextModifier.swift
│   └── ViewModifiers.swift
├── Models/
│   ├── SessionEntry.swift
│   ├── SessionItem.swift
│   ├── SessionName.swift
│   └── MoonMessage.swift
└── Resources/
    ├── gif/
    └── MoonMessage/
        └── MoonMessage.swift