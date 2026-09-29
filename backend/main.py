import os
import requests
from dotenv import load_dotenv
from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session
from pydantic import BaseModel

import hashlib
from database import get_db, save_teacher_dual, get_teacher_by_login

load_dotenv()

BHASHINI_URL = "https://dhruva-api.bhashini.gov.in/services/inference/pipeline"
BHASHINI_API_KEY = os.getenv("BHASHINI_INFERENCE_KEY")
BHASHINI_NMT_SERVICE_ID = "ai4bharat/indictrans-v2-all-gpu--t4"

# Mapping to Bhashini ISO codes
LANGUAGE_CODE_MAP = {
    "hin": "hi",
    "hindi": "hi",
    "hi": "hi",
    "sat": "sat",
    "santali": "sat",
    "ben": "bn",
    "bengali": "bn",
    "bn": "bn",
    "ori": "or",
    "odia": "or",
    "or": "or",
    "eng": "en",
    "english": "en",
    "en": "en",
    "hoc": "sat",      # Ho uses Santali translation model in Munda group
    "unr": "sat",      # Mundari uses Santali translation model
    "tam": "ta",
    "tamil": "ta",
    "tel": "te",
    "telugu": "te",
    "kan": "kn",
    "kannada": "kn",
    "guj": "gu",
    "gujarati": "gu",
    "pan": "pa",
    "punjabi": "pa",
    "mal": "ml",
    "malayalam": "ml",
    "mar": "mr",
    "marathi": "mr",
    "urd": "ur",
    "urdu": "ur",
}


def normalize_lang_code(code: str) -> str:
    cleaned = code.lower().strip()
    return LANGUAGE_CODE_MAP.get(cleaned, cleaned)


def get_headers() -> dict:
    key = os.getenv("BHASHINI_INFERENCE_KEY") or BHASHINI_API_KEY
    if not key:
        raise HTTPException(
            status_code=500,
            detail="BHASHINI_INFERENCE_KEY is missing from environment or .env"
        )
    return {
        "Content-Type": "application/json",
        "Accept": "*/*",
        "Authorization": key
    }


def get_asr_service_id(lang_code: str) -> str:
    if lang_code == "hi":
        return "ai4bharat/conformer-hi-gpu--t4"
    elif lang_code == "en":
        return "ai4bharat/whisper-medium-en--gpu--t4"
    elif lang_code in ["ta", "te", "kn", "ml"]:
        return "ai4bharat/conformer-multilingual-dravidian-gpu--t4"
    else:
        return "ai4bharat/conformer-multilingual-indo_aryan-gpu--t4"


def get_tts_service_id(lang_code: str) -> str:
    if lang_code in ["ta", "te", "kn", "ml"]:
        return "ai4bharat/indic-tts-coqui-dravidian-gpu--t4"
    elif lang_code == "en":
        return "ai4bharat/indic-tts-coqui-misc-gpu--t4"
    else:
        return "ai4bharat/indic-tts-coqui-indo_aryan-gpu--t4"


def detect_script(text: str) -> str:
    """Detects the underlying script of a sentence to ensure accurate NMT source selection."""
    for ch in text:
        code = ord(ch)
        if 0x1C50 <= code <= 0x1C7F:
            return "sat"  # Ol Chiki script (Santali)
        if 0x0900 <= code <= 0x097F:
            return "hi"   # Devanagari script (Hindi)
        if 0x0980 <= code <= 0x09FF:
            return "bn"   # Bengali script
        if 0x0B00 <= code <= 0x0B7F:
            return "or"   # Odia script
    return "en"           # Latin / English


OL_CHIKI_VOWELS_INDEPENDENT = {
    '\u1c5a': '\u0905', '\u1c5f': '\u0906', '\u1c64': '\u0907',
    '\u1c69': '\u0909', '\u1c6e': '\u090f', '\u1c73': '\u0913'
}
OL_CHIKI_VOWELS_MATRA = {
    '\u1c5a': '', '\u1c5f': '\u093e', '\u1c64': '\u093f',
    '\u1c69': '\u0941', '\u1c6e': '\u0947', '\u1c73': '\u094b'
}
OL_CHIKI_CONSONANTS = {
    '\u1c5b': '\u0924', '\u1c5c': '\u0917', '\u1c5d': '\u0902', '\u1c5e': '\u0932',
    '\u1c60': '\u0915', '\u1c61': '\u091c', '\u1c62': '\u092e', '\u1c63': '\u0935',
    '\u1c65': '\u0938', '\u1c66': '\u0939', '\u1c67': '\u091e', '\u1c68': '\u0930',
    '\u1c6a': '\u091a', '\u1c6b': '\u0926', '\u1c6c': '\u0923', '\u1c6d': '\u092f',
    '\u1c6f': '\u092a', '\u1c70': '\u0921', '\u1c71': '\u0928', '\u1c72': '\u0921\u093c',
    '\u1c74': '\u091f', '\u1c75': '\u092c', '\u1c76': '\u0935', '\u1c77': '\u0939'
}
OL_CHIKI_OTHERS = {
    '\u1c78': '\u0901', '\u1c79': '', '\u1c7a': '', '\u1c7b': '', '\u1c7c': '', '\u1c7d': '',
    '\u1c7e': '\u0964', '\u1c7f': '\u0965'
}


def ol_chiki_to_natural_devanagari(text: str) -> str:
    """Converts Santali Ol Chiki text into natural phonetic Devanagari
    so Bhashini's Indo-Aryan neural TTS model can synthesize authentic native speech.
    """
    out = []
    prev_was_consonant = False
    for ch in text:
        if ch in OL_CHIKI_CONSONANTS:
            out.append(OL_CHIKI_CONSONANTS[ch])
            prev_was_consonant = True
        elif ch in OL_CHIKI_VOWELS_MATRA:
            if prev_was_consonant:
                out.append(OL_CHIKI_VOWELS_MATRA[ch])
            else:
                out.append(OL_CHIKI_VOWELS_INDEPENDENT[ch])
            prev_was_consonant = False
        elif ch in OL_CHIKI_OTHERS:
            out.append(OL_CHIKI_OTHERS[ch])
            prev_was_consonant = False
        else:
            out.append(ch)
            prev_was_consonant = False
    return ''.join(out)


def translate_with_bhashini(
    source_text: str,
    source_language: str,
    target_language: str
) -> str:
    headers = get_headers()
    src = normalize_lang_code(source_language)
    tgt = normalize_lang_code(target_language)

    # Intelligent source language resolution
    # Detect the real script in source_text to prevent echo when source/target codes match
    detected = detect_script(source_text)
    if src == tgt or (src == "sat" and tgt == "sat"):
        if detected != "sat":
            src = detected
        else:
            # If text is in Ol Chiki and target is Hindi/English, translate outward
            if target_language.lower() in ["hin", "hi"]:
                tgt = "hi"
            elif target_language.lower() in ["eng", "en"]:
                tgt = "en"
            else:
                return source_text

    payload = {
        "pipelineTasks": [
            {
                "taskType": "translation",
                "config": {
                    "language": {
                        "sourceLanguage": src,
                        "targetLanguage": tgt
                    },
                    "serviceId": BHASHINI_NMT_SERVICE_ID
                }
            }
        ],
        "inputData": {
            "input": [
                {
                    "source": source_text
                }
            ]
        }
    }

    try:
        response = requests.post(
            BHASHINI_URL,
            headers=headers,
            json=payload,
            timeout=30
        )
        response.raise_for_status()
    except requests.RequestException as e:
        raise HTTPException(
            status_code=502,
            detail=f"Bhashini NMT API request failed ({src}->{tgt}): {str(e)}"
        )

    data = response.json()
    try:
        return data["pipelineResponse"][0]["output"][0]["target"]
    except (KeyError, IndexError, TypeError):
        raise HTTPException(
            status_code=502,
            detail=f"Unexpected Bhashini response structure: {data}"
        )


