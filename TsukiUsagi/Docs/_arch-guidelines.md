# TsukiUsagi アーキテクチャガイドライン

## 🏗️ ディレクトリ構造の判断基準

### **UI層の分類基準**

#### `GlobalComponents/` - 全アプリ共通UI
- **判断基準**: プロジェクト全体で5回以上使用される
- **例**: RoundedCard, KeyboardCloseButton, CommonHeaderView
- **禁止**: 特定機能に依存するロジックを含む

#### `CrossFeatureUI/` - 機能横断UI  
- **判断基準**: 2-4個の機能で使用される
- **例**: NavigationCardView, SideMenu, PlusMinusButton
- **特徴**: 機能横断的だが、特定用途に特化

#### `Features/*/Components/` - 機能専用UI
- **判断基準**: その機能内でのみ使用される
- **例**: TimerEditHeaderView, SessionRowView
- **特徴**: 高い凝集性、機能特化

### **ビジネスロジック層の分類基準**

#### `Foundation/Managers/` - グローバル管理
- **判断基準**: アプリ全体で使用される状態・ロジック
- **例**: SessionManager（全機能でセッション情報が必要）
- **責務**: アプリ横断的なデータ管理、設定管理

#### `Features/*/Services/` - 機能専用管理
- **判断基準**: その機能内でのみ使用される状態・ロジック  
- **例**: TimerPersistenceManager, HapticManager
- **責務**: 機能特化したビジネスロジック、外部連携

#### `Features/*/ViewModels/` - 画面状態管理
- **判断基準**: 特定画面・機能の状態管理
- **例**: TimerViewModel, HistoryViewModel
- **責務**: SwiftUIバインディング、画面ロジック

### **データ層の分類基準**

#### `Models/Core/` - アプリ共通モデル
- **判断基準**: 複数機能で共有されるデータ構造
- **例**: SessionEntry, SessionName
- **特徴**: アプリ全体の共通概念

#### `Features/*/Models/` - 機能専用モデル
- **判断基準**: その機能でのみ使用されるデータ構造
- **例**: PomodoroPhase, ActivityIntensity
- **特徴**: 機能固有のドメインモデル

### **アプリ固有UI層**

#### `Features/App/Components/` - アプリメイン画面専用
- **判断基準**: ContentViewでのみ使用される
- **例**: FooterBar, MainPanel  
- **責務**: アプリのメイン画面レイアウト

### **開発者ツール層**

#### `DeveloperTools/Debug/` - デバッグ・開発支援専用
- **判断基準**: 本番コードから完全に分離された開発支援機能
- **例**: PerformanceDebugView, AdaptiveViews
- **特徴**: 本番環境では除外、開発効率向上目的

## 🚦 判断フローチャート

### UI部品の配置判断
```
新しいUI部品を作成する時
↓
全アプリで使用する？ → YES → GlobalComponents/
↓ NO
2-4機能で使用する？ → YES → CrossFeatureUI/
↓ NO  
特定機能のみ？ → YES → Features/*/Components/
```

### ビジネスロジックの配置判断
```
新しいManager/Serviceを作成する時
↓
アプリ全体で必要？ → YES → Foundation/Managers/
↓ NO
機能特化している？ → YES → Features/*/Services/
↓
画面状態管理？ → YES → Features/*/ViewModels/
```

### モデルの配置判断
```
新しいModelを作成する時
↓
複数機能で使用？ → YES → Models/Core/
↓ NO
機能固有？ → YES → Features/*/Models/
```

## 🔄 将来の分離ポイント

### Settings機能の分離準備
- **SessionManagement機能**: 独立度★★★★★ (15ファイル)
  - 完全にセッション管理に特化
  - 他機能への依存が少ない
- **TimerSettings機能**: 独立度★★★★☆ (3ファイル)  
  - 時間設定に特化
  - Timer機能との結合度やや高

### 分離のタイミング
- **SessionManagement**: ファイル数が20を超えた時
- **TimerSettings**: 時間関連設定が5機能を超えた時

## 🚨 将来の肥大化リスクと対策

### Foundation/Managers の階層化指針
- **現状**: SessionManager関連ファイル4個
- **リスク**: `+`ファイル肥大化による可読性低下
- **対策**: 7ファイルを超えた場合は `Managers/Session/` に再分割
```
Foundation/Managers/Session/
├── SessionManager.swift
├── SessionManagerValidator.swift
├── Extensions/
│   ├── SessionManager+DescriptionManagement.swift
│   └── SessionManager+Preview.swift
└── ...
```

