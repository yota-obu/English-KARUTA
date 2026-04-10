# 英単語かるた - English Vocabulary Karuta

英単語と日本語訳をマッチングして語彙力を鍛える、iOS向けカードゲームアプリです。
CEFR（ヨーロッパ言語共通参照枠）に基づいた4段階の難易度と、2つのゲームモードで楽しめます。

## 特徴

- **マッチング形式のカードゲーム** — 英語カードと日本語カードをペアで選んで正解を目指す
- **2つのゲームモード** — 「1 Minute Challenge」と「Time Attack」
- **CEFRレベル対応（A1〜B2）** — 4段階の難易度
- **2つのプレイモード** — レベル別の Basic モードと、カテゴリ別の Category モード（Rank A/B）
- **スコアリングシステム** — スピードボーナス・連続正解ストリークによる倍率アップ
- **間違えた問題の復習機能** — 不正解の単語を保存し、例文付きで復習できる
- **プレイ履歴・ベストスコア** — 過去のゲーム結果を記録、レベル/モードごとのベスト記録を表示
- **サウンド＆触覚フィードバック** — 正解・不正解・コンボ・カウントダウン等に対応
- **ライトテーマ UI** — Periwinkle / Lavender / Indigo を基調としたカラーパレット
- **設定機能** — プライバシーポリシー、フィードバック送信、シェア、レビュー依頼

## スクリーンショット

<!-- スクリーンショットをここに追加してください -->
<!-- ![ホーム画面](screenshots/home.png) -->
<!-- ![ゲーム画面](screenshots/game.png) -->

## 動作環境

| 項目 | 要件 |
|------|------|
| iOS | 17.0 以上 |
| Xcode | 16.0 以上 |
| Swift | 6.0（Strict Concurrency 有効） |

## セットアップ

### 1. リポジトリをクローン

```bash
git clone <repository-url>
cd English_flashcard_game
```

### 2. Xcode プロジェクトを生成（XcodeGen 使用）

```bash
brew install xcodegen  # 未インストールの場合
xcodegen generate
```

### 3. ビルド＆実行

**Xcode で開く場合:**
```bash
open KarutaApp.xcodeproj
```
シミュレータまたは実機を選択し、`Cmd + R` で実行します。

**コマンドラインからビルド:**
```bash
xcodebuild -project KarutaApp.xcodeproj \
  -scheme KarutaApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  build
```

> **Note**: 外部パッケージの依存はありません。辞書データベースはプロジェクトにバンドル済みです。

### 辞書データの再構築（任意）

語彙データを更新したい場合は、Python スクリプトで辞書を再生成できます。

```bash
cd Tools
python3 build_dictionary.py
```

CEFR-J Vocabulary Profile と JMdict のデータをもとに `dictionary.sqlite` を再構築します。

## プロジェクト構成