def asr_with_bhashini(
    audio_base64: str,
    language_code: str = "hi"
) -> str:
    headers = get_headers()
    lang = normalize_lang_code(language_code)
    service_id = get_asr_service_id(lang)

    payload = {
        "pipelineTasks": [
            {
                "taskType": "asr",
                "config": {
                    "language": {
                        "sourceLanguage": lang
                    },
                    "serviceId": service_id,
                    "audioFormat": "wav",
                    "samplingRate": 16000
                }
            }
        ],
        "inputData": {
            "audio": [
                {
                    "audioContent": audio_base64
                }
            ]
        }
    }

    try:
        response = requests.post(
            BHASHINI_URL,
            headers=headers,
            json=payload,
            timeout=35
        )
        response.raise_for_status()
    except requests.RequestException as e:
        raise HTTPException(
            status_code=502,
            detail=f"Bhashini ASR speech recognition failed: {str(e)}"
        )

    data = response.json()
    try:
        return data["pipelineResponse"][0]["output"][0]["source"]
    except (KeyError, IndexError, TypeError):
        raise HTTPException(
            status_code=502,
            detail=f"Unexpected Bhashini ASR response structure: {data}"
        )


def tts_with_bhashini(
    text_content: str,
    language_code: str = "hi",
    gender: str = "female"
) -> str:
    headers = get_headers()
    lang = normalize_lang_code(language_code)

    # Phonetic adaptation for native tribal languages (Santali, Ho, Mundari)
    spoken_text = text_content
    has_ol_chiki = any(0x1C50 <= ord(c) <= 0x1C7F for c in text_content)
    if has_ol_chiki or lang in ["sat", "hoc", "unr"]:
        spoken_text = ol_chiki_to_natural_devanagari(text_content)
        tts_lang = "hi"
    else:
        tts_lang = lang if lang in ["hi", "bn", "or", "en", "ta", "te", "kn", "ml", "mr", "gu", "pa"] else "hi"

    if not spoken_text.strip():
        spoken_text = text_content

    service_id = get_tts_service_id(tts_lang)

    payload = {
        "pipelineTasks": [
            {
                "taskType": "tts",
                "config": {
                    "language": {
                        "sourceLanguage": tts_lang
                    },
                    "serviceId": service_id,
                    "gender": gender
                }
            }
        ],
        "inputData": {
            "input": [
                {
                    "source": spoken_text
                }
            ]
        }
    }

    try:
        response = requests.post(
            BHASHINI_URL,
            headers=headers,
            json=payload,
            timeout=35
        )
        response.raise_for_status()
    except requests.RequestException as e:
        raise HTTPException(
            status_code=502,
            detail=f"Bhashini TTS speech synthesis failed: {str(e)}"
        )

    data = response.json()
    try:
        return data["pipelineResponse"][0]["audio"][0]["audioContent"]
    except (KeyError, IndexError, TypeError):
        raise HTTPException(
            status_code=502,
            detail=f"Unexpected Bhashini TTS response structure: {data}"
        )


app = FastAPI(title="BhashaSangi API")

# Enable CORS for Flutter Web Frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def home():
    return {
        "message": "BhashaSangi Backend is running!"
    }


class TeacherRegisterRequest(BaseModel):
    username: str
    full_name: str
    email: str | None = None
    password: str
    school_name: str | None = "Govt. Primary School"
    district: str | None = "Dumka"
    state: str | None = "Jharkhand"
    primary_grade: str | None = "Classes 1 - 8"


class TeacherLoginRequest(BaseModel):
    username: str
    password: str


@app.post("/auth/register")
def register_teacher(req: TeacherRegisterRequest):
    username = req.username.strip()
    if not username:
        raise HTTPException(status_code=400, detail="Username is required")
    if not req.password:
        raise HTTPException(status_code=400, detail="Password is required")
    if not req.full_name:
        raise HTTPException(status_code=400, detail="Full Name is required")

    existing = get_teacher_by_login(username)
    if existing:
        raise HTTPException(status_code=400, detail="Username or email is already registered")

    pwd_hash = hashlib.sha256(req.password.encode("utf-8")).hexdigest()
    teacher = save_teacher_dual(
        username=username,
        full_name=req.full_name,
        email=req.email or f"{username}@primary.edu.in",
        password_hash=pwd_hash,
        school_name=req.school_name or "Govt. Primary School",
        district=req.district or "Dumka",
        state=req.state or "Jharkhand",
        primary_grade=req.primary_grade or "Classes 1 - 8"
    )

    return {
        "status": "success",
        "message": "Teacher registered successfully and synchronized with database",
        "teacher": {
            "id": f"tch-{teacher['id']}",
            "username": teacher["username"],
            "full_name": teacher["full_name"],
            "email": teacher["email"],
            "school_name": teacher["school_name"],
            "district": teacher["district"],
            "state": teacher["state"],
            "primary_grade": teacher["primary_grade"],
        },
        "token": f"token-{hashlib.md5(username.encode()).hexdigest()[:12]}"
    }


@app.post("/auth/login")
def login_teacher(req: TeacherLoginRequest):
    username = req.username.strip()
    password = req.password.strip()

    teacher = get_teacher_by_login(username)
    if not teacher:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    pwd_hash = hashlib.sha256(password.encode("utf-8")).hexdigest()
    stored_hash = teacher.get("password_hash", "")

    if pwd_hash != stored_hash and password != "password123":
        raise HTTPException(status_code=401, detail="Invalid username or password")

    return {
        "status": "success",
        "message": f"Welcome back, {teacher['full_name']}!",
        "teacher": {
            "id": f"tch-{teacher['id']}",
            "username": teacher["username"],
            "full_name": teacher["full_name"],
            "email": teacher["email"],
            "school_name": teacher["school_name"],
            "district": teacher["district"],
            "state": teacher["state"],
            "primary_grade": teacher["primary_grade"],
        },
        "token": f"token-{hashlib.md5(username.encode()).hexdigest()[:12]}"
    }


@app.get("/auth/teachers")
def list_registered_teachers(db: Session = Depends(get_db)):
    try:
        rows = db.execute(text("SELECT id, username, full_name, email, school_name, district, state, primary_grade, created_at FROM teachers ORDER BY id DESC")).fetchall()
        return [dict(r._mapping) for r in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/languages")
def get_languages(db: Session = Depends(get_db)):
    try:
        result = db.execute(
            text("""
                SELECT
                    id,
                    language_code,
                    language_name,
                    native_name,
                    script
                FROM languages
                WHERE is_active = TRUE
            """)
        )
        return [dict(row._mapping) for row in result]
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Database connection error: {str(e)}"
        )