### CrossFeatureUI/Controls の粒度指針
- **現状**: 2ファイル（適正レベル）
- **リスク**: 汎用コントロールの無分別置き場化
- **対策**: 5ファイルを超えた場合は用途別階層化
```
CrossFeatureUI/Controls/
├── Buttons/         # ボタン系コントロール
├── Toggles/         # トグル系コントロール  
└── Modifiers/       # アニメーションモディファイア
```

### Timer/Services のカテゴリ分割指針
- **現状**: 8ファイル（既に肥大化）
- **リスク**: 新機能追加時の読み込みコスト高騰化
- **対策**: 機能群別に4カテゴリ分割を検討
```
Timer/Services/
├── Notifications/   # NotificationManager, PhaseNotificationService
├── Haptics/         # HapticManager, HapticService
├── Persistence/     # TimerPersistenceManager, SessionHistoryService
└── Core/           # TimerEngine, TimerAnimationManager
```

### 階層化の判断基準
- **5ファイル未満**: フラット構造を維持
- **5-10ファイル**: カテゴリ分割を検討
- **10ファイル超**: 階層化実施を推奨

## 🛡️ アンチパターン

### 避けるべき配置
- ❌ `GlobalComponents/`に機能特化コンポーネント
- ❌ `Foundation/Managers/`に機能専用ロジック
- ❌ `Models/Core/`に機能固有モデル
- ❌ `Features/*/`にアプリ全体で使用するもの
- ❌ `Foundation/`にデバッグ・開発専用コード

### 禁止事項  
- 循環依存の作成
- Foundation層からFeatures層への依存
- 機能間の直接依存（CrossFeatureUIを経由する）
- **Entry/の複数作成**: アプリエントリポイントはトップレベル1箇所のみ
- **ContentView肥大化**: メイン画面ロジックはFeatures/App/に分離

## 🏠 トップレベルディレクトリの特別ルール

### Entry/ ディレクトリ
- **役割**: アプリケーションのエントリポイントのみ
- **内容**: TsukiUsagiApp.swift, AppDelegate.swift, ContentView.swift
- **禁止**: Features/*/Entry/ のようなサブEntryの作成
- **理由**: エントリポイントの分散を防止し、アプリ起動フローを一元化
- **ContentView責務**: 最小限のルーティング・レイアウトのみ
- **肥大化対策**: メイン画面ロジックは Features/App/ に分離

### Foundation/ ディレクトリ
- **役割**: アプリ全体で使用される基盤機能
- **特徴**: Features層に依存しない、高い再利用性
- **例**: Managers, Extensions, Formatters, UIKitSupport

### DeveloperTools/ ディレクトリ
- **役割**: 開発・デバッグ支援機能の完全分離
- **内容**: Debug/, Profiling/, Testing/ など
- **特徴**: 本番コードとの明確な境界、条件付きコンパイル対応
- **利点**: 本番環境でのコード除外、開発効率向上

## 📖 命名規則

### ディレクトリ命名
- **単数形**: Models, Foundation
- **複数形**: Features, GlobalComponents  
- **目的明確**: CrossFeatureUI, UIKitSupport

### ファイル命名
- **Manager**: グローバル状態管理 (SessionManager)
- **Service**: 機能特化サービス (HapticService)
- **ViewModel**: 画面状態管理 (TimerViewModel)
- **View**: UI部品 (RoundedCard)
- **Engine**: 機能特化エンジン (AdaptiveAnimationEngine)

## 🎨 Visual層のリソース分離

### コードベース vs アセットベースの使い分け

#### `Visual/Backgrounds/` - コードベース背景
- **用途**: SwiftUIでプロシージャルに生成される背景
- **例**: GalaxyBackground, BackgroundGradientView
- **特徴**: アニメーション、グラデーション、動的生成

#### `Assets.xcassets/` - アセットベース背景  
- **用途**: 静的な背景画像ファイル
- **例**: background_night.imageset, wallpaper_moon.imageset
- **特徴**: PNG/JPGファイル、静的表示、ファイルサイズ重視

#### `Resources/` - その他リソース
- **用途**: GIFアニメーション、フォントなど
- **例**: star_animation.gif、custom_fonts/
- **特徴**: 特殊フォーマット、外部リソース

### 判断フローチャート
```
新しい背景を追加する時
↓
アニメーションや動的生成？ → YES → Visual/Backgrounds/
↓ NO
静的な背景画像？ → YES → Assets.xcassets/
↓ NO  
特殊フォーマット？ → YES → Resources/
```

この構造により、開発者の判断迷いを最小化し、長期的な保守性を確保します。