# 英単語かるた 仕様書

## 概要

タイムアタック型の英単語・日本語かるたゲームiOSアプリ。
英語の単語カードと日本語訳カードをマッチングするゲーム。

**アプリ名**: 英単語かるた (English Vocabulary Karuta)

## 技術構成

| 項目 | 内容 |
|---|---|
| 言語 | Swift 6.0 (Strict Concurrency) |
| UI | SwiftUI (iOS 17+) |
| 状態管理 | `@Observable` / `@MainActor` |
| ビルド | XcodeGen + SweetPad (VSCode) |
| データ永続化 | SwiftData (GameSession, WordRecord) + SQLite (辞書DB) |
| 外部依存 | なし (SQLite3はiOS標準) |
| テーマ | ライトテーマ / 液体ソフトモーフィズム |

---

## 辞書データ

### データソース
- **CEFR-J Wordlist Version 1.6** (レベル別CSV)
  - `CEFR-J/CEFR-J_A1.csv` ~ `CEFR-J_B2.csv`
  - 商用利用可 (要クレジット表示)
  - **7,658エントリ** (A1: 1,097 / A2: 1,390 / B1: 2,411 / B2: 2,760)

### 各エントリのSQLiteカラム
- `id` — 主キー
- `headword` — 英単語 (`/`区切りの場合は最初の形のみ)
- `headword_raw` — 元の英単語表記 (全形)
- `pos` — 品詞 (noun, verb, adjective, adverb, etc.)
- `cefr_level` — CEFRレベル (A1, A2, B1, B2)
- `first_meaning` — かるた用の第1訳 (クリーンアップ済み)
- `meaning_raw` — 元のCSVの日本語訳 (全文保持)
- `all_meanings` — 全訳のリスト (Review詳細用)
- `ipa` — IPA発音記号
- `topic` — トピックタグ (Food and drink, Education等)
- `example_en` — 英語例文
- `example_ja` — 日本語訳例文

### かるた用訳のクリーンアップルール
1. **トップレベルでの分割** (括弧内は保護): `/` `;` `；`
2. `《`の前で区切り (`《略》`等の補足を除外)
3. **括弧と中身を除去**: `()` `（）` `〈〉` `《》` `【】` `｟｠` `[X]` `{}` `〖〗`
4. **括弧と中身を保持**: `[[X]]` (X部分のみ残す)
5. **括弧自体を除去・中身は残す**: `『』`
6. シングルクォート `'` `'` `'` を除去
7. アスタリスク `*` `**` を除去
8. `,` `，` `、` の前で区切る (トップレベルのみ)
9. 後処理: 単独の `U` `C` 削除、片方だけの括弧削除、`;` 以降削除
10. 残りが記号 (`= ~ -` 等) のみの場合は次の候補へフォールバック
11. **除外フィルタ**: `=` 含むエントリ / 英字含むエントリ (`either`, `molecule`, `account` 以外)

### 辞書ビルドスクリプト
`Tools/build_dictionary.py` → `Sources/KarutaApp/Resources/dictionary.sqlite`

---

## ゲームモード

### 2つのゲームモード

| モード | 内容 | 制限時間 | クリア条件 |
|---|---|---|---|
| **1 Minute Challenge** (`max_correct`) | 60秒間に何ペア取れるかチャレンジ | 60秒 | 時間切れで終了、正解数を競う |
| **Time Attack** (`time_attack`) | 20ペアを最速で正解 | 300秒 (上限) | 20ペア達成でクリア、タイムを競う |

### 共通仕様
- 表示カード: 常に **英語5枚 + 日本語5枚** の計10枚
- CEFR レベル A1〜B2 の4段階から選択
- 単語はDB内のレベルからランダム抽選

### ゲーム中のタイマー表示
- **1 Minute Challenge**: 残り時間を **カウントダウン** (60→0)
- **Time Attack**: 経過時間を **カウントアップ** (0→経過秒数)

---

## ゲーム仕様

### カードマッチング
- 英語カードをタップ → 日本語カードをタップ → ペア判定
- 正解: カードがフェードアウト → 別のスロットに新カードがフェードイン
- 不正解: シェイクアニメーション
- 不正解はセッション中で1回のみカウント (重複防止)

### カード補充ロジック
- 正解後 **1.1秒のデバウンス** で連続マッチを溜める
- 最大 **1.8秒**で強制補充 (カードが全部消えないように)
- 連続マッチ時は空きスロットに **一括補充**
- 英語/日本語それぞれ **ランダムなスロット**に配置 (固定パターンを回避)
- 出現は `.opacity` + `.scale` フェードイン (0.6秒)

### 効果音・振動
- カードタップ: `.selectionChanged` (音なし)
- メニュー/レベル選択ボタン: `select.caf` + `.selectionChanged`
- 正解: `correct.caf` + `.success`
- 不正解: `wrong.caf` + `.error` + シェイクアニメ
- カウントダウン (残り10秒): `countdown.caf` (1回のみ) + `.light` (毎秒)
- ゲーム終了: `timeup.caf` + 触覚連打
- SE音量: 25%, タイマー系: 5%

---

## 単語記録 (WordRecord)

ゲーム中の正解/不正解を WordRecord (SwiftData) に永続化。

### フィールド
- `correctCount` — 正解回数
- `wrongCount` — 不正解回数
- `masteredAt` — マスター日時 (nil=未マスター)
- `lastAttemptWrong` — 最後の試行が不正解か

### 自動マスタリングロジック
- **初回正解** (wrongCount=0) → 自動的に `masteredAt` セット → Mastered タブへ
- **過去に間違えた単語**で正解 → `correctCount` 増やさない、masteredにもしない (Wrongに留まる)
- **過去にマスターした単語**で不正解 → demote (masteredAt = nil)