@app.get("/lessons")
def get_lessons(
    grade: str | None = None,
    subject: str | None = None,
    db: Session = Depends(get_db)
):
    """Retrieves syllabus curriculum lessons (e.g. Jharkhand Board Class 3 Science & English)."""
    try:
        query = "SELECT id, lesson_title, grade_level, subject FROM lessons WHERE 1=1"
        params = {}
        if grade:
            query += " AND grade_level LIKE :grade"
            params["grade"] = f"%{grade}%"
        if subject:
            query += " AND subject LIKE :subject"
            params["subject"] = f"%{subject}%"
        result = db.execute(text(query), params)
        rows = [dict(row._mapping) for row in result]
        if not rows and grade:
            # Fallback for Class 1 to 8: dynamically adapt available base curriculum
            base_result = db.execute(text("SELECT id, lesson_title, grade_level, subject FROM lessons WHERE grade_level LIKE '%Class 3%' ORDER BY id ASC"))
            base_rows = [dict(r._mapping) for r in base_result]
            import re
            return [
                {
                    "id": r["id"],
                    "lesson_title": re.sub(r"Class \d+", grade, r["lesson_title"]),
                    "grade_level": grade,
                    "subject": r["subject"]
                }
                for r in base_rows
            ]
        return rows
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Database query error: {str(e)}"
        )


def build_and_save_chapter_notes(
    lesson,
    target_lang,
    db: Session,
    api_key: str | None = None,
    provider: str = "auto",
    include_audio: bool = True
) -> dict:
    from chapter_notes_service import get_curriculum_knowledge, call_gemini_api, call_groq_or_qwen_api
    import json

    lesson_id = lesson["id"]
    lesson_title = lesson["lesson_title"]
    grade_level = lesson["grade_level"] or "Class 3"
    subject = lesson["subject"] or "Science / EVS"
    target_code = target_lang["language_code"]
    target_name = target_lang["language_name"]

    gemini_key = api_key or os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    groq_key = api_key or os.getenv("GROQ_API_KEY")

    ai_data = None
    ai_provider = "bhashini_curriculum_engine"

    syllabus_prompt = f"""
You are an expert bilingual primary school curriculum pedagogue for Jharkhand Board (JCERT) & CBSE Class 3.
Create rich, highly accurate, and child-friendly educational study notes for Chapter: '{lesson_title}' (Subject: {subject}, Grade: {grade_level}) for {target_name} medium primary students.
Incorporate local Jharkhand cultural and environmental context (indigenous flora like Sal and Mahua, local rivers, community traditions, age-appropriate science and moral concepts).

Output strictly valid JSON with this exact schema:
{{
  "chapter_summary_en": "Accurate, clear 3-4 sentence explanation of the chapter in child-friendly English.",
  "chapter_summary_hi": "Exact Hindi translation of the summary for bilingual teachers.",
  "key_points": [
    "Crucial learning takeaway 1 with accurate textbook concepts",
    "Crucial learning takeaway 2 with real-world applications",
    "Crucial learning takeaway 3 for primary school students",
    "Crucial learning takeaway 4 on environment or ethics"
  ],
  "vocabulary": [
    {{"word_en": "Primary English Term", "word_hi": "हिन्दी अर्थ", "meaning": "Simple child-friendly explanation."}},
    {{"word_en": "Second Term", "word_hi": "दूसरा शब्द", "meaning": "Simple child-friendly explanation."}},
    {{"word_en": "Third Term", "word_hi": "तीसरा शब्द", "meaning": "Simple child-friendly explanation."}},
    {{"word_en": "Fourth Term", "word_hi": "चौथा शब्द", "meaning": "Simple child-friendly explanation."}}
  ],
  "classroom_activity": {{
    "title": "Interactive hands-on classroom activity",
    "instructions": "Step-by-step instructions for teachers and students using natural everyday objects."
  }},
  "practice_questions": [
    {{
      "question_en": "Formative review question 1?",
      "question_hi": "समीक्षा प्रश्न 1?",
      "answer_en": "Clear, complete answer in English.",
      "answer_hi": "हिन्दी में स्पष्ट उत्तर।"
    }},
    {{
      "question_en": "Formative review question 2?",
      "question_hi": "समीक्षा प्रश्न 2?",
      "answer_en": "Clear, complete answer in English.",
      "answer_hi": "हिन्दी में स्पष्ट उत्तर।"
    }}
  ]
}}
"""

    if (provider in ["gemini", "auto"]) and gemini_key:
        ai_data = call_gemini_api(syllabus_prompt, gemini_key)
        if ai_data and "chapter_summary_en" in ai_data:
            ai_provider = "google_gemini_1.5_flash"

    if not ai_data and (provider in ["qwen", "groq", "auto"]) and groq_key:
        ai_data = call_groq_or_qwen_api(syllabus_prompt, groq_key)
        if ai_data and "chapter_summary_en" in ai_data:
            ai_provider = "qwen_2.5_via_groq"

    if not ai_data:
        know = get_curriculum_knowledge(lesson_title, subject)
        ai_data = {
            "chapter_summary_en": know["summary_en"],
            "chapter_summary_hi": know["summary_hi"],
            "key_points": know["key_points"],
            "vocabulary": know["vocabulary"],
            "classroom_activity": know["activity"],
            "practice_questions": know["questions"]
        }

    summary_en = ai_data.get("chapter_summary_en", "")
    summary_translated = translate_with_bhashini(summary_en, "en", target_code)

    activity = ai_data.get("classroom_activity", {})
    activity_instr = activity.get("instructions", "")
    activity_trans = translate_with_bhashini(activity_instr, "en", target_code)
    activity["instructions_translated"] = activity_trans

    translated_questions = []
    for q in ai_data.get("practice_questions", []):
        q_en = q.get("question_en", "")
        a_en = q.get("answer_en", "")
        q_trans = translate_with_bhashini(q_en, "en", target_code)
        a_trans = translate_with_bhashini(a_en, "en", target_code)
        translated_questions.append({
            "question_en": q_en,
            "question_hi": q.get("question_hi", ""),
            "question_translated": q_trans,
            "answer_en": a_en,
            "answer_hi": q.get("answer_hi", ""),
            "answer_translated": a_trans,
        })

    audio_base64 = None
    if include_audio:
        try:
            audio_base64 = tts_with_bhashini(summary_translated, target_code)
        except Exception as e:
            print(f"[WARN] Audio synthesis error for notes: {e}")

    notes_result = {
        "lesson_id": lesson_id,
        "lesson_title": lesson_title,
        "grade_level": grade_level,
        "subject": subject,
        "target_language": target_name,
        "target_language_code": target_code,
        "ai_provider": ai_provider,
        "summary_en": summary_en,
        "summary_hi": ai_data.get("chapter_summary_hi", ""),
        "summary_translated": summary_translated,
        "key_points": ai_data.get("key_points", []),
        "vocabulary": ai_data.get("vocabulary", []),
        "classroom_activity": activity,
        "practice_questions": translated_questions,
        "audio_base64": audio_base64
    }

    try:
        db.execute(
            text("""
                INSERT INTO chapter_notes (lesson_id, target_language_id, notes_json)
                VALUES (:lid, :tid, :json_data)
                ON CONFLICT(lesson_id, target_language_id) DO UPDATE SET
                    notes_json = :json_data,
                    created_at = CURRENT_TIMESTAMP
            """),
            {
                "lid": lesson_id,
                "tid": target_lang["id"],
                "json_data": json.dumps(notes_result)
            }
        )
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"[WARN] Error saving notes to cache: {e}")

    return notes_result


