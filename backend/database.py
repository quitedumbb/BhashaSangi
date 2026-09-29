import os
import sys
from urllib.parse import quote_plus
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "mysql-3f9cc0fd-bhashasangi1.c.aivencloud.com")
DB_PORT = os.getenv("DB_PORT", "11143")
DB_USER = os.getenv("DB_USER", "avnadmin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "defaultdb")
DB_SSL_MODE = os.getenv("DB_SSL_MODE", "REQUIRED")

encoded_password = quote_plus(DB_PASSWORD) if DB_PASSWORD else ""

MYSQL_URL = (
    f"mysql+pymysql://{DB_USER}:{encoded_password}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# Dedicated local SQLite engine for offline synchronization
SQLITE_URL = "sqlite:///./bhasha_sangi.db"
sqlite_engine = create_engine(
    SQLITE_URL,
    connect_args={"check_same_thread": False}
)
SqliteSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=sqlite_engine
)

# Connect args with SSL support for Aiven Cloud MySQL
mysql_connect_args = {"connect_timeout": 8}
if DB_SSL_MODE or "aivencloud.com" in DB_HOST.lower():
    mysql_connect_args["ssl"] = {"ssl_mode": "REQUIRED"}

# Attempt connection to MySQL; if unavailable, seamlessly fallback to local SQLite
use_sqlite = False
try:
    temp_engine = create_engine(
        MYSQL_URL,
        connect_args=mysql_connect_args
    )
    with temp_engine.connect() as conn:
        print(f"[DATABASE] Successfully connected to Cloud MySQL at {DB_HOST}:{DB_PORT} ({DB_NAME})!")
    engine = temp_engine
except Exception as e:
    print(f"[DATABASE] MySQL not available ({e}).")
    print("[DATABASE] Activating seamless local SQLite fallback (bhasha_sangi.db)...")
    use_sqlite = True
    engine = sqlite_engine

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


def init_db():
    """Initializes tables and seeds default curriculum on the active database engine."""
    ai_syntax = "INTEGER PRIMARY KEY AUTOINCREMENT" if use_sqlite else "INT AUTO_INCREMENT PRIMARY KEY"
    ignore_syntax = "INSERT OR IGNORE" if use_sqlite else "INSERT IGNORE"

    with engine.begin() as conn:
        # 1. Languages table
        conn.execute(text(f"""
            CREATE TABLE IF NOT EXISTS languages (
                id {ai_syntax},
                language_code VARCHAR(10) NOT NULL,
                language_name VARCHAR(50) NOT NULL,
                native_name VARCHAR(100) NOT NULL,
                script VARCHAR(50) NOT NULL,
                is_active BOOLEAN DEFAULT TRUE
            );
        """))

        # 2. Lessons table
        conn.execute(text(f"""
            CREATE TABLE IF NOT EXISTS lessons (
                id {ai_syntax},
                lesson_title VARCHAR(150) NOT NULL,
                grade_level VARCHAR(20) DEFAULT 'Primary',
                subject VARCHAR(50) DEFAULT 'General'
            );
        """))

        # 3. Translations table
        conn.execute(text(f"""
            CREATE TABLE IF NOT EXISTS translations (
                id {ai_syntax},
                lesson_id INTEGER,
                source_language_id INTEGER NOT NULL,
                target_language_id INTEGER NOT NULL,
                dialect_id INTEGER,
                source_text TEXT NOT NULL,
                translated_text TEXT NOT NULL,
                session_tag VARCHAR(100) DEFAULT 'General Classroom',
                translation_method VARCHAR(50) DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))

        # 4. Chapter Notes table (AI Generated Curriculum Notes)
        conn.execute(text(f"""
            CREATE TABLE IF NOT EXISTS chapter_notes (
                id {ai_syntax},
                lesson_id INTEGER NOT NULL,
                target_language_id INTEGER NOT NULL,
                notes_json TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(lesson_id, target_language_id)
            );
        """))

        # 5. Classroom Speech Sessions table
        conn.execute(text(f"""
            CREATE TABLE IF NOT EXISTS classroom_sessions (
                id {ai_syntax},
                session_name VARCHAR(150) NOT NULL,
                folder_tag VARCHAR(100) NOT NULL,
                lesson_id INTEGER,
                target_language_id INTEGER NOT NULL DEFAULT 1,
                raw_transcript TEXT,
                notes_json TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))

        # 6. Learning Cards table (Daily Flashcards with Vernacular & Hindi)
        conn.execute(text(f"""
            CREATE TABLE IF NOT EXISTS learning_cards (
                id {ai_syntax},
                word_en VARCHAR(100) NOT NULL,
                word_hi VARCHAR(100) NOT NULL,
                word_vernacular VARCHAR(100) NOT NULL,
                roman_phonetic VARCHAR(100) DEFAULT '',
                category VARCHAR(50) DEFAULT 'Everyday Vocabulary',
                example_sentence_en TEXT,
                example_sentence_hi TEXT,
                example_sentence_vernacular TEXT,
                target_language_id INTEGER NOT NULL DEFAULT 1,
                audio_base64 TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(word_en, target_language_id)
            );
        """))

        # 7. Teachers / Users table (Auth & Classroom Profiles)
        conn.execute(text(f"""
            CREATE TABLE IF NOT EXISTS teachers (
                id {ai_syntax},
                username VARCHAR(100) UNIQUE NOT NULL,
                full_name VARCHAR(150) NOT NULL,
                email VARCHAR(150),
                password_hash VARCHAR(255) NOT NULL,
                school_name VARCHAR(200) DEFAULT 'Govt. Primary School',
                district VARCHAR(100) DEFAULT 'Dumka',
                state VARCHAR(100) DEFAULT 'Jharkhand',
                primary_grade VARCHAR(50) DEFAULT 'Classes 1 - 8',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """))

        # Check if languages are populated
        count = conn.execute(text("SELECT COUNT(*) FROM languages")).scalar()
        if count == 0:
            conn.execute(text(f"""
                {ignore_syntax} INTO languages (id, language_code, language_name, native_name, script, is_active) VALUES
                (1, 'sat', 'Santali', 'ᱥᱟᱱᱛᱟᱲᱤ', 'Ol Chiki', 1),
                (2, 'hoc', 'Ho', '𑢹𑣉', 'Warang Chiti', 1),
                (3, 'unr', 'Mundari', 'मुण्डारी', 'Nagari / Mundari Bani', 1),
                (4, 'hin', 'Hindi', 'हिन्दी', 'Devanagari', 1),
                (5, 'ben', 'Bengali', 'বাংলা', 'Bengali-Assamese', 1),
                (6, 'ori', 'Odia', 'ଓଡ଼ᱤଆ', 'Odia', 1),
                (7, 'eng', 'English', 'English', 'Latin', 1);
            """))

        # Check and populate curriculum lessons for Class 1 through Class 8
        base_curriculum = [
            ("Science: Ch 1 - Poonam's Day Out (Animals & Birds Around Us)", "Science / EVS (JCERT)"),
            ("Science: Ch 2 - The Plant Fairy (Leaves, Trees & Forest Roots)", "Science / EVS (JCERT)"),
            ("Science: Ch 3 - Water O Water! (Sources & Clean Drinking Habits)", "Science / EVS (JCERT)"),
            ("Science: Ch 4 - Our First School (Family & Tribal Heritage)", "Science / EVS (JCERT)"),
            ("Science: Ch 5 - Chhotu's House (Shelter & Clean Classroom Living)", "Science / EVS (JCERT)"),
            ("Science: Ch 6 - Foods We Eat (Grains, Nutrition & Balanced Diet)", "Science / EVS (JCERT)"),
            ("Science: Ch 7 - Flying High (Birds, Beaks & Habitats)", "Science / EVS (JCERT)"),
            ("Science: Ch 8 - Clouds & Rain (Monsoon, Soil & Farming)", "Science / EVS (JCERT)"),
            ("English: Unit 1 - Good Morning & The Magic Garden", "English (JCERT / CBSE)"),
            ("English: Unit 2 - Bird Talk & Nina and the Baby Sparrows", "English (JCERT / CBSE)"),
            ("English: Unit 3 - Little by Little & The Enormous Turnip", "English (JCERT / CBSE)"),
            ("English: Unit 4 - Sea Song & A Little Fish Story", "English (JCERT / CBSE)"),
            ("English: Unit 5 - The Balloon Man & The Yellow Butterfly", "English (JCERT / CBSE)"),
            ("English: Unit 6 - Trains & The Story of the Road", "English (JCERT / CBSE)"),
            ("English: Unit 7 - Puppy and I & Little Tiger, Big Tiger", "English (JCERT / CBSE)"),
            ("English: Unit 8 - What's in the Mailbox? & My Silly Sister", "English (JCERT / CBSE)"),
            ("English: Unit 9 - He Is My Brother & How Creatures Move", "English (JCERT / CBSE)")
        ]

        for c in range(1, 9):
            grade_name = f"Class {c}"
            g_count = conn.execute(text("SELECT COUNT(*) FROM lessons WHERE grade_level = :g"), {"g": grade_name}).scalar() or 0
            if g_count < 10:
                for idx, (title, subj) in enumerate(base_curriculum, start=1):
                    lesson_id = (c * 100 + idx)
                    lesson_title = f"{grade_name} {title}"
                    conn.execute(text(f"""
                        {ignore_syntax} INTO lessons (id, lesson_title, grade_level, subject)
                        VALUES (:lid, :ltitle, :glevel, :subj)
                    """), {
                        "lid": lesson_id,
                        "ltitle": lesson_title,
                        "glevel": grade_name,
                        "subj": subj
                    })

        # Check and populate learning cards
        card_count = conn.execute(text("SELECT COUNT(*) FROM learning_cards")).scalar()
        if card_count == 0:
            seed_cards = [
                ("Water", "पानी", "ᱫᱟᱜ", "Da'", "Nature & Daily Life", "We drink clean water every day.", "हम रोज साफ पानी पीते हैं।", "ᱟᱵᱚ ᱫᱤᱱᱟᱹᱢ ᱜᱮ ᱥᱟᱯᱷᱟ ᱫᱟᱜ ᱵᱚ ᱧᱩᱭᱟ ᱾", 1),
                ("Tree", "पेड़", "ᱫᱟᱨᱮ", "Dare", "Nature & Environment", "Trees give us sweet fruits and cool shade.", "पेड़ हमें मीठे फल और ठंडी छाया देते हैं।", "ᱫᱟᱨᱮ ᱟᱵᱚ ᱦᱮᱲᱮᱢ ᱡᱚ ᱟᱨ ᱨᱮᱭᱟᱲ ᱩᱢᱩᱞ ᱮ ᱮᱢᱟᱵᱚᱱᱟ ᱾", 1),
                ("Sun", "सूरज", "ᱥᱤᱝᱜᱤ", "Singi", "Science & Sky", "The morning sun shines bright in the sky.", "सुबह का सूरज आकाश में चमकता है।", "ᱥᱮᱛᱟᱜ ᱥᱤᱝᱜᱤ ᱥᱮᱨᱢᱟ ᱨᱮ ᱡᱷᱟᱞᱠᱟᱣᱜ-ᱟ ᱾", 1),
                ("Book", "किताब", "ᱯᱚᱛᱚᱵ", "Potob", "School & Learning", "I read my school book carefully.", "मैं अपनी स्कूल की किताब ध्यान से पढ़ता हूँ।", "ᱤᱧ ᱟᱥᱲᱟ ᱯᱚᱛᱚᱵ ᱫᱷᱮᱭᱟᱱ ᱛᱮᱧ ᱯᱟᱲᱦᱟᱣᱟ ᱾", 1),
                ("Friend", "दोस्त / मित्र", "ᱜᱟᱛᱮ", "Gate", "Community & Friends", "Friends play together in the playground.", "दोस्त खेल के मैदान में साथ खेलते हैं।", "ᱜᱟᱛᱮ ᱠᱚ ᱠᱷᱮᱞᱚᱸᱰ ᱴᱟᱺᱰᱤ ᱨᱮᱠᱚ ᱮᱱᱮᱡ-ᱟ ᱾", 1),
                ("Bird", "पक्षी / चिड़िया", "ᱪᱮᱬᱮ", "Ceñe", "Animals & Birds", "A little bird sings sweetly on the branch.", "एक छोटी चिड़िया डाल पर मीठा गाती है।", "ᱢᱤᱫ ᱠᱟᱹᱴᱤᱡ ᱪᱮᱬᱮ ᱰᱟᱹᱨ ᱨᱮ ᱥᱤᱵᱤᱞ ᱮ ᱥᱮᱨᱮᱧᱟ ᱾", 1),
                ("Flower", "फूल", "ᱵᱟᱦᱟ", "Baha", "Nature & Garden", "Colorful flowers bloom in spring season.", "वसंत ऋतु में रंग-बिरंगे फूल खिलते हैं।", "ᱵᱟᱦᱟ ᱨᱤᱛᱩ ᱨᱮ ᱨᱚᱝ-ᱵᱮᱨᱚᱝ ᱵᱟᱦᱟ ᱯᱷᱩᱴᱟᱹᱣᱜ-ᱟ ᱾", 1),
                ("School", "विद्यालय / स्कूल", "ᱟᱥᱲᱟ", "Asṛa", "School & Learning", "Children walk happily to school every morning.", "बच्चे रोज सुबह खुशी से स्कूल जाते हैं।", "ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱥᱮᱛᱟᱜ ᱨᱟᱹᱥᱠᱟᱹ ᱛᱮ ᱟᱥᱲᱟ ᱠᱚ ᱥᱮᱱᱚᱜ-ᱟ ᱾", 1),
                ("Mother", "मां / माता", "ᱟᱭᱳ", "Ayo", "Family & Home", "Mother cooks delicious healthy food for us.", "मां हमारे लिए स्वादिष्ट खाना बनाती है।", "ᱟᱭᱳ ᱟᱵᱚ ᱞᱟᱹᱜᱤᱫ ᱥᱤᱵᱤᱞ ᱡᱚᱢᱟᱜ ᱮ ᱛᱮᱭᱟᱨᱟ ᱾", 1),
                ("Father", "पिता / बाबा", "ᱵᱟᱵᱟ", "Baba", "Family & Home", "Father teaches us kindness and honesty.", "पिताजी हमें भलाई और सच्चाई सिखाते हैं।", "ᱵᱟᱵᱟ ᱟᱵᱚ ᱥᱟᱹᱨᱤ ᱟᱨ ᱵᱷᱟᱹᱞᱟᱹᱭ ᱮ ᱥᱮᱪᱮᱫ ᱵᱚᱱᱟ ᱾", 1),
                ("Milk", "दूध", "ᱛᱳᱣᱟ", "Towa", "Food & Health", "Drinking milk makes growing children strong.", "दूध पीने से बच्चे मजबूत और स्वस्थ बनते हैं।", "ᱛᱳᱣᱟ ᱧᱩ ᱞᱮᱠᱷᱟᱱ ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱠᱮᱴᱮᱡᱚᱜ-ᱟ ᱾", 1),
                ("Earth", "धरती / पृथ्वी", "ᱫᱷᱟᱹᱨᱛᱤ", "Dhạrti", "Nature & Science", "We must protect our mother earth.", "हमें अपनी धरती माता की रक्षा करनी चाहिए।", "ᱟᱵᱚ ᱫᱷᱟᱹᱨᱛᱤ ᱟᱭᱳ ᱫᱩᱜ ᱫᱚᱦᱚ ᱦᱩᱭᱩᱜ ᱛᱟᱵᱚᱱᱟ ᱾", 1),
                ("Rain", "बारिश / वर्षा", "ᱫᱟᱜ-ᱡᱟᱹᱲᱤ", "Daq-jạṛi", "Nature & Weather", "Rain brings water to green paddy fields.", "बारिश से धान के हरे खेतों को पानी मिलता है।", "ᱫᱟᱜ-ᱡᱟᱹᱲᱤ ᱛᱮ ᱦᱟᱹᱨᱭᱟᱹᱲ ᱜᱚᱫᱷᱟᱱ ᱠᱷᱮᱛ ᱫᱟᱜ ᱧᱟᱢᱟ ᱾", 1),
                ("Leaf", "पत्ता", "ᱥᱟᱠᱟᱢ", "Sakam", "Plants & Trees", "Green leaves prepare food using sunlight.", "हरे पत्ते धूप की मदद से भोजन बनाते हैं।", "ᱦᱟᱹᱨᱭᱟᱹᱲ ᱥᱟᱠᱟᱢ ᱥᱤᱛᱩᱝ ᱛᱮ ᱡᱚᱢᱟᱜ ᱮ ᱵᱮᱱᱟᱣᱟ ᱾", 1),
                ("River", "नदी", "ᱜᱟᱰᱟ", "Gada", "Water & Geography", "The clean river flows across our village.", "स्वच्छ नदी हमारे गांव से होकर बहती है।", "ᱥᱟᱯᱷᱟ ᱜᱟᱰᱟ ᱟᱵᱚ ᱟᱹᱛᱩ ᱥᱮᱫ ᱛᱮ ᱞᱤᱸᱜᱤᱱ ᱠᱟᱱᱟ ᱾", 1),
                ("Fish", "मछली", "ᱦᱟᱹᱠᱩ", "Hạku", "Aquatic Animals", "Fish swim gracefully in the cool pond.", "मछलियां ठंडे तालाब में तैरती हैं।", "ᱦᱟᱹᱠᱩ ᱨᱮᱭᱟᱲ ᱯᱩᱠᱷᱨᱤ ᱨᱮᱠᱚ ᱯᱟᱭᱨᱟᱜ-ᱟ ᱾", 1),
                ("Elephant", "हाथी", "ᱦᱟᱹᱛᱤ", "Hạti", "Forest Animals", "The mighty elephant walks peacefully in the forest.", "विशाल हाथी जंगल में शांति से चलता है।", "ᱢᱟᱨᱟᱝ ᱦᱟᱹᱛᱤ ᱵᱤᱨ ᱨᱮ ᱥᱩᱞᱩᱠ ᱛᱮᱭ ᱛᱟᱲᱟᱢᱟ ᱾", 1),
                ("Night", "रात", "ᱧᱤᱫᱟᱹ", "Ñidạ", "Daily Life & Time", "Stars twinkle brightly in the night sky.", "रात के आकाश में तारे चमकते हैं।", "ᱧᱤᱫᱟᱹ ᱥᱮᱨᱢᱟ ᱨᱮ ᱤᱯᱤᱞ ᱠᱚ ᱡᱷᱟᱞᱠᱟᱣᱜ-ᱟ ᱾", 1),
                ("Morning", "सुबह / सवेरा", "ᱥᱮᱛᱟᱜ", "Setaq", "Daily Life & Time", "Wake up early in the morning and exercise.", "सुबह जल्दी उठें और व्यायाम करें।", "ᱥᱮᱛᱟᱜ ᱵᱮᱨᱮᱫ ᱠᱟᱛᱮ ᱠᱟᱹᱥᱨᱟᱹᱛ ᱢᱮ ᱾", 1),
                ("Wind", "हवा / वायु", "ᱦᱚᱭ", "Hoy", "Nature & Weather", "Cool wind blows gently through the trees.", "पेड़ों के बीच से ठंडी हवा बहती है।", "ᱫᱟᱨᱮ ᱛᱟᱞᱟ ᱛᱮ ᱨᱮᱭᱟᱲ ᱦᱚᱭ ᱦᱤᱥᱤᱫ-ᱟ ᱾", 1)
            ]
            for card in seed_cards:
                conn.execute(text(f"""
                    {ignore_syntax} INTO learning_cards
                    (word_en, word_hi, word_vernacular, roman_phonetic, category, example_sentence_en, example_sentence_hi, example_sentence_vernacular, target_language_id)
                    VALUES (:w_en, :w_hi, :w_ver, :phon, :cat, :ex_en, :ex_hi, :ex_ver, :tid)
                """), {
                    "w_en": card[0], "w_hi": card[1], "w_ver": card[2], "phon": card[3],
                    "cat": card[4], "ex_en": card[5], "ex_hi": card[6], "ex_ver": card[7], "tid": card[8]
                })

        # Check and seed default demo teacher
        try:
            teacher_count = conn.execute(text("SELECT COUNT(*) FROM teachers")).scalar()
            if teacher_count == 0:
                import hashlib
                default_hash = hashlib.sha256("password123".encode("utf-8")).hexdigest()
                conn.execute(text(f"""
                    {ignore_syntax} INTO teachers 
                    (username, full_name, email, password_hash, school_name, district, state, primary_grade)
                    VALUES 
                    ('sunita', 'Sunita Soren', 'sunita.soren@primary.edu.in', :phash, 'Govt. Primary School, Dumka', 'Dumka', 'Jharkhand', 'Classes 1 - 8')
                """), {"phash": default_hash})
        except Exception as te:
            print(f"[WARN] Teacher seeding notice: {te}")


def save_teacher_dual(username: str, full_name: str, email: str, password_hash: str,
                      school_name: str = "Govt. Primary School", district: str = "Dumka",
                      state: str = "Jharkhand", primary_grade: str = "Classes 1 - 8") -> dict:
    """Saves teacher profile in active database (Aiven Cloud MySQL or local SQLite) and syncs to SQLite."""
    params = {
        "username": username.strip(),
        "full_name": full_name.strip(),
        "email": email.strip() if email else f"{username.strip()}@primary.edu.in",
        "phash": password_hash,
        "school": school_name.strip() if school_name else "Govt. Primary School",
        "district": district.strip() if district else "Dumka",
        "state": state.strip() if state else "Jharkhand",
        "grade": primary_grade.strip() if primary_grade else "Classes 1 - 8"
    }

    # 1. Save in active engine (Aiven Cloud MySQL or local SQLite)
    primary_id = None
    try:
        with engine.begin() as pconn:
            if use_sqlite:
                res = pconn.execute(text("""
                    INSERT OR REPLACE INTO teachers 
                    (username, full_name, email, password_hash, school_name, district, state, primary_grade)
                    VALUES (:username, :full_name, :email, :phash, :school, :district, :state, :grade)
                """), params)
                primary_id = res.lastrowid
            else:
                # MySQL ON DUPLICATE KEY UPDATE syntax
                res = pconn.execute(text("""
                    INSERT INTO teachers 
                    (username, full_name, email, password_hash, school_name, district, state, primary_grade)
                    VALUES (:username, :full_name, :email, :phash, :school, :district, :state, :grade)
                    ON DUPLICATE KEY UPDATE 
                    full_name = VALUES(full_name),
                    password_hash = VALUES(password_hash),
                    school_name = VALUES(school_name),
                    district = VALUES(district),
                    state = VALUES(state),
                    primary_grade = VALUES(primary_grade)
                """), params)
                primary_id = res.lastrowid
    except Exception as pe:
        print(f"[WARN] Primary teacher save exception: {pe}")

    # 2. Dual save into local SQLite database for offline resilience
    if not use_sqlite:
        try:
            with sqlite_engine.begin() as sconn:
                sconn.execute(text("""
                    INSERT OR REPLACE INTO teachers 
                    (username, full_name, email, password_hash, school_name, district, state, primary_grade)
                    VALUES (:username, :full_name, :email, :phash, :school, :district, :state, :grade)
                """), params)
        except Exception as se:
            print(f"[WARN] SQLite dual-save exception: {se}")

    return {
        "id": primary_id or 1,
        "username": params["username"],
        "full_name": params["full_name"],
        "email": params["email"],
        "school_name": params["school"],
        "district": params["district"],
        "state": params["state"],
        "primary_grade": params["grade"],
    }


def get_teacher_by_login(login_id: str) -> dict | None:
    """Finds teacher by username or email across primary (Aiven Cloud MySQL) and local SQLite databases."""
    query = text("SELECT id, username, full_name, email, password_hash, school_name, district, state, primary_grade FROM teachers WHERE username = :lid OR email = :lid LIMIT 1")

    # Check active engine
    try:
        with engine.connect() as conn:
            row = conn.execute(query, {"lid": login_id.strip()}).fetchone()
            if row:
                return dict(row._mapping)
    except Exception as e:
        print(f"[WARN] Primary teacher lookup error: {e}")

    # Check local SQLite fallback
    try:
        with sqlite_engine.connect() as sconn:
            srow = sconn.execute(query, {"lid": login_id.strip()}).fetchone()
            if srow:
                return dict(srow._mapping)
    except Exception as e:
        print(f"[WARN] SQLite fallback teacher lookup error: {e}")

    return None


# Initialize schema automatically
try:
    init_db()
except Exception as err:
    print(f"[DATABASE] Schema init note: {err}")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()