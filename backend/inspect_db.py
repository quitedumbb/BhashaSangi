import sys
from database import engine, sqlite_engine, use_sqlite, text

def inspect_database():
    sys.stdout.reconfigure(encoding='utf-8')
    print("=" * 65)
    print(" 🗄️ BHASHA SANGI - DATABASE DATA INSPECTOR")
    print("=" * 65)

    import os
    db_host = os.getenv("DB_HOST", "127.0.0.1")
    db_port = os.getenv("DB_PORT", "3306")
    active_db = "Local SQLite (bhasha_sangi.db)" if use_sqlite else f"Cloud MySQL ({db_host}:{db_port})"
    print(f"• Active Backend Database: {active_db}\n")

    # 1. Teachers / Users Table
    print("--- [ 1. REGISTERED TEACHERS ] ---")
    try:
        with engine.connect() as conn:
            teachers = conn.execute(text("SELECT id, username, full_name, email, school_name, district, primary_grade FROM teachers")).fetchall()
            if not teachers:
                print("   (No teachers found)")
            for t in teachers:
                print(f"   • ID: {t[0]} | User: {t[1]} | Name: {t[2]} | School: {t[4]} | District: {t[5]} | Grade: {t[6]}")
    except Exception as e:
        print(f"   Error reading teachers: {e}")

    # 2. Translations History Table
    print("\n--- [ 2. RECENT CLASSROOM TRANSLATIONS ] ---")
    try:
        with engine.connect() as conn:
            trans = conn.execute(text("SELECT id, session_tag, source_text, translated_text FROM translations ORDER BY id DESC LIMIT 5")).fetchall()
            if not trans:
                print("   (No translations yet)")
            for tr in trans:
                print(f"   • [Tag: {tr[1]}] Original: {tr[2]}")
                print(f"     Translated: {tr[3]}\n")
    except Exception as e:
        print(f"   Error reading translations: {e}")

    # 3. Learning Flashcards Sample
    print("--- [ 3. DAILY LEARNING FLASHCARDS (Sample) ] ---")
    try:
        with engine.connect() as conn:
            cards = conn.execute(text("SELECT id, word_en, word_hi, word_vernacular, roman_phonetic FROM learning_cards LIMIT 5")).fetchall()
            for c in cards:
                print(f"   • English: {c[1]} | Hindi: {c[2]} | Santali (Ol Chiki): {c[3]} ({c[4]})")
    except Exception as e:
        print(f"   Error reading learning cards: {e}")

    # 4. Curriculum Chapters Sample
    print("\n--- [ 4. CURRICULUM LESSONS (Class 1 to 8 Summary) ] ---")
    try:
        with engine.connect() as conn:
            grade_counts = conn.execute(text("SELECT grade_level, count(*) FROM lessons GROUP BY grade_level ORDER BY grade_level")).fetchall()
            for gc in grade_counts:
                print(f"   • {gc[0]}: {gc[1]} chapters loaded")
    except Exception as e:
        print(f"   Error reading curriculum: {e}")

    print("\n" + "=" * 65)

if __name__ == "__main__":
    inspect_database()