### Review画面
- **Wrongタブ**: 未マスター単語
- **Masteredタブ**: マスター済み単語
- **Allタブ**: 全記録
- CEFRレベルフィルター (All / A1 / A2 / B1 / B2)
- 表示順: ABC順 (英単語)
- カウンター: `現在表示数 / 全プレイ済み数`
- 右側の○ボタンで覚えた/覚えてない切り替え
- タップで詳細シート (全画面):
  - 英単語、IPA発音記号、品詞、CEFRレベル、トピック
  - 正解回数 / 不正解回数 / 正答率
  - 全訳リスト (番号付き)
  - 英語例文、日本語訳例文

---

## 画面構成

```
ContentView
 └── HomeView (NavigationStack)
       ├── Play → StageSelectView
       │           ├── CEFR Level チップ (A1/A2/B1/B2)
       │           └── Game Mode 行 (1 min / 20 pairs / Coming Soon x2)
       │           → GameView (.fullScreenCover) → GameResultView
       ├── Review → ReviewView (Wrong/Mastered/All + CEFR フィルタ)
       │           → WordDetailSheet (.fullScreenCover)
       ├── History → HistoryView → HistoryDetailView
       └── Settings → SettingsView
                     ├── PrivacyPolicyView
                     └── ShareSheet
```

### ベスト記録表示
- ステージ選択画面で各 (CEFR × ゲームモード) のベストを表示
- **1 min**: 最高正解数
- **20 pairs**: 最短クリア時間
- ハイスコア達成時はリザルト画面に **NEW RECORD!** バッジ

---

## カラーパレット

[ColorPalette.swift](../Sources/KarutaApp/Utilities/ColorPalette.swift) — 6色構成のライトテーマ

| 名前 | Hex | 用途 |
|---|---|---|
| **mistWhite** | `#F8F9FC` | 背景メイン (最も明るい) |
| **lavender** | `#BFC8EA` | カード背景, 補助アクセント, A1 |
| **slate** | `#7B86AA` | テキスト副, ボーダー, A2 |
| **periwinkle** | `#738BE7` | プライマリアクション, B1, 正解 |
| **indigo** | `#5B67A2` | セカンダリ, B2, ストリーク |
| **charcoal** | `#545051` | テキスト主, 不正解 |

詳細は [docs/design.md](design.md) を参照。

---

## ファイル構成

```
Sources/KarutaApp/
├── KarutaApp.swift              # @main + SwiftData container + Nav appearance
├── ContentView.swift            # → HomeView
├── Models/
│   ├── CEFRLevel.swift          # A1-B2 enum
│   ├── Stage.swift              # ステージ + GameMode + CategoryRank (未使用)
│   ├── DictionaryEntry.swift    # 辞書エントリ (read-only)
│   ├── GameCard.swift           # ゲーム内カード状態
│   ├── GameSession.swift        # SwiftData: ゲーム記録
│   ├── WordRecord.swift         # SwiftData: 単語別学習記録
│   └── WrongAnswer.swift        # SwiftData: レガシー (未使用)
├── ViewModels/
│   └── GameViewModel.swift      # @Observable @MainActor ゲームエンジン
├── Views/
│   ├── HomeView.swift           # メニュー (Play/Review/History/Settings)
│   ├── StageSelectView.swift    # CEFR レベル × ゲームモード選択
│   ├── GameView.swift           # ゲームプレイ画面
│   ├── GameResultView.swift     # リザルト + NEW RECORD バッジ
│   ├── HistoryView.swift        # プレイ履歴一覧
│   ├── HistoryDetailView.swift  # 履歴詳細
│   ├── ReviewView.swift         # 復習 + WordDetailSheet
│   ├── SettingsView.swift       # 設定
│   ├── PrivacyPolicyView.swift  # プライバシーポリシー
│   ├── OnboardingView.swift     # 未使用
│   └── Components/
│       ├── GameCardView.swift   # カード単体
│       ├── SoftCardStyle.swift  # 液体カードスタイル
│       ├── LiquidPressStyle.swift # ボタン液体プレス
│       ├── TimerBarView.swift   # タイマーバー
│       ├── StreakBadgeView.swift
│       ├── ScorePopupView.swift
│       └── ShareCardView.swift  # シェア用カード
├── Services/
│   ├── DictionaryService.swift  # SQLite 辞書リーダー (singleton)
│   ├── GameHistoryStore.swift   # SwiftData CRUD
│   ├── SoundManager.swift       # AVAudioPlayer + ambient session
│   └── HapticManager.swift      # UIImpactFeedback
├── Utilities/
│   ├── ColorPalette.swift       # 6色パレット
│   ├── FontStyles.swift         # フォント定義
│   ├── Constants.swift          # 定数
│   └── ShareSheet.swift         # UIActivityViewController wrapper
└── Resources/
    ├── dictionary.sqlite        # ビルド済み辞書DB
    ├── select.caf               # ボタンタップ音
    ├── correct.caf              # 正解音
    ├── wrong.caf                # 不正解音
    ├── countdown.caf            # カウントダウン音
    └── timeup.caf               # タイムアップ音
```

---

## ライセンス帰属表示

アプリ内 Settings 画面の Credits セクションに表示:

- 『CEFR-J Wordlist Version 1.6』東京外国語大学投野由紀夫研究室. （URL: http://www.cefr-j.org/download.html より2026年4月ダウンロード）
- 『DiQt English-Japanese Dictionary』BooQs Inc.
- Sound Effects: Pocket Sound – https://pocket-se.info/
