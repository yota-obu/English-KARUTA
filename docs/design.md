# 英単語かるた デザインガイド

## デザインコンセプト

**液体のような柔らかさ** + **ライトテーマ** + **静かな青系トーン**

学習アプリとして長時間使用しても目が疲れない、落ち着いた青系のパレットで構成。
触覚と視覚で「液体」を感じる柔らかいインタラクションを実現する。

---

## カラーパレット

6色の限定パレットで全UIを構成。すべて [ColorPalette.swift](../Sources/KarutaApp/Utilities/ColorPalette.swift) で定義。

### Base Palette

| 名前 | Hex | プレビュー | 役割 |
|---|---|---|---|
| **mistWhite** | `#F8F9FC` | ░ | 背景メイン (最も明るい) |
| **lavender** | `#BFC8EA` | ▒ | カード背景, 補助アクセント, A1 |
| **slate** | `#7B86AA` | ▓ | テキスト副, ボーダー, A2 |
| **periwinkle** | `#738BE7` | ▓ | プライマリアクション, B1, 正解 |
| **indigo** | `#5B67A2` | ▓ | セカンダリ, B2, ストリーク, タイマー警告 |
| **charcoal** | `#545051` | ▓ | テキスト主, 不正解, ダークアクセント |

### セマンティックマッピング

| 用途 | 使う色 |
|---|---|
| 背景メイン | mistWhite |
| 背景セカンダリ | lavender 40% |
| カード面 | white |
| テキスト主 | charcoal |
| テキスト副 | slate |
| テキスト第3 | slate 60% |
| プライマリアクセント | periwinkle |
| セカンダリアクセント | indigo |
| 第3アクセント | lavender |
| **正解** | periwinkle |
| **不正解** | charcoal |
| ストリーク | indigo |
| タイマー警告 | indigo |
| タイマー危険 | charcoal |

### CEFRレベル色 (薄→濃)

レベルが上がるほど色が深くなるグラデーション。

| レベル | 色 | 意味 |
|---|---|---|
| **A1** | lavender | 初級 (最も薄い) |
| **A2** | slate | 初級上 |
| **B1** | periwinkle | 中級 |
| **B2** | indigo | 中級上 (最も濃い) |

### グラデーション

```swift
// 背景グラデーション (画面全体)
backgroundGradient: mistWhite → lavender 35%

// アクセントグラデーション (ロゴ・強調要素)
accentGradient: periwinkle → indigo (左上→右下)
```

---

## 形 (Shape)

| 要素 | 角丸 |
|---|---|
| カード (ゲーム内) | 20pt continuous |
| カード (Home メニュー) | 20pt continuous |
| チップ (レベル選択) | 16pt continuous |
| バッジ | Capsule |
| カウンター | Capsule |

### シャドウ ("液体" 感)

- **liquidShadowColor**: `indigo.opacity(0.12)`
- パラメータ: `radius: 12, y: 6`
- 全カードに統一的に適用 → ふわっと浮いている感

### ボーダー ("液体" 感)

- **liquidBorderColor**: `Color.white.opacity(0.7)`
- 1pt の細いハイライト → ガラス的な質感

---

## タイポグラフィ

[FontStyles.swift](../Sources/KarutaApp/Utilities/FontStyles.swift)

| スタイル | サイズ | weight | design |
|---|---|---|---|
| titleLarge | 32 | bold | rounded |
| titleMedium | 24 | bold | rounded |
| titleSmall | 20 | semibold | rounded |
| bodyLarge | 18 | medium | rounded |
| bodyMedium | 16 | regular | rounded |
| bodySmall | 14 | regular | rounded |
| caption | 12 | medium | rounded |
| cardText | 17 | semibold | rounded |
| scoreText | 48 | heavy | rounded |
| streakText | 22 | black | rounded |
| timerText | 14 | bold | monospaced |

**ルール**: 全フォントは `.rounded` デザインで統一 (timerのみmonospaced)。
学習アプリらしい親しみやすさ + 視認性。

---

## モーション

### LiquidPressStyle (液体プレス)

[LiquidPressStyle.swift](../Sources/KarutaApp/Views/Components/LiquidPressStyle.swift)

```swift
.scaleEffect(isPressed ? 0.94 : 1.0)
.animation(.interpolatingSpring(stiffness: 280, damping: 14), value: isPressed)
```

押下時にぷにっと縮んで弾けるように戻る。
**全インタラクティブボタンに適用**:
- ホームメニューボタン
- ステージ選択 (Level/Category チップ, サブレベル行, トピック行)
- ゲーム内カード (将来的に)

### カードアニメーション

| イベント | アニメーション |
|---|---|
| 選択 | scale(1.05) + glow `.spring(response:0.3, damping:0.6)` |
| 正解 | opacity → 0 (位置維持) `.easeOut(0.3)` |
| 不正解 | シェイク (3振動 / 0.4秒) |
| カード差し替え | 0.6秒待機後、`.spring` で同位置に補充 |

### ハプティクス

[HapticManager.swift](../Sources/KarutaApp/Services/HapticManager.swift)

| イベント | フィードバック |
|---|---|
| ボタンタップ | `selectionChanged()` |
| 正解 | `notificationOccurred(.success)` |
| 不正解 | `notificationOccurred(.error)` |
| ストリーク 5連 | `.heavy` impact |
| カウントダウン | `.light` impact |
| ゲーム終了 | medium → heavy → medium 連打 |

---

## レイアウト原則

1. **余白を大きく** — 1画面に詰め込まない、息のあるレイアウト
2. **パネル/グリッドを避ける** — リスト or シンプルなチップ + リスト
3. **角丸 + シャドウで階層化** — 線で区切らない
4. **アクセント色は控えめに** — 主要なアクション1点のみに使用
5. **テキストは2階調 + 1ヒント** — primary / secondary / tertiary

---

## コンポーネント一覧

### `softCard()` Modifier
全てのカード型UIに適用する液体的な背景:
- 白背景
- liquidShadowColor
- liquidBorderColor 1pt

### `LiquidPressStyle`
全インタラクティブボタンに適用するプレススタイル:
- scale 0.94
- spring back animation
- 触覚 (selectionChanged)

### `levelChip` / `rankChip`
- 選択時: フィルカラー + シャドウ
- 非選択時: 白背景 + ボーダー

### `subLevelRow` / `topicRow`
- 白背景の柔らかいカード
- 左に番号 (CEFR色)、中央に情報、右に Best スコア + chevron

---

## ファイル構成

```
Sources/KarutaApp/
├── Utilities/
│   ├── ColorPalette.swift   ← 全色定義
│   └── FontStyles.swift     ← 全フォント定義
└── Views/Components/
    ├── SoftCardStyle.swift  ← softCard() modifier
    └── LiquidPressStyle.swift ← liquid press button style
```

すべての色・フォント・アニメーションは上記4ファイルで一元管理。
直接Hex指定や`.font(.system(size:))`などのインライン定義は禁止。