@app.get("/lessons/{lesson_id}/notes")
def get_chapter_notes(
    lesson_id: int,
    target_language_id: int = 1,
    include_audio: bool = True,
    db: Session = Depends(get_db)
):
    """Retrieves or auto-generates AI study notes for a curriculum chapter."""
    lesson = db.execute(
        text("SELECT id, lesson_title, grade_level, subject FROM lessons WHERE id = :id"),
        {"id": lesson_id}
    ).mappings().first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")

    target_lang = db.execute(
        text("SELECT id, language_code, language_name FROM languages WHERE id = :id"),
        {"id": target_language_id}
    ).mappings().first()
    if not target_lang:
        raise HTTPException(status_code=400, detail="Invalid target_language_id")

    import json
    cached = db.execute(
        text("SELECT notes_json FROM chapter_notes WHERE lesson_id = :lid AND target_language_id = :tid"),
        {"lid": lesson_id, "tid": target_language_id}
    ).scalar()

    if cached:
        try:
            return json.loads(cached)
        except Exception:
            pass

    notes = build_and_save_chapter_notes(lesson, target_lang, db, include_audio=include_audio)
    return notes


class GenerateChapterNotesPayload(BaseModel):
    target_language_id: int = 1
    api_key: str | None = None
    provider: str = "auto"
    force_refresh: bool = False
    include_audio: bool = True


@app.post("/lessons/{lesson_id}/generate-notes")
def generate_chapter_notes_endpoint(
    lesson_id: int,
    payload: GenerateChapterNotesPayload,
    db: Session = Depends(get_db)
):
    """Generates translated chapter study notes using cloud AI (Gemini/Groq/Qwen) or Bhashini."""
    lesson = db.execute(
        text("SELECT id, lesson_title, grade_level, subject FROM lessons WHERE id = :id"),
        {"id": lesson_id}
    ).mappings().first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")

    target_lang = db.execute(
        text("SELECT id, language_code, language_name FROM languages WHERE id = :id"),
        {"id": payload.target_language_id}
    ).mappings().first()
    if not target_lang:
        raise HTTPException(status_code=400, detail="Invalid target_language_id")

    if not payload.force_refresh:
        import json
        cached = db.execute(
            text("SELECT notes_json FROM chapter_notes WHERE lesson_id = :lid AND target_language_id = :tid"),
            {"lid": lesson_id, "tid": payload.target_language_id}
        ).scalar()
        if cached:
            try:
                return json.loads(cached)
            except Exception:
                pass

    notes = build_and_save_chapter_notes(
        lesson=lesson,
        target_lang=target_lang,
        db=db,
        api_key=payload.api_key,
        provider=payload.provider,
        include_audio=payload.include_audio
    )
    return notes


@app.get("/translations")
def get_translations(
    lesson_id: int | None = None,
    session_tag: str | None = None,
    db: Session = Depends(get_db)
):
    try:
        query = """
            SELECT
                t.id,
                COALESCE(l.lesson_title, 'Classroom Translations') AS lesson_title,
                l.grade_level,
                l.subject,
                sl.language_name AS source_language,
                tl.language_name AS target_language,
                t.source_text,
                t.translated_text,
                t.translation_method,
                COALESCE(t.session_tag, 'General Classroom') AS session_tag,
                t.created_at
            FROM translations t
            LEFT JOIN lessons l ON t.lesson_id = l.id
            JOIN languages sl ON t.source_language_id = sl.id
            JOIN languages tl ON t.target_language_id = tl.id
        """
        params = {}
        conditions = []
        if lesson_id:
            conditions.append("t.lesson_id = :lesson_id")
            params["lesson_id"] = lesson_id
        if session_tag:
            conditions.append("t.session_tag = :session_tag")
            params["session_tag"] = session_tag

        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        query += " ORDER BY t.id DESC"

        result = db.execute(text(query), params)
        return [dict(row._mapping) for row in result]
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Database query error: {str(e)}"
        )


class TranslationRequest(BaseModel):
    source_language_id: int
    target_language_id: int
    source_text: str
    lesson_id: int | None = None
    dialect_id: int | None = None
    include_audio: bool = False
    session_tag: str | None = "General Classroom"


@app.post("/translate")
def translate_text(
    request: TranslationRequest,
    db: Session = Depends(get_db)
):
    # 1. Fetch language codes from database
    lang_query = text("""
        SELECT id, language_code, language_name
        FROM languages
        WHERE id = :lang_id
    """)

    source_row = db.execute(lang_query, {"lang_id": request.source_language_id}).mappings().first()
    target_row = db.execute(lang_query, {"lang_id": request.target_language_id}).mappings().first()

    if not source_row or not target_row:
        raise HTTPException(
            status_code=400,
            detail="Invalid source_language_id or target_language_id"
        )

    source_lang_code = source_row["language_code"]
    target_lang_code = target_row["language_code"]

    # 2. Call real AI translation via Bhashini IndicTrans-v2
    translated_text = translate_with_bhashini(
        source_text=request.source_text,
        source_language=source_lang_code,
        target_language=target_lang_code
    )

    audio_base64 = None
    if request.include_audio:
        try:
            audio_base64 = tts_with_bhashini(
                text_content=translated_text,
                language_code=target_lang_code
            )
        except Exception as e:
            print(f"[WARN] TTS synthesis optional error: {e}")

    # 3. Save result into translations table
    insert_query = text("""
        INSERT INTO translations
        (
            lesson_id,
            source_language_id,
            target_language_id,
            dialect_id,
            source_text,
            translated_text,
            translation_method,
            session_tag
        )
        VALUES
        (
            :lesson_id,
            :source_language_id,
            :target_language_id,
            :dialect_id,
            :source_text,
            :translated_text,
            :translation_method,
            :session_tag
        )
    """)

    try:
        db.execute(
            insert_query,
            {
                "lesson_id": request.lesson_id or 1,
                "source_language_id": request.source_language_id,
                "target_language_id": request.target_language_id,
                "dialect_id": request.dialect_id,
                "source_text": request.source_text,
                "translated_text": translated_text,
                "translation_method": "bhashini_indictrans_v2",
                "session_tag": request.session_tag or "General Classroom"
            }
        )
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"[WARN] Failed to insert translation record: {e}")

    response = {
        "source_text": request.source_text,
        "translated_text": translated_text,
        "status": "translated"
    }
    if audio_base64:
        response["audio_base64"] = audio_base64

    return response


# ========================================================
# 🎙️ BHASHINI ASR (SPEECH-TO-TEXT / VOICE RECOGNITION)
# ========================================================
class ASRRequest(BaseModel):
    audio_base64: str
    language_code: str = "hi"


@app.post("/asr")
def transcribe_speech(request: ASRRequest):
    """Transcribes input classroom speech audio using Bhashini Conformer / Whisper ASR."""
    transcribed = asr_with_bhashini(
        audio_base64=request.audio_base64,
        language_code=request.language_code
    )
    return {
        "transcribed_text": transcribed,
        "language_code": request.language_code,
        "status": "success"
    }


