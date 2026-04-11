# 英日辞書データソース調査レポート

> **NOTE (2026-04-11更新)**: 本レポートは初期調査段階の記録です。
> 現在のアプリは **CEFR-J Wordlist Version 1.6 + DiQt English-Japanese Dictionary** を採用しています。
> 詳細は [SPEC.md](SPEC.md) の「辞書データ」セクションを参照してください。
> このレポートは将来的な辞書ソース選定の参考として残しています。

## 現状の問題 (調査時点)

調査開始時点ではJMdict（日→英辞書）を逆引きして使用していた。JMdictは日本語見出しから英語訳を引く辞書のため、英語→日本語方向で使うと不自然な訳が多くなる。例: "house" で技術的・文語的な訳が出てしまう。

→ 最終的に **CEFR-J Wordlist v1.6** (英→日訳・例文・IPA・トピックタグ全て含む) を採用することで解決。

---

## 商用利用可能な辞書データソース

### A. 辞書本体（英単語 + 日本語訳）

#### 1. EJDict（パブリックドメイン）★推奨
- **URL**: https://github.com/kujirahand/EJDict
- **ライセンス**: CC0 1.0（パブリックドメイン）— 制限なし
- **形式**: TSV（英単語 TAB 日本語訳）、A-Zファイル分割
- **内容**: 英→日方向で設計。品詞マーカー付き（{名}=名詞, {動}=動詞, {形}=形容詞）
- **規模**: 約50,000〜80,000エントリ
- **品質**: 英→日方向で設計されているため、JMdict逆引きより自然な訳
- **欠点**: 読み仮名なし、IPA発音記号なし、例文なし
- **帰属表示**: 不要

#### 2. JMdict/EDICT（現在使用中）
- **URL**: https://www.edrdg.org/jmdict/edict.html
- **ライセンス**: CC BY-SA 4.0 — 商用可、帰属表示必須
- **形式**: XML。JSON版あり（scriptin/jmdict-simplified, 毎週更新）
- **内容**: 214,000+エントリ。漢字、読み、品詞、英語訳、優先度コード
- **品質**: 日→英方向では最高品質
- **改善案**: 優先度コード（ichi1, news1, spec1）を使って一般的な語を優先すれば逆引き精度が大幅向上
- **帰属表示**: アプリ内About画面に表示必須

#### 3. Wiktionary（Wiktextract/Kaikki.org経由）
- **URL**: https://kaikki.org/dictionary/rawdata.html
- **ライセンス**: CC BY-SA 3.0/4.0 — 商用可
- **形式**: JSONL（1行1エントリ）、全データ2.4GB(gz)
- **内容**: 1,356,506英単語。IPA発音記号、品詞、日本語訳、例文、音声ファイルリンク、語源
- **品質**: IPA・品詞・訳すべてが1データに含まれる。日本語訳の網羅率は部分的
- **欠点**: 生データが巨大、フィルタリングスクリプトが必要
- **帰属表示**: 必須 + share-alike

#### 4. Japanese WordNet
- **URL**: https://bond-lab.github.io/wnja/eng/downloads.html
- **ライセンス**: BSD系 — 商用可
- **形式**: SQLite, XML
- **内容**: 57,238概念、93,834語、例文48,276
- **品質**: 概念ベースのマッピングのため、自然な訳とは限らない
- **帰属表示**: 必須

---

### B. レベル分類（CEFRなど）

#### 5. CEFR-J Vocabulary Profile（現在使用中）
- **URL**: https://github.com/openlanguageprofiles/olp-en-cefrj
- **ライセンス**: 商用無料（要引用）、Octanove C1/C2はCC BY-SA 4.0
- **形式**: CSV
- **内容**: A1-B2レベル分類、約7,700語。日本語訳なし
- **帰属表示**: Tono Laboratory, TUFS

#### 6. NGSL (New General Service List)
- **URL**: https://www.newgeneralservicelist.com/
- **ライセンス**: CC BY-SA 4.0
- **内容**: 2,809語、英語テキストの92%をカバー。日本語訳なし
- **品質**: 学習者向け最重要語彙リスト

#### 7. Words-CEFR-Dataset
- **URL**: https://github.com/Maximax67/Words-CEFR-Dataset
- **ライセンス**: MIT
- **形式**: SQLite, CSV
- **内容**: 大量の英単語のCEFR分類（A1-C2）+ Google N-Gram頻度データ

#### 8. SVL12000 ❌商用不可
- **URL**: https://github.com/kim0051/word-levels-db
- **ライセンス**: ALC Press著作権 — **商用利用不可**
- **内容**: 12,000語、日本語訳付き、12段階レベル
- **注意**: GitHubにあるが著作権的に使用不可

#### 9. Oxford 3000/5000 ❌商用不可
- **ライセンス**: Oxford University Press著作権
- **注意**: CEFR分類付きだがライセンス取得が必要

#### 10. JACET 8000 ❌商用不可
- **ライセンス**: JACET著作権
- **注意**: 使用不可

---

### C. 発音記号（IPA）

