# TsukiUsagi プロジェクト構造

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
│           ├── UsagiView_1.swift
│           └── UsagiView_2.swift
├── Constants/
│   └── LayoutConstants.swift
├── Entry/
│   ├── Components/
│   │   ├── FooterBar.swift
│   │   └── MainPanel.swift
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   └── TsukiUsagiApp.swift
├── Features/
│   ├── History/
│   │   ├── Stores/
│   │   │   └── HistoryStore.swift
│   │   ├── ViewModels/
│   │   │   └── HistoryViewModel.swift
│   │   └── Views/
│   │       └── HistoryView.swift
│   ├── Settings/
│   │   ├── BreakTimeSectionView.swift
│   │   ├── ManageSessionNamesSectionView.swift
│   │   ├── NewSessionFormView.swift
│   │   ├── ResetStopSectionView.swift
│   │   ├── SessionListSectionView.swift
│   │   ├── SessionNameManagerView.swift
│   │   ├── SessionRowView.swift
│   │   ├── SettingsHeaderView.swift
│   │   ├── SettingsView.swift
│   │   ├── ViewHistorySectionView.swift
│   │   └── WorkTimeSectionView.swift
│   ├── Shared/
│   │   ├── SessionLabelSection.swift
│   │   ├── SessionManager.swift
│   │   ├── SessionManagerV2.swift
│   │   └── TimeFormatting.swift
│   └── Timer/
│       ├── HapticManager.swift
│       ├── HapticService.swift
│       ├── NotificationManager.swift
│       ├── PhaseNotificationService.swift
│       ├── PomodoroPhase.swift
│       ├── RecordedTimesView.swift
│       ├── SessionHistoryService.swift
│       ├── StartPulseAnimationModifier.swift
│       ├── TimeFormatterUtil.swift
│       ├── TimerAnimationManager.swift
│       ├── TimerEditView.swift
│       ├── TimerEngine.swift
│       ├── TimerPanel.swift
│       ├── TimerPersistenceManager.swift
│       ├── TimerSessionManager.swift
│       ├── TimerStateManager.swift
│       ├── TimerTextView.swift
│       └── TimerViewModel.swift
├── Foundation/
│   ├── Components/
│   │   ├── HiddenKeyboardWarner.swift
│   │   ├── OptimizedStarBackground.swift
│   │   ├── PlusMinusButton.swift
│   │   ├── RoundedCard.swift
│   │   └── TotalCard.swift
│   ├── Extensions/
│   │   ├── Array+Safe.swift
│   │   ├── Color+Hex.swift
│   │   ├── String+Trimmed.swift
│   │   └── View+SessionVisibility.swift
│   └── Formatters/
│       ├── DateFormatters.swift
│       └── TimeFormatters.swift
├── UIKitSupport/
│   ├── UIKitWrappers/
│   │   ├── SelectableTextView.swift
│   │   ├── GearButtonToolbar.swift
│   │   ├── GlitterTextModifier.swift
│   │   ├── GradientGlitterTextModifier.swift
│   │   └── ViewModifiers.swift
│   ├── AccessibilityIDs.swift
│   ├── AwakeEnablerView.swift
│   ├── DesignTokens.swift
│   ├── FeatureFlags.swift
│   └── PreviewData.swift
├── Models/
│   ├── SessionEntry.swift
│   ├── SessionItem.swift
│   └── SessionName.swift
└── Resources/
    ├── gif/
    └── MoonMessage/
        └── MoonMessage.swift
```