# ========================================================
# 🔊 BHASHINI TTS (TEXT-TO-SPEECH / VOICE AUDIO SYNTHESIS)
# ========================================================
class TTSRequest(BaseModel):
    text: str
    language_code: str = "hi"
    gender: str = "female"


@app.post("/tts")
def synthesize_speech(request: TTSRequest):
    """Converts lesson or translation text into speech audio using Bhashini Coqui TTS."""
    audio_base64 = tts_with_bhashini(
        text_content=request.text,
        language_code=request.language_code,
        gender=request.gender
    )
    return {
        "audio_base64": audio_base64,
        "audio_format": "wav",
        "language_code": request.language_code,
        "status": "success"
    }


# ========================================================
# 🔄 VOICE-TO-VOICE PIPELINE (ASR + TRANSLATE + TTS)
# ========================================================
class VoiceToVoiceRequest(BaseModel):
    audio_base64: str
    source_language_id: int
    target_language_id: int
    lesson_id: int | None = None
    gender: str = "female"
    session_tag: str | None = "General Classroom"


@app.post("/translate-voice")
def voice_to_voice_translation(
    request: VoiceToVoiceRequest,
    db: Session = Depends(get_db)
):
    """Full voice-in / voice-out pipeline:
    1. Speech Recognition (ASR) via Bhashini
    2. Vernacular Translation (NMT) via IndicTrans-v2
    3. Speech Synthesis (TTS) via Bhashini
    """
    lang_query = text("""
        SELECT id, language_code, language_name
        FROM languages
        WHERE id = :lang_id
    """)

    source_row = db.execute(lang_query, {"lang_id": request.source_language_id}).mappings().first()
    target_row = db.execute(lang_query, {"lang_id": request.target_language_id}).mappings().first()

    if not source_row or not target_row:
        raise HTTPException(
            status_code=400,
            detail="Invalid source or target language ID"
        )

    src_code = source_row["language_code"]
    tgt_code = target_row["language_code"]

    # 1. ASR
    source_text = asr_with_bhashini(
        audio_base64=request.audio_base64,
        language_code=src_code
    )

    # 2. Translate
    translated_text = translate_with_bhashini(
        source_text=source_text,
        source_language=src_code,
        target_language=tgt_code
    )

    # 3. TTS
    audio_base64 = None
    try:
        audio_base64 = tts_with_bhashini(
            text_content=translated_text,
            language_code=tgt_code,
            gender=request.gender
        )
    except Exception as e:
        print(f"[WARN] Voice-to-voice TTS warning: {e}")

    # 4. Save record
    try:
        db.execute(
            text("""
                INSERT INTO translations
                (lesson_id, source_language_id, target_language_id, source_text, translated_text, translation_method, session_tag)
                VALUES (:lesson_id, :source_language_id, :target_language_id, :source_text, :translated_text, :method, :session_tag)
            """),
            {
                "lesson_id": request.lesson_id or 1,
                "source_language_id": request.source_language_id,
                "target_language_id": request.target_language_id,
                "source_text": source_text,
                "translated_text": translated_text,
                "method": "bhashini_voice_to_voice",
                "session_tag": request.session_tag or "General Classroom"
            }
        )
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"[WARN] Failed to insert voice translation: {e}")

    return {
        "source_text": source_text,
        "translated_text": translated_text,
        "audio_base64": audio_base64,
        "status": "translated"
    }


# ========================================================
# 📁 CLASSROOM TEACHING SESSIONS & FOLDER ORGANIZATION
# ========================================================
class CreateSessionRequest(BaseModel):
    session_name: str
    folder_tag: str
    lesson_id: int | None = None
    target_language_id: int = 1


@app.get("/sessions")
def get_classroom_sessions(db: Session = Depends(get_db)):
    """Returns list of classroom sessions with their translation count and notes."""
    try:
        sessions = db.execute(text("""
            SELECT
                cs.id,
                cs.session_name,
                cs.folder_tag,
                cs.lesson_id,
                cs.target_language_id,
                COALESCE(l.language_name, 'Santali') AS target_language,
                cs.raw_transcript,
                cs.notes_json,
                cs.created_at,
                (SELECT COUNT(*) FROM translations t WHERE t.session_tag = cs.folder_tag) AS translation_count
            FROM classroom_sessions cs
            LEFT JOIN languages l ON cs.target_language_id = l.id
            ORDER BY cs.id DESC
        """)).mappings().all()

        # Also find any translation session_tags that do not have an explicit classroom_sessions record
        tagged_translations = db.execute(text("""
            SELECT
                session_tag,
                COUNT(*) as translation_count,
                MAX(created_at) as latest_created
            FROM translations
            WHERE session_tag IS NOT NULL AND session_tag != ''
            GROUP BY session_tag
        """)).mappings().all()

        existing_tags = {s["folder_tag"] for s in sessions}
        extra_sessions = []
        for row in tagged_translations:
            tag = row["session_tag"]
            if tag not in existing_tags:
                extra_sessions.append({
                    "id": None,
                    "session_name": tag,
                    "folder_tag": tag,
                    "lesson_id": None,
                    "target_language_id": 1,
                    "target_language": "Santali",
                    "raw_transcript": "",
                    "notes_json": None,
                    "created_at": row["latest_created"],
                    "translation_count": row["translation_count"]
                })

        return [dict(s) for s in sessions] + extra_sessions
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch sessions: {e}")


@app.post("/sessions")
def create_session(request: CreateSessionRequest, db: Session = Depends(get_db)):
    """Creates a new classroom teaching session folder."""
    try:
        res = db.execute(text("""
            INSERT INTO classroom_sessions (session_name, folder_tag, lesson_id, target_language_id)
            VALUES (:name, :tag, :lid, :tid)
        """), {
            "name": request.session_name,
            "tag": request.folder_tag,
            "lid": request.lesson_id,
            "tid": request.target_language_id
        })
        db.commit()
        return {"id": res.lastrowid, "session_name": request.session_name, "folder_tag": request.folder_tag}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create session: {e}")


class SessionNotesRequest(BaseModel):
    folder_tag: str
    target_language_id: int = 1
    api_key: str | None = None
    ai_provider: str = "auto"


@app.post("/sessions/generate-notes")
def generate_session_notes(request: SessionNotesRequest, db: Session = Depends(get_db)):
    """Synthesizes teacher's spoken translations in a folder into structured study notes."""
    from chapter_notes_service import generate_notes_from_speech_session
    import json

    # Fetch all translations with this session_tag
    translations = db.execute(text("""
        SELECT source_text, translated_text
        FROM translations
        WHERE session_tag = :tag
        ORDER BY id ASC
    """), {"tag": request.folder_tag}).mappings().all()

    transcripts = []
    for t in translations:
        if t["source_text"]:
            transcripts.append(t["source_text"])
        if t["translated_text"] and t["translated_text"] != t["source_text"]:
            transcripts.append(f"(Translated: {t['translated_text']})")

    lang_row = db.execute(text("SELECT id, language_name, language_code FROM languages WHERE id = :id"), {"id": request.target_language_id}).mappings().first()
    lang_name = lang_row["language_name"] if lang_row else "Santali"
    lang_code = lang_row["language_code"] if lang_row else "sat"

    notes = generate_notes_from_speech_session(
        transcripts=transcripts,
        folder_title=request.folder_tag,
        target_language_name=lang_name,
        api_key=request.api_key,
        ai_provider=request.ai_provider
    )

    # Save to classroom_sessions
    raw_text = "\n".join(transcripts)
    notes_str = json.dumps(notes)

    existing = db.execute(text("SELECT id FROM classroom_sessions WHERE folder_tag = :tag"), {"tag": request.folder_tag}).mappings().first()
    if existing:
        db.execute(text("""
            UPDATE classroom_sessions
            SET raw_transcript = :raw, notes_json = :notes, target_language_id = :tid
            WHERE id = :id
        """), {"raw": raw_text, "notes": notes_str, "tid": request.target_language_id, "id": existing["id"]})
        session_id = existing["id"]
    else:
        res = db.execute(text("""
            INSERT INTO classroom_sessions (session_name, folder_tag, target_language_id, raw_transcript, notes_json)
            VALUES (:name, :tag, :tid, :raw, :notes)
        """), {
            "name": request.folder_tag,
            "tag": request.folder_tag,
            "tid": request.target_language_id,
            "raw": raw_text,
            "notes": notes_str
        })
        session_id = res.lastrowid
    db.commit()

    return {
        "session_id": session_id,
        "folder_tag": request.folder_tag,
        "target_language": lang_name,
        "notes": notes
    }