#### 11. CMU Pronouncing Dictionary ★推奨
- **URL**: http://www.speech.cs.cmu.edu/cgi-bin/cmudict
- **ライセンス**: BSD-2-Clause — 商用可
- **形式**: テキスト（ARPAbetフォーマット）
- **内容**: 134,000+語のアメリカ英語発音、ストレスマーカー付き
- **IPA変換**: 
  - cmudict-ipa (https://github.com/menelik3/cmudict-ipa) — 変換済み
  - arpabet-to-ipa (https://github.com/wwesantos/arpabet-to-ipa) — MIT

#### 12. IPA-Dict
- **URL**: https://github.com/open-dict-data/ipa-dict
- **ライセンス**: MIT
- **内容**: 31言語のIPA。en_US（米語）とen_UK（英語）の両方あり

#### 13. Wiktionary IPA（Kaikki.org経由）
- 上記3と同じデータソース。soundsフィールドにIPA含む
- カバー率: 全エントリの約10%だが、一般的な単語は大体カバー

---

### D. 例文

#### 14. Tatoeba ★推奨
- **URL**: https://tatoeba.org/en/downloads
- **ライセンス**: CC BY 2.0 FR — 商用可
- **内容**: 英日ペア約117,000組（manythings.org/ankiで整形済み）
- **品質**: 田中コーパス由来のものは高品質。学習者投稿は品質にばらつき

#### 15. 田中コーパス (Tanaka Corpus)
- **URL**: http://edrdg.org/wiki/index.php/Tanaka_Corpus
- **ライセンス**: CC BY-SA 3.0 — 商用可
- **内容**: 約150,000の英日文ペア
- **品質**: 大学教授と学生が作成、Jim Breen氏が編集。Tatoeba内に含まれる

#### 16. OpenSubtitles ⚠️リスク
- **ライセンス**: 字幕の著作権は映画/TVスタジオに帰属 — **商用利用は法的に不確実**

---

### E. 音声データ

#### 17. Apple AVSpeechSynthesizer ★推奨
- iOS SDKに含まれる。無料、オフライン対応、英語・日本語両方
- データ管理不要、API料金なし

#### 18. Forvo API（有料）
- 月額$28.95〜（商用Small Business）
- 6M+の人間による発音。ただし音声の再配布不可

#### 19. Wikimedia Commons / Lingua Libre
- **ライセンス**: CC BY-SA 4.0
- 英語発音ファイル約1,200件 — カバー率が低い

#### 20. Wiktionary Audio（Kaikki.org経由）
- 全言語で約942,000音声ファイル。CC BY-SA
- 英語のカバー率はそのサブセット

---

## ライセンス一覧

| リソース | ライセンス | 商用OK | 帰属表示 |
|---|---|:---:|:---:|
| EJDict | CC0 1.0 | ✅ | 不要 |
| JMdict | CC BY-SA 4.0 | ✅ | 必須 |
| Wiktextract | CC BY-SA 3.0/4.0 | ✅ | 必須+SA |
| CEFR-J | 商用無料 | ✅ | 必須 |
| NGSL | CC BY-SA 4.0 | ✅ | 必須 |
| Words-CEFR-Dataset | MIT | ✅ | 必須 |
| CMU Dict | BSD-2-Clause | ✅ | 必須 |
| IPA-Dict | MIT | ✅ | 必須 |
| Tatoeba | CC BY 2.0 FR | ✅ | 必須 |
| 田中コーパス | CC BY-SA 3.0 | ✅ | 必須 |
| Japanese WordNet | BSD系 | ✅ | 必須 |
| AVSpeechSynthesizer | iOS SDK | ✅ | 不要 |
| SVL12000 | ALC著作権 | ❌ | — |
| Oxford 3000/5000 | OUP著作権 | ❌ | — |
| JACET 8000 | JACET著作権 | ❌ | — |
| Forvo | 有料プロプライエタリ | 💰 | 必須 |

---

## 推奨組み合わせ案

### 案1: EJDict中心（シンプル、最も安全）
```
CEFR-J (レベル) → EJDict (英→日訳, CC0) → CMU Dict (IPA) → Tatoeba (例文)
```
- メリット: EJDictはCC0で制限なし、英→日方向で自然な訳
- デメリット: 読み仮名がない（別途JMdictから補完が必要）

### 案2: Wiktionary中心（最も高機能）
```
CEFR-J (レベル) → Wiktextract (訳+IPA+品詞+例文) → JMdict (補完) → CMU Dict (IPA補完)
```
- メリット: 1つのソースからIPA・訳・品詞・例文がすべて取れる
- デメリット: 生データ2.4GB、フィルタリング処理が必要、日本語訳のカバー率は部分的

### 案3: ハイブリッド（推奨）
```
CEFR-J (レベル)
  + EJDict (主翻訳, CC0)
  + JMdict (読み仮名・品詞補完, 優先度コード活用, CC BY-SA)
  + CMU Dict → IPA変換 (発音記号, BSD)
  + Tatoeba (例文, CC BY)
  + AVSpeechSynthesizer (音声, iOS SDK)
```
- メリット: 各データソースの長所を組み合わせ。訳はEJDict、読みはJMdict、発音はCMU
- デメリット: パイプラインが複雑になる

---

## 次のアクション

上記の案から使用するデータソースを選択してください。選択後、`Tools/build_dictionary.py` を更新してデータパイプラインを再構築します。
