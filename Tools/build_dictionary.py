#!/usr/bin/env python3
"""
Build dictionary.sqlite from CEFR-J CSV files.
Source: CEFR-J/CEFR-J_A1.csv ~ CEFR-J_B2.csv

Output: Sources/KarutaApp/Resources/dictionary.sqlite
"""

import csv
import re
import sqlite3
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
CEFRJ_DIR = PROJECT_DIR / "CEFR-J"
OUTPUT_DB = PROJECT_DIR / "Sources" / "KarutaApp" / "Resources" / "dictionary.sqlite"

CSV_FILES = {
    "A1": "CEFR-J_A1.csv",
    "A2": "CEFR-J_A2.csv",
    "B1": "CEFR-J_B1.csv",
    "B2": "CEFR-J_B2.csv",
}


def extract_topics(supplement: str) -> str:
    """Extract topic tags from supplement field."""
    topics = set()
    for line in supplement.split("\n"):
        line = line.strip()
        if ":" in line:
            val = line.split(":", 1)[1].strip()
            if val:
                for t in val.split(","):
                    t = t.strip()
                    if t and t not in ("CoreInventory_1", "CoreInventory 2", "Threshold"):
                        topics.add(t)
    return "; ".join(sorted(topics))


def remove_brackets_with_contents(text: str) -> str:
    """Remove all bracket types and their contents.
    Order matters - process [[...]] FIRST before [...] single brackets.
    Handles: () （） 〈〉 《》 【】 [[]] [] ｟｠ * **
    Keeps: 『』 (removes only brackets, keeps contents)
    """
    # 1. Double square brackets [[X]] -> X (keep content) — must be BEFORE single [...]
    text = re.sub(r'\[\[([^\]]*)\]\]', r'\1', text, flags=re.DOTALL)

    # 2. Single square brackets [X] -> remove brackets AND content
    text = re.sub(r'\[[^\]]*\]', '', text, flags=re.DOTALL)

    # 3. Standard brackets with contents
    text = re.sub(r'\([^)]*\)', '', text, flags=re.DOTALL)
    text = re.sub(r'（[^）]*）', '', text, flags=re.DOTALL)
    text = re.sub(r'〈[^〉]*〉', '', text, flags=re.DOTALL)
    text = re.sub(r'《[^》]*》', '', text, flags=re.DOTALL)
    text = re.sub(r'【[^】]*】', '', text, flags=re.DOTALL)
    text = re.sub(r'｟[^｠]*｠', '', text, flags=re.DOTALL)
    text = re.sub(r'\{[^}]*\}', '', text, flags=re.DOTALL)
    text = re.sub(r'〖[^〗]*〗', '', text, flags=re.DOTALL)
    # Remove leftover stray uppercase U/C followed by ) (broken bracket leak: "U〉UC〉")
    text = re.sub(r'[UC]〉', '', text)
    text = re.sub(r'〈[UC]', '', text)

    # 4. Keep contents of 『』 but remove brackets
    text = text.replace('『', '').replace('』', '')

    # 5. Remove asterisks (markdown-like emphasis): *text* or **text** -> text
    text = re.sub(r'\*+', '', text)

    # 6. Remove single quotes (curly variants too)
    text = text.replace("'", "").replace("\u2018", "").replace("\u2019", "")

    return text


def post_clean(first: str) -> str:
    """Post-cleanup of the extracted first meaning.
    - If only symbols remain (= ~ etc.), return empty so caller falls back.
    - If only single-letter ASCII U/C remain, also reject.
    - Strip orphan brackets (one side only).
    """
    s = first.strip()
    if not s:
        return ""

    # Remove standalone uppercase U / C tokens (countable/uncountable markers)
    # that may have leaked from 〈U〉〈C〉〈U/C〉 brackets
    s = re.sub(r'(?<![A-Za-z])[UC](?![A-Za-z])', '', s)
    s = s.strip()

    # Cut off after ; or ； (anything after a semicolon is supplementary)
    s = re.split(r'[;；]', s)[0]
    s = s.strip()

    if not s:
        return ""

    # Reject if only symbols (=, ~, punctuation, whitespace)
    if re.fullmatch(r'[=~\-_,.;:。、・\s]+', s):
        return ""

    # Remove orphan opening brackets (no matching close)
    open_to_close = {'(': ')', '（': '）', '〈': '〉', '《': '》', '【': '】', '｟': '｠'}
    close_to_open = {v: k for k, v in open_to_close.items()}

    # If no matching open found for a close char anywhere in s, drop it
    for close_ch, open_ch in close_to_open.items():
        if close_ch in s and open_ch not in s:
            s = s.replace(close_ch, '')
    for open_ch, close_ch in open_to_close.items():
        if open_ch in s and close_ch not in s:
            s = s.replace(open_ch, '')

    return s.strip()


def split_top_level(text: str, separators: set[str]) -> list[str]:
    """Split text by separators, but ONLY at top level (outside any brackets)."""
    open_chars = set("([{（〈《【｟『〖")
    pair = {
        '(': ')', '[': ']', '{': '}',
        '（': '）', '〈': '〉', '《': '》', '【': '】', '｟': '｠', '『': '』', '〖': '〗'
    }
    parts = []
    buf = []
    stack = []
    for ch in text:
        if ch in open_chars:
            stack.append(pair[ch])
            buf.append(ch)
        elif stack and ch == stack[-1]:
            stack.pop()
            buf.append(ch)
        elif not stack and ch in separators:
            parts.append(''.join(buf))
            buf = []
        else:
            buf.append(ch)
    if buf:
        parts.append(''.join(buf))
    return parts