```
Sources/KarutaApp/
├── KarutaApp.swift              # アプリエントリポイント（SwiftData 設定）
├── ContentView.swift            # ルートビュー
├── Models/
│   ├── GameCard.swift           # カードの状態管理
│   ├── GameSession.swift        # ゲームセッション（永続化）
│   ├── WrongAnswer.swift        # 不正解データ（永続化／レガシー）
│   ├── WordRecord.swift         # 単語ごとの学習記録（復習用）
│   ├── DictionaryEntry.swift    # 辞書エントリ
│   ├── CEFRLevel.swift          # 難易度レベル定義（A1〜B2）
│   └── Stage.swift              # ステージ・ゲームモード・カテゴリランク定義
├── Views/
│   ├── HomeView.swift           # ホーム画面
│   ├── GameView.swift           # ゲーム画面
│   ├── GameResultView.swift     # リザルト画面
│   ├── StageSelectView.swift    # ステージ選択（Basic / Category 切り替え）
│   ├── HistoryView.swift        # プレイ履歴一覧
│   ├── HistoryDetailView.swift  # 履歴詳細
│   ├── ReviewView.swift         # 復習画面
│   ├── SettingsView.swift       # 設定画面
│   ├── PrivacyPolicyView.swift  # プライバシーポリシー
│   ├── OnboardingView.swift     # 初回起動ガイド
│   └── Components/
│       ├── GameCardView.swift   # カード表示・タップ処理
│       ├── ScorePopupView.swift # 加点表示ポップアップ
│       ├── TimerBarView.swift   # タイマーバー
│       ├── StreakBadgeView.swift# ストリーク表示
│       ├── ShareCardView.swift  # 結果シェア用カード
│       ├── SoftCardStyle.swift  # カードスタイル
│       └── LiquidPressStyle.swift # ボタン押下スタイル
├── ViewModels/
│   └── GameViewModel.swift      # ゲームロジック・状態管理（@Observable）
├── Services/
│   ├── DictionaryService.swift  # SQLite 辞書アクセス
│   ├── GameHistoryStore.swift   # SwiftData による履歴・記録の永続化
│   ├── SoundManager.swift       # サウンド管理
│   └── HapticManager.swift      # 触覚フィードバック管理
├── Utilities/
│   ├── Constants.swift          # 定数・スコアリングルール
│   ├── ColorPalette.swift       # カラーパレット
│   ├── FontStyles.swift         # フォント定義
│   └── ShareSheet.swift         # 共有シート
└── Resources/
    ├── dictionary.sqlite        # 語彙データベース
    └── Assets.xcassets/         # アプリアイコン・画像

Tools/
├── build_dictionary.py          # 辞書構築スクリプト
└── data/
    ├── cefrj-vocabulary-profile-1.5.csv
    └── JMdict_e.gz
```

## アーキテクチャ

**MVVM パターン** を採用しています。

```
View（SwiftUI） → ViewModel（@Observable） → Service / Model
                                              ↓
                                     SwiftData（セッション・WordRecord）
                                     SQLite3（読み取り専用辞書）
```

- **Model** — データ構造の定義（GameCard, DictionaryEntry, GameSession, WordRecord 等）
- **View** — SwiftUI による画面描画
- **ViewModel** — `GameViewModel` がゲームロジック・スコアリング・タイマーを管理（`@Observable` + `@MainActor`）
- **Service** — 辞書検索、履歴保存、サウンド・触覚フィードバック

## ゲームシステム

### プレイモード

| モード | 内容 |
|--------|------|
| **Basic** | CEFR レベル（A1〜B2）を選んでプレイ |
| **Category** | カテゴリ別に Rank A（A1+A2）/ Rank B（B1+B2）を選んでプレイ |

### ゲームモード（各レベル/カテゴリ共通）

| モード | 内容 | 制限時間 | クリア条件 |
|--------|------|----------|------------|
| **1 Minute Challenge**（max_correct） | 60秒以内にできるだけ多くのペアを正解する | 60秒 | 時間切れで終了。正解数を競う |
| **Time Attack**（time_attack） | 15ペアを最速で正解する | 300秒（実質クリア時間が記録対象） | 15ペア完了でクリア。タイムを競う |

両モードとも、表示カードは常に **5ペア** で、正解するごとに新しいカードが補充されます。

### 難易度レベル（CEFR）

| レベル | 名称（英） | 名称（日） |
|--------|-----------|-----------|
| A1 | Beginner | 初級 |
| A2 | Elementary | 初級上 |
| B1 | Intermediate | 中級 |
| B2 | Upper Intermediate | 中級上 |

### スコアリング

スコア計算式（[Constants.swift](Sources/KarutaApp/Utilities/Constants.swift)）:

```
獲得スコア = 基本点(10) × スピードボーナス × ストリーク倍率
```

