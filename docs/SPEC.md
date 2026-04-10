# KarutaApp - 英単語カルタゲーム 仕様書

## 概要

デュオリンゴの「無限カルタ」に着想を得た、タイムアタック型の英単語・日本語カルタゲームiOSアプリ。
英語の単語カードと日本語訳カードをマッチングするゲーム。

## 技術構成

| 項目 | 内容 |
|---|---|
| 言語 | Swift 6.0 |
| UI | SwiftUI (iOS 17+) |
| ビルド | XcodeGen + SweetPad (VSCode) |
| データ永続化 | SwiftData (ゲーム記録) + SQLite (辞書DB) |
| 外部依存 | なし (SQLite3はiOS標準) |
| テーマ | ライトテーマ / 液体ソフトモーフィズム |

## 辞書データ

### データソース
- **CEFR-J Vocabulary Profile** (レベル別CSV)
  - `CEFR-J/CEFR-J_A1.csv` ~ `CEFR-J_B2.csv`
  - 商用無料 (要引用: Tono Laboratory, TUFS)
  - 7,743エントリ (A1: 1,123 / A2: 1,406 / B1: 2,437 / B2: 2,777)

### 各エントリに含まれるフィールド
- `headword` — 英単語
- `pos` — 品詞 (noun, verb, adjective, adverb, etc.)
- `cefr_level` — CEFRレベル (A1, A2, B1, B2)
- `first_meaning` — カルタ用の第1訳 (クリーンアップ済み)
- `meaning_raw` — 元のCSVの日本語訳 (全文保持)
- `all_meanings` — `/`区切りで分割した訳のリスト
- `ipa` — IPA発音記号
- `topic` — トピック/カテゴリ (例: "Food and drink", "Education")
- `example_en` — 英語例文
- `example_ja` — 日本語訳例文

### カルタ用訳のクリーンアップルール
1. `()` `（）` → カッコと中身を除去
2. `〈...〉` `《...》` `【...】` `[[...]]` → カッコと中身を除去
3. `『』` → カッコ自体を除去、中身は残す
4. `,` 以降を除去
5. シングルクォート `'` `'` `'` を除去
6. それ以外はそのまま保持

### 辞書ビルドスクリプト
`Tools/build_dictionary.py` → `Sources/KarutaApp/Resources/dictionary.sqlite`

---

## ゲームモード

### 1. レベル別モード
- CEFR A1~B2を選択 → 各レベル内で5段階 (Level 1~5)
- 単語の難易度のみ変化、カードは常に日本語5枚・英語5枚
- Level 1: 10ペア/90秒 → Level 5: 18ペア/70秒

### 2. カテゴリ別モード
- トピック/ジャンルでプレイ (Food and drink, Education, Travel等)
- レベル横断で特定カテゴリの単語のみ出題
- 15ペア/90秒

---

## ゲーム仕様

### カードマッチング
- 画面に英語5枚・日本語5枚の計10枚表示
- 英語カードをタップ → 日本語カードをタップ → ペア判定
- 正解: カードが消え(opacity 0)、0.6秒後に同じ位置に新カード出現
- 不正解: シェイクアニメーション、3秒のタイムペナルティ
- カードは位置固定 — マッチ後に他のカードが移動しない

### スコアリング
```
スコア = 基礎点(10) × スピードボーナス(1.0-1.5x) × ストリーク倍率(1.0-3.0x)
```
- ストリーク倍率: 0-2連続=1.0x, 3-5=1.5x, 6-9=2.0x, 10-14=2.5x, 15+=3.0x

### 効果音・振動
- カードタップ: selectionChanged
- 正解: .success + correct音
- 不正解: .error + wrong音 + シェイク
- ストリーク5連: .heavy + combo音
- カウントダウン(残り10秒): .light + countdown音

---

## 単語記録 (WordRecord)

ゲーム中の正解/不正解がWordRecordに記録される:
- `correctCount` — 正解回数
- `wrongCount` — 不正解回数
- `masteredAt` — 覚えた日時 (nil=未マスター)