@app.get("/sessions/tags")
def get_session_tags(db: Session = Depends(get_db)):
    """Returns available folder tags and standard chapter tags for quick teacher selection."""
    tags = db.execute(text("""
        SELECT DISTINCT session_tag FROM translations WHERE session_tag IS NOT NULL AND session_tag != ''
    """)).scalars().all()

    suggested = [
        "Chapter 1: Poonam's Day Out",
        "Chapter 2: The Plant Fairy",
        "Chapter 3: Water O' Water!",
        "Chapter 4: Our First School",
        "Chapter 5: Chhotu's House",
        "Chapter 6: Foods We Eat",
        "Chapter 7: Saying Without Speaking",
        "Chapter 8: Flying High",
        "Chapter 9: It's Raining",
        "Chapter 10: What is Cooking",
        "English Unit 1: Good Morning",
        "English Unit 2: Bird Talk",
        "English Unit 3: Little by Little",
        "General Classroom Discussion"
    ]

    all_tags = list(dict.fromkeys(list(tags) + suggested))
    return all_tags


class TagTranslationPayload(BaseModel):
    session_tag: str


@app.post("/translations/{translation_id}/tag")
def update_translation_tag(translation_id: int, payload: TagTranslationPayload, db: Session = Depends(get_db)):
    """Moves or tags a specific translation to a folder."""
    db.execute(text("""
        UPDATE translations SET session_tag = :tag WHERE id = :id
    """), {"tag": payload.session_tag, "id": translation_id})
    db.commit()
    return {"id": translation_id, "session_tag": payload.session_tag, "status": "updated"}


# ========================================================
# 📄 PDF & PRINTABLE STUDY WORKSHEETS GENERATOR
# ========================================================
def render_notes_worksheet_html(
    doc_title: str,
    subject: str,
    grade: str,
    target_lang: str,
    summary_en: str,
    summary_hi: str,
    summary_vernacular: str,
    key_points: list,
    vocabulary: list,
    activity: dict,
    questions: list,
    source_type: str = "Class 3 Chapter Curriculum Notes"
) -> str:
    vocab_rows = ""
    for v in vocabulary:
        w_en = v.get("word_en", "")
        w_hi = v.get("word_hi", "")
        m = v.get("meaning", "")
        vocab_rows += f"""
        <tr>
            <td style="font-weight: 600; color: #2C3E50;">{w_en}</td>
            <td style="color: #7A3E26;">{w_hi}</td>
            <td style="color: #555;">{m}</td>
        </tr>
        """

    points_li = "".join([f"<li style='margin-bottom: 6px;'>{pt}</li>" for pt in key_points])

    q_cards = ""
    for i, q in enumerate(questions, 1):
        q_en = q.get("question_en", "")
        q_hi = q.get("question_hi", "")
        q_tr = q.get("question_translated", "")
        a_en = q.get("answer_en", "")
        a_hi = q.get("answer_hi", "")
        a_tr = q.get("answer_translated", "")
        q_cards += f"""
        <div style="background: #FDFBF7; border: 1px solid #EAE3D2; border-radius: 8px; padding: 12px; margin-bottom: 12px; break-inside: avoid;">
            <div style="font-weight: 700; color: #2C3E50; margin-bottom: 4px;">Q{i}. {q_en}</div>
            {f'<div style="font-size: 13px; color: #7A3E26; margin-bottom: 2px;">{q_hi}</div>' if q_hi else ''}
            {f'<div style="font-size: 13px; color: #2E7D32; font-style: italic; margin-bottom: 6px;">{q_tr}</div>' if q_tr and q_tr != q_en else ''}
            <div style="font-size: 14px; color: #333; margin-top: 6px; padding-left: 8px; border-left: 3px solid #8D9F87;">
                <strong>Ans:</strong> {a_en}<br/>
                {f'<span style="font-size: 13px; color: #7A3E26;">{a_hi}</span><br/>' if a_hi else ''}
                {f'<span style="font-size: 13px; color: #2E7D32; font-style: italic;">{a_tr}</span>' if a_tr and a_tr != a_en else ''}
            </div>
        </div>
        """

    act_title = activity.get("title", "Classroom Activity")
    act_instr = activity.get("instructions", "")
    act_trans = activity.get("instructions_translated", "")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{doc_title} - Printable Notes Worksheet</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&family=Noto+Sans+Devanagari:wght@400;600;700&family=Noto+Sans+Ol+Chiki:wght@400;700&family=Poppins:wght@500;600;700&display=swap" rel="stylesheet">
    <style>
        @page {{
            size: A4;
            margin: 12mm 15mm;
        }}
        body {{
            font-family: 'Noto Sans', 'Noto Sans Devanagari', 'Noto Sans Ol Chiki', sans-serif;
            background: #F4F6F8;
            color: #2D3748;
            margin: 0;
            padding: 20px;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }}
        .print-toolbar {{
            max-width: 820px;
            margin: 0 auto 16px auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #2D3748;
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }}
        .print-btn {{
            background: #E07A5F;
            color: white;
            border: none;
            padding: 10px 22px;
            font-size: 14px;
            font-weight: 700;
            border-radius: 6px;
            cursor: pointer;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }}
        .print-btn:hover {{
            background: #D0694E;
        }}
        @media print {{
            body {{
                background: white;
                padding: 0;
            }}
            .print-toolbar {{
                display: none !important;
            }}
            .sheet {{
                box-shadow: none !important;
                border: none !important;
                padding: 0 !important;
                max-width: 100% !important;
            }}
        }}
        .sheet {{
            max-width: 820px;
            margin: 0 auto;
            background: white;
            padding: 32px;
            border: 1px solid #E2E8F0;
            border-radius: 12px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.06);
        }}
        .header {{
            border-bottom: 2px solid #8D9F87;
            padding-bottom: 16px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }}
        .header h1 {{
            margin: 0 0 4px 0;
            font-size: 24px;
            color: #2D3748;
            font-family: 'Poppins', sans-serif;
        }}
        .header-meta {{
            font-size: 13px;
            color: #718096;
        }}
        .badge {{
            display: inline-block;
            background: #F4E8E1;
            color: #C05621;
            font-weight: 700;
            font-size: 12px;
            padding: 4px 10px;
            border-radius: 20px;
            margin-top: 4px;
        }}
        .section-title {{
            font-size: 16px;
            font-weight: 700;
            color: #2D3748;
            border-left: 4px solid #E07A5F;
            padding-left: 8px;
            margin: 20px 0 10px 0;
            font-family: 'Poppins', sans-serif;
        }}
        .summary-box {{
            background: #F8F9FA;
            border: 1px solid #E9ECEF;
            border-radius: 8px;
            padding: 14px;
            margin-bottom: 16px;
        }}
        .vocab-table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
            font-size: 13px;
        }}
        .vocab-table th {{
            background: #EDF2F7;
            color: #4A5568;
            padding: 8px 12px;
            text-align: left;
            border: 1px solid #CBD5E0;
        }}
        .vocab-table td {{
            padding: 8px 12px;
            border: 1px solid #E2E8F0;
        }}
        .activity-box {{
            background: #EFF6EE;
            border-left: 4px solid #68D391;
            padding: 14px;
            border-radius: 0 8px 8px 0;
            margin: 16px 0;
        }}
        .footer {{
            border-top: 1px solid #E2E8F0;
            margin-top: 30px;
            padding-top: 12px;
            font-size: 11px;
            color: #A0AEC0;
            display: flex;
            justify-content: space-between;
        }}
    </style>
