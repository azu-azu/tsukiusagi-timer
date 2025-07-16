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