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
    Uses re.DOTALL so multi-line bracket contents are also removed.
    Handles: () （） 〈〉 《》 【】 [[]]
    Keeps: 『』 (removes only brackets, keeps contents)
    """
    # Remove brackets WITH contents (including newlines/spaces)
    text = re.sub(r'\([^)]*\)', '', text, flags=re.DOTALL)
    text = re.sub(r'（[^）]*）', '', text, flags=re.DOTALL)
    text = re.sub(r'〈[^〉]*〉', '', text, flags=re.DOTALL)
    text = re.sub(r'《[^》]*》', '', text, flags=re.DOTALL)
    text = re.sub(r'【[^】]*】', '', text, flags=re.DOTALL)
    text = re.sub(r'\[\[[^\]]*\]\]', '', text, flags=re.DOTALL)

    # Keep contents of 『』 but remove brackets
    text = text.replace('『', '').replace('』', '')

    # Remove single quotes (curly variants too)
    text = text.replace("'", "").replace("\u2018", "").replace("\u2019", "")

    return text


def extract_first_meaning(meaning_ja: str) -> str:
    """Extract the first/primary meaning for karuta display.
    Order matters:
    1. Remove all brackets+contents FIRST (so internal / and , don't break splitting)
    2. Split by / or ; to get individual meanings
    3. Take first non-empty meaning
    4. Take text before first comma ,
    5. Normalize whitespace (collapse multi-line/multi-space)
    """
    if not meaning_ja:
        return ""

    # Step 1: Remove all brackets and contents first
    cleaned = remove_brackets_with_contents(meaning_ja)

    # Step 2: Split by / or ; to get individual meanings
    parts = re.split(r'\s*/\s*|;\s*', cleaned)
    parts = [p for p in parts if p.strip()]

    if not parts:
        return ""

    # Step 3: Take first meaningful part
    first = parts[0]

    # Step 4: Take text before first comma
    first = re.split(r'[,]', first)[0]

    # Step 5: Normalize whitespace - collapse newlines and multiple spaces
    first = re.sub(r'\s+', ' ', first).strip()

    # Fallback: try next part if empty
    if not first and len(parts) > 1:
        second = re.split(r'[,]', parts[1])[0]
        first = re.sub(r'\s+', ' ', second).strip()

    return first


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