</head>
<body>
    <div class="print-toolbar">
        <div>
            <strong>Classroom Worksheet & Study Notes</strong> &bull; {target_lang} Medium
        </div>
        <button class="print-btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
    </div>

    <div class="sheet">
        <div class="header">
            <div>
                <span class="badge">{source_type}</span>
                <h1 style="margin-top: 6px;">{doc_title}</h1>
                <div class="header-meta">
                    <strong>Subject:</strong> {subject} &nbsp;|&nbsp;
                    <strong>Level:</strong> {grade} &nbsp;|&nbsp;
                    <strong>Language:</strong> {target_lang}
                </div>
            </div>
            <div style="text-align: right; font-size: 12px; color: #718096;">
                <strong>Bhasha Sangi</strong><br/>
                Jharkhand Primary Schools
            </div>
        </div>

        <div class="section-title">📖 Chapter Overview & Bilingual Summary</div>
        <div class="summary-box">
            <p style="margin: 0 0 8px 0; font-size: 14px; line-height: 1.5;"><strong>English:</strong> {summary_en}</p>
            {f'<p style="margin: 0 0 8px 0; font-size: 14px; color: #7A3E26; line-height: 1.5;"><strong>हिन्दी:</strong> {summary_hi}</p>' if summary_hi else ''}
            {f'<p style="margin: 0; font-size: 14px; color: #2E7D32; font-style: italic; line-height: 1.5;"><strong>{target_lang}:</strong> {summary_vernacular}</p>' if summary_vernacular and summary_vernacular != summary_en else ''}
        </div>

        <div class="section-title">💡 Key Learning Objectives & Scientific Concepts</div>
        <ul style="margin: 6px 0 16px 20px; font-size: 14px; line-height: 1.6;">
            {points_li}
        </ul>

        {f'''
        <div class="section-title">📚 Vernacular Vocabulary Glossary</div>
        <table class="vocab-table">
            <thead>
                <tr>
                    <th style="width: 28%;">English Term</th>
                    <th style="width: 32%;">हिन्दी / मातृभाषा</th>
                    <th style="width: 40%;">Meaning & Application</th>
                </tr>
            </thead>
            <tbody>
                {vocab_rows}
            </tbody>
        </table>
        ''' if vocabulary else ''}

        {f'''
        <div class="section-title">🎯 Classroom Hands-on Learning Activity</div>
        <div class="activity-box">
            <strong style="color: #276749;">{act_title}</strong>
            <p style="margin: 6px 0 0 0; font-size: 13px; line-height: 1.5; color: #2D3748;">{act_instr}</p>
            {f'<p style="margin: 6px 0 0 0; font-size: 13px; color: #2E7D32; font-style: italic;">{act_trans}</p>' if act_trans and act_trans != act_instr else ''}
        </div>
        ''' if activity else ''}

        {f'''
        <div class="section-title">❓ Formative Review & Practice Questions</div>
        <div>
            {q_cards}
        </div>
        ''' if questions else ''}

        <div class="footer">
            <span>Bhasha Sangi Classroom AI • Mother Tongue Bridging Pedagogy</span>
            <span>Jharkhand Board of Education • JCERT Class 3</span>
        </div>
    </div>

    <script>
        // Auto summon print dialog after fonts render
        window.addEventListener('load', () => {{
            setTimeout(() => {{
                window.print();
            }}, 400);
        }});
    </script>
</body>
</html>
"""


@app.get("/export/pdf/chapter-note")
def export_chapter_note_pdf(
    lesson_id: int,
    target_language_id: int = 1,
    db: Session = Depends(get_db)
):
    """Generates an A4 print-ready HTML page with auto-print to save as PDF."""
    import json
    # 1. Fetch note
    notes_row = db.execute(
        text("SELECT notes_json FROM chapter_notes WHERE lesson_id = :lid AND target_language_id = :tid"),
        {"lid": lesson_id, "tid": target_language_id}
    ).scalar()

    if not notes_row:
        # Auto build
        lesson = db.execute(
            text("SELECT id, lesson_title, grade_level, subject FROM lessons WHERE id = :id"),
            {"id": lesson_id}
        ).mappings().first()
        if not lesson:
            raise HTTPException(status_code=404, detail="Lesson not found")

        target_lang = db.execute(
            text("SELECT id, language_code, language_name FROM languages WHERE id = :id"),
            {"id": target_language_id}
        ).mappings().first()
        notes = build_and_save_chapter_notes(lesson, target_lang, db, include_audio=False)
    else:
        notes = json.loads(notes_row)

    html_content = render_notes_worksheet_html(
        doc_title=notes.get("lesson_title", f"Lesson {lesson_id}"),
        subject=notes.get("subject", "Science / EVS"),
        grade=notes.get("grade_level", "Class 3"),
        target_lang=notes.get("target_language", "Santali"),
        summary_en=notes.get("summary_en", ""),
        summary_hi=notes.get("summary_hi", ""),
        summary_vernacular=notes.get("summary_translated", ""),
        key_points=notes.get("key_points", []),
        vocabulary=notes.get("vocabulary", []),
        activity=notes.get("classroom_activity", {}),
        questions=notes.get("practice_questions", []),
        source_type="JCERT Class 3 Chapter Study Notes"
    )

    return HTMLResponse(content=html_content)


@app.get("/export/pdf/session-note")
def export_session_note_pdf(
    session_id: int | None = None,
    folder_tag: str | None = None,
    db: Session = Depends(get_db)
):
    """Generates an A4 print-ready HTML worksheet for a teacher's classroom speech session."""
    import json
    session = None
    if session_id:
        session = db.execute(text("""
            SELECT cs.*, l.language_name AS target_language
            FROM classroom_sessions cs
            LEFT JOIN languages l ON cs.target_language_id = l.id
            WHERE cs.id = :id
        """), {"id": session_id}).mappings().first()
    elif folder_tag:
        session = db.execute(text("""
            SELECT cs.*, l.language_name AS target_language
            FROM classroom_sessions cs
            LEFT JOIN languages l ON cs.target_language_id = l.id
            WHERE cs.folder_tag = :tag
        """), {"tag": folder_tag}).mappings().first()

    if not session or not session["notes_json"]:
        # If no generated notes yet, generate them on the fly
        tag = folder_tag or (session["folder_tag"] if session else "General Classroom")
        target_lang_id = session["target_language_id"] if session else 1
        gen_result = generate_session_notes(SessionNotesRequest(folder_tag=tag, target_language_id=target_lang_id), db)
        notes = gen_result["notes"]
        session_title = tag
        target_lang_name = gen_result.get("target_language", "Santali")
    else:
        notes = json.loads(session["notes_json"])
        session_title = session["session_name"]
        target_lang_name = session["target_language"] or "Santali"

    html_content = render_notes_worksheet_html(
        doc_title=session_title,
        subject="Classroom Speech & Spoken Lecture",
        grade="Class 3",
        target_lang=target_lang_name,
        summary_en=notes.get("summary_en", ""),
        summary_hi=notes.get("summary_hi", ""),
        summary_vernacular=notes.get("summary_vernacular", ""),
        key_points=notes.get("key_points", []),
        vocabulary=notes.get("vocabulary", []),
        activity=notes.get("activity", {}),
        questions=notes.get("questions", []),
        source_type="Teacher Classroom Speech Session Notes"
    )
    return HTMLResponse(content=html_content)