### Review画面
- **Wrongタブ**: 間違えた単語 (未マスター)
- **Masteredタブ**: 覚えた単語
- **Allタブ**: 全記録
- CEFRレベルフィルター (All / A1 / A2 / B1 / B2)
- ABCソート (英単語順)
- 右側の○ボタンで覚えた/覚えてない切り替え
- タップで詳細シート:
  - 英単語、IPA発音記号、品詞、CEFRレベル、トピック
  - 正解回数/不正解回数/正答率
  - 全訳リスト (番号付き)
  - 英語例文、日本語訳例文

---

## 画面構成

```
ContentView
 ├── [初回] OnboardingView → HomeView
 └── [通常] HomeView (NavigationStack)
       ├── Play → StageSelectView
       │           ├── [Levelタブ] CEFR選択 → Level 1-5 リスト
       │           └── [Categoryタブ] トピック一覧
       │           → GameView (.fullScreenCover) → GameResultView
       ├── Review → ReviewView (Wrong/Mastered/All + フィルター)
       ├── History → HistoryView → HistoryDetailView
       └── Settings → SettingsView
```

---

## カラーパレット (ライト / 液体UI)

| 用途 | Hex | 説明 |
|---|---|---|
| 背景メイン | `#F0F4FF` | ソフトラベンダーホワイト |
| 背景サブ | `#E8EDFB` | ライトブルーグレー |
| カード面 | `#FFFFFF` | 白 |
| アクセント1 | `#7C5CFC` | エレクトリックバイオレット |
| アクセント2 | `#FF6B9D` | コーラルピンク |
| アクセント3 | `#00C9A7` | ミントティール |
| テキスト主 | `#1E1B4B` | ディープインディゴ |
| 英語カード | `#EDE9FE` | ソフトバイオレット |
| 日本語カード | `#FCE7F3` | ソフトピンク |

---

## ファイル構成

```
Sources/KarutaApp/
├── KarutaApp.swift              # @main + SwiftData container
├── ContentView.swift            # Onboarding分岐
├── Models/
│   ├── CEFRLevel.swift          # A1-B2 enum
│   ├── Stage.swift              # ステージ定義
│   ├── DictionaryEntry.swift    # 辞書エントリ
│   ├── GameCard.swift           # ゲーム内カード
│   ├── GameSession.swift        # SwiftData: ゲーム記録
│   ├── WrongAnswer.swift        # SwiftData: 間違い記録 (レガシー)
│   └── WordRecord.swift         # SwiftData: 単語別記録
├── ViewModels/
│   └── GameViewModel.swift      # ゲームエンジン
├── Views/
│   ├── HomeView.swift
│   ├── StageSelectView.swift    # Level/Categoryモード
│   ├── GameView.swift
│   ├── GameResultView.swift
│   ├── HistoryView.swift
│   ├── HistoryDetailView.swift
│   ├── ReviewView.swift         # WordDetailSheet含む
│   ├── SettingsView.swift
│   ├── OnboardingView.swift
│   └── Components/
│       ├── GameCardView.swift
│       ├── SoftCardStyle.swift
│       ├── TimerBarView.swift
│       ├── StreakBadgeView.swift
│       ├── ScorePopupView.swift
│       └── ShareCardView.swift
├── Services/
│   ├── DictionaryService.swift  # SQLite辞書リーダー
│   ├── GameHistoryStore.swift   # SwiftData CRUD
│   ├── SoundManager.swift
│   └── HapticManager.swift
├── Utilities/
│   ├── ColorPalette.swift
│   ├── FontStyles.swift
│   ├── Constants.swift
│   └── ShareSheet.swift
└── Resources/
    └── dictionary.sqlite        # ビルド済み辞書DB
```

---

## ライセンス帰属表示

アプリ内Settings画面に表示:
- 『CEFR-J Wordlist Version 1.6』東京外国語大学投野由紀夫研究室.（URL: http://www.cefr-j.org/download.html より2026年4月ダウンロード）
- 『DiQt English-Japanese Dictionary』BooQs Inc.