def extract_first_meaning(meaning_ja: str) -> str:
    """Extract the first/primary meaning for karuta display."""
    if not meaning_ja:
        return ""

    # Step 1: Split by / or ; or ； at TOP LEVEL only (so brackets are preserved)
    parts = split_top_level(meaning_ja.strip(), {'/', ';', '；'})
    parts = [p.strip() for p in parts if p.strip()]

    if not parts:
        return ""

    # Try each part in order, return first that survives processing + post-cleanup
    for part in parts:
        # 1. Cut at 《 (everything from 《 onward is supplementary) — top level only
        cuts = split_top_level(part, {'《'})
        candidate = cuts[0] if cuts else part
        # 2. Remove all bracket types and their contents
        candidate = remove_brackets_with_contents(candidate)
        # 3. Take text before first comma (, or ， or 、) — top level only
        commaCuts = split_top_level(candidate, {',', '，', '、'})
        candidate = commaCuts[0] if commaCuts else candidate
        # 4. Normalize whitespace
        candidate = re.sub(r'\s+', ' ', candidate).strip()
        # 5. Post-cleanup
        candidate = post_clean(candidate)
        if candidate:
            return candidate

    return ""


def extract_all_meanings(meaning_ja: str) -> list[str]:
    """Extract all meanings as a list."""
    if not meaning_ja:
        return []

    parts = re.split(r'\s*/\s*', meaning_ja)
    meanings = []
    for p in parts:
        p = p.strip()
        if not p:
            continue
        # Clean for display but keep some context
        p = re.sub(r'\[\[([^\]]*)\]\]', r'\1', p)
        p = p.strip()
        if p:
            meanings.append(p)
    return meanings


def build_database():
    print("=== Building Karuta Dictionary from CEFR-J CSVs ===\n")

    OUTPUT_DB.parent.mkdir(parents=True, exist_ok=True)
    if OUTPUT_DB.exists():
        OUTPUT_DB.unlink()

    conn = sqlite3.connect(str(OUTPUT_DB))
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            headword TEXT NOT NULL,
            headword_raw TEXT NOT NULL,
            pos TEXT NOT NULL,
            cefr_level TEXT NOT NULL,
            first_meaning TEXT NOT NULL,
            meaning_raw TEXT NOT NULL,
            all_meanings TEXT NOT NULL,
            ipa TEXT,
            topic TEXT,
            example_en TEXT,
            example_ja TEXT
        )
    """)
    cur.execute("CREATE INDEX idx_cefr ON entries(cefr_level)")
    cur.execute("CREATE INDEX idx_topic ON entries(topic)")
    cur.execute("CREATE INDEX idx_headword ON entries(headword)")

    stats = {}
    skipped = 0

    for level, filename in CSV_FILES.items():
        filepath = CEFRJ_DIR / filename
        if not filepath.exists():
            print(f"  [skip] {filename} not found")
            continue

        count = 0
        with open(filepath, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                headword_raw = row.get("headword", "").strip()
                pos = row.get("pos", "").strip()
                meaning_ja = row.get("meaning_ja", "").strip()

                if not headword_raw or not meaning_ja:
                    skipped += 1
                    continue

                # Take first form only when multiple variants are listed (e.g., "color/colour" -> "color")
                headword = headword_raw.split("/")[0].strip()

                # Skip function words that don't work well for karuta
                if pos in ("determiner", "conjunction", "preposition", "pronoun") and len(headword) <= 3:
                    skipped += 1
                    continue

                first_meaning = extract_first_meaning(meaning_ja)
                if not first_meaning or len(first_meaning) < 1:
                    skipped += 1
                    continue

                # Filter: reject first_meaning containing "=" or "＝"
                if '=' in first_meaning or '＝' in first_meaning:
                    skipped += 1
                    continue

                # Filter: reject first_meaning containing ASCII letters,
                # EXCEPT for a short allowlist of headwords where ascii is expected
                ALLOWED_ASCII_HEADWORDS = {"either", "molecule", "account"}
                if re.search(r'[a-zA-Z]', first_meaning) and headword not in ALLOWED_ASCII_HEADWORDS:
                    skipped += 1
                    continue

                all_meanings_list = extract_all_meanings(meaning_ja)
                all_meanings_json = "\n".join(all_meanings_list)

                ipa = row.get("ipa", "").strip()
                topic = extract_topics(row.get("supplement", ""))
                example_en = row.get("example_sentence", "").strip()
                example_ja = row.get("translated_sentence", "").strip()

                cur.execute("""
                    INSERT INTO entries (headword, headword_raw, pos, cefr_level, first_meaning, meaning_raw, all_meanings, ipa, topic, example_en, example_ja)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (headword, headword_raw, pos, level, first_meaning, meaning_ja, all_meanings_json, ipa or None, topic or None, example_en or None, example_ja or None))
                count += 1

        stats[level] = count
        print(f"  {level}: {count} entries")

    conn.commit()

    # Topic stats
    cur.execute("SELECT topic, COUNT(*) FROM entries WHERE topic IS NOT NULL AND topic != '' GROUP BY topic ORDER BY COUNT(*) DESC LIMIT 20")
    topic_rows = cur.fetchall()

    total = sum(stats.values())
    print(f"\n  Total: {total} entries (skipped: {skipped})")
    print(f"\n  Top topics:")
    for t, c in topic_rows:
        print(f"    {c:4d}  {t}")

    conn.close()
    print(f"\n  Output: {OUTPUT_DB}")
    print("=== Done ===")


if __name__ == "__main__":
    build_database()