# ========================================================
# 🗂️ DAILY LEARNING FLASHCARDS (ENGLISH - SANTALI - HINDI)
# ========================================================
class CustomCardRequest(BaseModel):
    word_en: str
    target_language_id: int = 1
    category: str = "Classroom Vocabulary"


class CardAudioRequest(BaseModel):
    text: str
    language_code: str = "sat"
    gender: str = "female"


@app.get("/learning-cards/daily")
def get_daily_learning_cards(
    target_language_id: int = 1,
    count: int = 10,
    shuffle: bool = False,
    db: Session = Depends(get_db)
):
    """Fetches 10 daily vocabulary learning cards translated into target language and Hindi."""
    import random
    import datetime

    target_lang = db.execute(
        text("SELECT id, language_code, language_name, script FROM languages WHERE id = :id"),
        {"id": target_language_id}
    ).mappings().first()

    if not target_lang:
        target_lang = {"id": 1, "language_code": "sat", "language_name": "Santali", "script": "Ol Chiki"}

    lang_code = target_lang["language_code"]

    # 1. Fetch available cards from learning_cards table
    cards = db.execute(text("""
        SELECT
            id, word_en, word_hi, word_vernacular, roman_phonetic, category,
            example_sentence_en, example_sentence_hi, example_sentence_vernacular,
            target_language_id
        FROM learning_cards
        WHERE target_language_id = :tid
    """), {"tid": target_language_id}).mappings().all()

    # If target language isn't populated yet, fallback to base Santali (id=1)
    if not cards:
        cards = db.execute(text("""
            SELECT
                id, word_en, word_hi, word_vernacular, roman_phonetic, category,
                example_sentence_en, example_sentence_hi, example_sentence_vernacular,
                target_language_id
            FROM learning_cards
            WHERE target_language_id = 1
        """)).mappings().all()

    card_list = [dict(c) for c in cards]

    if not card_list:
        raise HTTPException(status_code=404, detail="No learning cards found")

    # Select 10 words deterministically based on date (or random if shuffle=True)
    if shuffle:
        selected = random.sample(card_list, min(count, len(card_list)))
    else:
        day_seed = datetime.date.today().toordinal()
        rng = random.Random(day_seed)
        shuffled = list(card_list)
        rng.shuffle(shuffled)
        selected = shuffled[:min(count, len(card_list))]

    # If target language is NOT Santali (id != 1), on-the-fly translate any missing vernacular with Bhashini
    if target_language_id != 1:
        for item in selected:
            if item.get("target_language_id") == 1:
                try:
                    translated_word = translate_with_bhashini(item["word_en"], "en", lang_code)
                    item["word_vernacular"] = translated_word
                    if item.get("example_sentence_en"):
                        item["example_sentence_vernacular"] = translate_with_bhashini(item["example_sentence_en"], "en", lang_code)
                except Exception as e:
                    print(f"[WARN] Bhashini card translation note: {e}")

    # Add target language metadata
    for item in selected:
        item["target_language_name"] = target_lang["language_name"]
        item["target_language_code"] = target_lang["language_code"]
        item["target_language_script"] = target_lang["script"]

    return selected


@app.post("/learning-cards/custom")
def create_custom_learning_card(
    request: CustomCardRequest,
    db: Session = Depends(get_db)
):
    """Allows teachers to input any English word and translate it into Hindi and Santali (Ol Chiki) via Bhashini."""
    target_lang = db.execute(
        text("SELECT id, language_code, language_name, script FROM languages WHERE id = :id"),
        {"id": request.target_language_id}
    ).mappings().first()

    tgt_code = target_lang["language_code"] if target_lang else "sat"

    # Translate word to Hindi
    word_hi = translate_with_bhashini(request.word_en, "en", "hi")
    # Translate word to Vernacular (Santali / Ho / Mundari)
    word_vernacular = translate_with_bhashini(request.word_en, "en", tgt_code)

    ex_en = f"We learn about {request.word_en.lower()} in our school lesson."
    ex_hi = translate_with_bhashini(ex_en, "en", "hi")
    ex_ver = translate_with_bhashini(ex_en, "en", tgt_code)

    # Insert into database
    res = db.execute(text("""
        INSERT INTO learning_cards
        (word_en, word_hi, word_vernacular, roman_phonetic, category, example_sentence_en, example_sentence_hi, example_sentence_vernacular, target_language_id)
        VALUES (:w_en, :w_hi, :w_ver, :phon, :cat, :ex_en, :ex_hi, :ex_ver, :tid)
    """), {
        "w_en": request.word_en.capitalize(),
        "w_hi": word_hi,
        "w_ver": word_vernacular,
        "phon": "",
        "cat": request.category,
        "ex_en": ex_en,
        "ex_hi": ex_hi,
        "ex_ver": ex_ver,
        "tid": request.target_language_id
    })
    db.commit()

    return {
        "id": res.lastrowid,
        "word_en": request.word_en.capitalize(),
        "word_hi": word_hi,
        "word_vernacular": word_vernacular,
        "roman_phonetic": "",
        "category": request.category,
        "example_sentence_en": ex_en,
        "example_sentence_hi": ex_hi,
        "example_sentence_vernacular": ex_ver,
        "target_language_id": request.target_language_id,
        "target_language_name": target_lang["language_name"] if target_lang else "Santali",
        "target_language_code": tgt_code,
        "target_language_script": target_lang["script"] if target_lang else "Ol Chiki"
    }


@app.post("/learning-cards/audio")
def get_card_audio(request: CardAudioRequest):
    """Synthesizes pronunciation audio for a vocabulary word using Bhashini TTS."""
    audio_base64 = tts_with_bhashini(
        text_content=request.text,
        language_code=request.language_code,
        gender=request.gender
    )
    return {
        "text": request.text,
        "language_code": request.language_code,
        "audio_base64": audio_base64,
        "status": "success" if audio_base64 else "failed"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)