| 要素 | 詳細 |
|------|------|
| 基本ポイント | 1ペア正解 = 10点 |
| スピードボーナス | `1.0 + (残り時間 / 制限時間) × 0.5` （1.0〜1.5倍） |
| ストリーク倍率 | 0-2連続: 1.0× / 3-5連続: 1.5× / 6-9連続: 2.0× / 10-14連続: 2.5× / 15連続以上: 3.0× |
| 不正解ペナルティ | 残り時間から 3秒減算 |
| ストリークマイルストーン | 5連続正解ごとに演出（追加スコアなし） |

不正解するとストリークは 0 にリセットされます。

### ベストスコア記録

ステージ選択画面で、各レベル × ゲームモードのベスト記録が表示されます。

- **1 Minute Challenge**: 最高正解数
- **Time Attack**: 最短クリア時間（クリア済みセッションのみ）

## 設定画面の機能

[SettingsView.swift](Sources/KarutaApp/Views/SettingsView.swift)

### Game
- Sound Effects（効果音 ON/OFF）
- Haptic Feedback（触覚フィードバック ON/OFF）

### Data
- Clear All History（プレイ履歴と復習データをすべて削除）

### Support
- **Privacy Policy** — [PrivacyPolicyView](Sources/KarutaApp/Views/PrivacyPolicyView.swift) を表示
- **Send Feedback** — `mailto:` でメールアプリを起動（端末情報付き）
- **Share App** — App Store URL を共有
- **Rate App** — `StoreKit` の `requestReview` で App Store レビューダイアログを表示

### Credits & Version（枠なし表示）
- CEFR-J Wordlist Version 1.6
- DiQt English-Japanese Dictionary
- Sound Effects（Pocket Sound）
- App Version（`Bundle.main` から動的取得）

## 使用技術

| カテゴリ | 技術 |
|----------|------|
| 言語 | Swift 6.0（Strict Concurrency） |
| UI フレームワーク | SwiftUI |
| 状態管理 | `@Observable` / `@MainActor` |
| データ永続化 | SwiftData（GameSession, WordRecord）/ SQLite3（辞書） |
| オーディオ | AVFoundation |
| レビュー | StoreKit（`requestReview`） |
| ビルドシステム | Swift Package Manager / XcodeGen |
| 辞書データ | CEFR-J Vocabulary Profile / JMdict |

## カラーパレット

[ColorPalette.swift](Sources/KarutaApp/Utilities/ColorPalette.swift) — 6色構成のライトテーマ

| 名前 | HEX | 用途 |
|------|-----|------|
| mistWhite | `#F8F9FC` | 背景（最も明るい） |
| lavender | `#BFC8EA` | ソフトサーフェス、ライトアクセント |
| periwinkle | `#738BE7` | プライマリアクション、最も明るい青 |
| indigo | `#5B67A2` | セカンダリ、強い青 |
| slate | `#7B86AA` | ミュートテキスト、ボーダー |
| charcoal | `#545051` | プライマリテキスト、ダークアクセント |

## 開発フロー

### project.yml 変更後の手順

`project.yml` を編集した場合は必ず再生成してください：

```bash
xcodegen generate
```

新しいファイルを `Sources/KarutaApp/` 配下に追加した場合も、XcodeGen で自動検出されるため再生成が必要です。

### 公開前の TODO

[SettingsView.swift:14-15](Sources/KarutaApp/Views/SettingsView.swift#L14-L15) のプレースホルダーを実値に書き換えてください：

```swift
private let feedbackEmail = "support@example.com"      // ← 実際のメールアドレスへ
private let appStoreId = "id0000000000"                // ← App Store 公開後の ID へ
```

## ライセンス

辞書データは以下のオープンソースデータセットを使用しています：

- **CEFR-J Wordlist Version 1.6** — Yukio Tono Laboratory, Tokyo University of Foreign Studies
- **JMdict** — Japanese-Multilingual Dictionary（[EDRDG License](https://www.edrdg.org/edrdg/licence.html)）
- **DiQt English-Japanese Dictionary** — BooQs Inc.
- **Sound Effects** — [Pocket Sound](https://pocket-se.info/)
