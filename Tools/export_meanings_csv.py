#!/usr/bin/env python3
"""
Export all dictionary entries to a CSV for visual inspection.

Output columns:
    id, cefr_level, headword, pos, first_meaning, meaning_raw,
    length, example_ja, topic

`first_meaning` is what is displayed on the karuta Japanese card.
`meaning_raw` is the original CEFR-J meaning before processing.
`length` is the character count of `first_meaning` so you can sort
to find unusually long/short entries that may look broken.

Output: Tools/karuta_meanings.csv
"""

import csv
import sqlite3
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
DB_PATH = PROJECT_DIR / "Sources" / "KarutaApp" / "Resources" / "dictionary.sqlite"
OUTPUT_CSV = SCRIPT_DIR / "karuta_meanings.csv"


def export():
    if not DB_PATH.exists():
        print(f"ERROR: dictionary.sqlite not found at {DB_PATH}")
        return

    conn = sqlite3.connect(str(DB_PATH))
    cur = conn.cursor()

    cur.execute("""
        SELECT id, cefr_level, headword, pos, first_meaning, meaning_raw, example_ja, topic
        FROM entries
        ORDER BY cefr_level, headword
    """)

    rows = cur.fetchall()
    conn.close()

    with open(OUTPUT_CSV, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerow([
            "id",
            "cefr_level",
            "headword",
            "pos",
            "first_meaning",
            "length",
            "meaning_raw",
            "example_ja",
            "topic",
        ])
        for row in rows:
            id_, level, headword, pos, first_meaning, meaning_raw, example_ja, topic = row
            writer.writerow([
                id_,
                level,
                headword,
                pos,
                first_meaning,
                len(first_meaning) if first_meaning else 0,
                meaning_raw,
                example_ja or "",
                topic or "",
            ])

    print(f"Exported {len(rows)} entries to {OUTPUT_CSV}")
    print("\nTip: Excel/Numbers で開いて 'length' 列を降順ソートすると")
    print("     長すぎる/おかしい訳が見つけやすいです。")


if __name__ == "__main__":
    export()
