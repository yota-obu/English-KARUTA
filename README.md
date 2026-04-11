# 英単語かるた - English Vocabulary Karuta

英単語と日本語訳をマッチングして語彙力を鍛える、iOS向けカードゲームアプリです。
CEFR（ヨーロッパ言語共通参照枠）に基づいた4段階の難易度と、2つのゲームモードで楽しめます。

## 特徴

- **マッチング形式のカードゲーム** — 英語カードと日本語かるたをペアで選んで正解を目指す
- **2つのゲームモード** — 「1 Minute Challenge」(60秒で何ペア取れるか) と「Time Attack」(20ペアを最速で)
- **CEFRレベル対応（A1〜B2）** — 4段階の難易度。CEFR-J Wordlist v1.6 に基づく約 7,600 語
- **間違えた問題の復習機能** — 不正解の単語を WordRecord として保存し、例文付きで復習できる。正解で自動マスター
- **プレイ履歴・ベストスコア** — 過去のゲーム結果を記録、レベル × モードごとのベスト記録を表示。ハイスコア時は NEW RECORD バッジ
- **サウンド＆触覚フィードバック** — 正解 / 不正解 / カウントダウン / タイムアップ等に対応
- **ライトテーマ UI** — Periwinkle / Lavender / Indigo を基調とした 6色限定パレット (液体ソフトモーフィズム)
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

CEFR-J Wordlist v1.6 のデータをもとに `dictionary.sqlite` を再構築します。
DiQt 由来の日本語訳をクリーンアップし、約 7,600 エントリの SQLite を生成します。

## プロジェクト構成

```
Sources/KarutaApp/
├── KarutaApp.swift              # アプリエントリポイント（SwiftData 設定）
├── ContentView.swift            # ルートビュー
├── Models/
│   ├── GameCard.swift           # カードの状態管理
│   ├── GameSession.swift        # ゲームセッション（永続化）
│   ├── WrongAnswer.swift        # 不正解データ（レガシー／未使用）
│   ├── WordRecord.swift         # 単語ごとの学習記録（正解/不正解回数、マスター状態）
│   ├── DictionaryEntry.swift    # 辞書エントリ
│   ├── CEFRLevel.swift          # 難易度レベル定義（A1〜B2）
│   └── Stage.swift              # ステージ・ゲームモード定義
├── Views/
│   ├── HomeView.swift           # ホーム画面
│   ├── GameView.swift           # ゲーム画面
│   ├── GameResultView.swift     # リザルト画面
│   ├── StageSelectView.swift    # ステージ選択（CEFR レベル × ゲームモード）
│   ├── HistoryView.swift        # プレイ履歴一覧
│   ├── HistoryDetailView.swift  # 履歴詳細
│   ├── ReviewView.swift         # 復習画面 (Wrong/Mastered/All タブ + CEFR フィルタ)
│   ├── SettingsView.swift       # 設定画面
│   ├── PrivacyPolicyView.swift  # プライバシーポリシー
│   ├── OnboardingView.swift     # 初回起動ガイド (現在は使用していない)
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

### ゲームモード

| モード | 内容 | 制限時間 | クリア条件 |
|--------|------|----------|------------|
| **1 Minute Challenge**（max_correct） | 60秒以内にできるだけ多くのペアを正解する | 60秒 | 時間切れで終了。正解数を競う |
| **Time Attack**（time_attack） | 20ペアを最速で正解する | 300秒（実質クリア時間が記録対象） | 20ペア完了でクリア。タイムを競う。タイマーはカウントアップ表示 |

両モードとも、表示カードは常に **5ペア (英語5枚 + 日本語5枚)** で、正解するごとに新しいカードが補充されます。

### 難易度レベル（CEFR）

| レベル | 名称 | 単語数 |
|--------|-----|------|
| A1 | Beginner | 約 1,100 |
| A2 | Elementary | 約 1,400 |
| B1 | Intermediate | 約 2,400 |
| B2 | Upper Intermediate | 約 2,800 |

### カード補充ロジック

- 正解後 1.1秒待機 (連続マッチを溜める) → 最大1.8秒で強制補充
- 連続マッチ時は空きスロットに **一括補充**
- 英語/日本語それぞれ **ランダムなスロット**に配置 → 同じ位置パターンが固定化されない
- 出現は `.opacity` + `.scale` フェードイン (0.6秒)

### 復習システム (WordRecord)

- ゲーム中の正解/不正解を WordRecord として永続化
- 初回正解 → 自動的にマスター扱い
- 一度でも間違えると Wrong リスト入り、その後正解しても Wrong に留まる
- Review 画面で **Wrong / Mastered / All** タブ + CEFR レベルフィルタで閲覧

### ベストスコア記録

ステージ選択画面で、各レベル × ゲームモードのベスト記録が表示されます。

- **1 Minute Challenge**: 最高正解数
- **Time Attack**: 最短クリア時間（クリア済みセッションのみ）
- ハイスコア達成時はリザルト画面に **NEW RECORD!** バッジが表示されます

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
