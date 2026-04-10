# Karuta - 英語フラッシュカードゲーム

英単語と日本語訳をマッチングして語彙力を鍛える、iOS向けカードゲームアプリです。  
CEFR（ヨーロッパ言語共通参照枠）に基づいた6段階の難易度で、初心者から上級者まで楽しめます。

## 特徴

- **マッチング形式のカードゲーム** — 英語カードと日本語カードをペアで選んで正解を目指す
- **CEFRレベル対応（A1〜C2）** — レベルごとにステージ数・カード枚数・制限時間が変化
- **スコアリングシステム** — スピードボーナス・連続正解ストリークによる倍率アップ
- **間違えた問題の復習機能** — 不正解の単語を保存し、あとから例文付きで復習できる
- **プレイ履歴** — 過去のゲーム結果（スコア・正答率・ストリーク等）を記録・閲覧
- **サウンド＆触覚フィードバック** — 正解・不正解・コンボ・カウントダウン等に対応
- **ダークテーマUI** — レベルごとのカラーコードとアニメーション付き

## スクリーンショット

<!-- スクリーンショットをここに追加してください -->
<!-- ![ホーム画面](screenshots/home.png) -->
<!-- ![ゲーム画面](screenshots/game.png) -->

## 動作環境

| 項目 | 要件 |
|------|------|
| iOS | 17.0 以上 |
| Xcode | 16.0 以上 |
| Swift | 6.0 |

## セットアップ

### 1. リポジトリをクローン

```bash
git clone <repository-url>
cd English_flashcard_game
```

### 2. Xcodeプロジェクトを生成（XcodeGen使用）

```bash
brew install xcodegen  # 未インストールの場合
xcodegen generate
```

### 3. ビルド＆実行

```bash
open KarutaApp.xcodeproj
```

Xcodeでシミュレータまたは実機を選択し、`Cmd + R` で実行します。

> **Note**: 外部パッケージの依存はありません。辞書データベースはプロジェクトにバンドル済みです。

### 辞書データの再構築（任意）

語彙データを更新したい場合は、Python スクリプトで辞書を再生成できます。

```bash
cd Tools
python3 build_dictionary.py
```

JMdict と CEFR-J Vocabulary Profile のデータをもとに `dictionary.sqlite` を再構築します。

## プロジェクト構成

```
Sources/KarutaApp/
├── KarutaApp.swift              # アプリエントリポイント（SwiftData設定）
├── Models/
│   ├── GameCard.swift           # カードの状態管理
│   ├── GameSession.swift        # ゲームセッション（永続化）
│   ├── WrongAnswer.swift        # 不正解データ（永続化）
│   ├── DictionaryEntry.swift    # 辞書エントリ
│   ├── CEFRLevel.swift          # 難易度レベル定義
│   └── Stage.swift              # ステージ構成
├── Views/
│   ├── HomeView.swift           # ホーム画面
│   ├── GameView.swift           # ゲーム画面
│   ├── GameResultView.swift     # リザルト画面
│   ├── StageSelectView.swift    # ステージ選択
│   ├── HistoryView.swift        # プレイ履歴一覧
│   ├── HistoryDetailView.swift  # 履歴詳細
│   ├── ReviewView.swift         # 復習画面
│   ├── SettingsView.swift       # 設定画面
│   ├── OnboardingView.swift     # 初回起動ガイド
│   └── Components/              # 再利用可能なUIコンポーネント
├── ViewModels/
│   └── GameViewModel.swift      # ゲームロジック・状態管理
├── Services/
│   ├── DictionaryService.swift  # SQLite辞書アクセス
│   ├── GameHistoryStore.swift   # SwiftDataによるデータ永続化
│   ├── SoundManager.swift       # サウンド管理
│   └── HapticManager.swift      # 触覚フィードバック管理
├── Utilities/
│   ├── Constants.swift          # 定数・スコアリングルール
│   ├── ColorPalette.swift       # カラーパレット
│   ├── FontStyles.swift         # フォント定義
│   └── ShareSheet.swift         # 共有機能
└── Resources/
    └── dictionary.sqlite        # 語彙データベース

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
                                     SwiftData（セッション・復習データ）
                                     SQLite3（辞書データベース）
```

- **Model** — データ構造の定義（GameCard, DictionaryEntry, GameSession 等）
- **View** — SwiftUI による画面描画
- **ViewModel** — `GameViewModel` がゲームロジック・スコアリング・タイマーを管理
- **Service** — データアクセス（辞書検索、履歴保存）やサウンド・触覚フィードバック

## ゲームシステム

### 難易度レベル

| レベル | 名称 | ステージ数 | 表示ペア / 合計ペア | 制限時間 |
|--------|------|-----------|---------------------|----------|
| A1 | Beginner | 10 | 5 / 5 | 120秒 |
| A2 | Elementary | 10 | 6 / 20 | 105秒 |
| B1 | Intermediate | 12 | 6-7 / 25 | 100秒 |
| B2 | Upper Intermediate | 12 | 7 / 28 | 95秒 |
| C1 | Advanced | 10 | 8 / 30 | 90秒 |
| C2 | Proficiency | 8 | 8 / 32 | 85秒 |

### スコアリング

| 要素 | 詳細 |
|------|------|
| 基本ポイント | 1マッチ = 10点 |
| スピードボーナス | 残り時間に応じて 1.0〜1.5倍 |
| ストリーク倍率 | 3連続: 1.5倍 / 6連続: 2.0倍 / 10連続: 2.5倍 / 15連続: 3.0倍 |
| 不正解ペナルティ | 制限時間から3秒減算 |

## 使用技術

| カテゴリ | 技術 |
|----------|------|
| 言語 | Swift 6.0（Strict Concurrency） |
| UIフレームワーク | SwiftUI |
| データ永続化 | SwiftData（セッション・復習） / SQLite3（辞書） |
| オーディオ | AVFoundation |
| ビルドシステム | Swift Package Manager / XcodeGen |
| 辞書データ | JMdict（和英辞典） / CEFR-J Vocabulary Profile |

## ライセンス

辞書データは以下のオープンソースデータセットを使用しています：

- **JMdict** — Japanese-Multilingual Dictionary（[EDRDG License](https://www.edrdg.org/edrdg/licence.html)）
- **CEFR-J Vocabulary Profile** — 東京外国語大学 投野由紀夫研究室
