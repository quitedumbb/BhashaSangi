# Bhasha Sangi (भाषा संगी) Frontend

> **“AI powered vernacular pedagogy and real time translation tool for mother tongue based primary education.”**

---

## 🎨 Visual Identity & Pedagogy

Bhasha Sangi is designed to feel like a **warm Indian classroom** rather than a sterile tech dashboard:
* **Terracotta** (`#B44B2C`): Anchors actions, primary buttons, and accents.
* **Muted Marigold** (`#D97706`): Used for pedagogical badges, status highlights, and tips.
* **Earthy Sage** (`#386641`): Used for vernacular confirmations and healthy connection indicators.
* **Warm Cream / Sandalwood Parchment** (`#FBF8F2`, `#F4ECE1`): Paper-like background for eye comfort.
* **Dark Brown Ink** (`#2C1E17`): High contrast readable typography.

---

## 📁 Architecture & File Layout

```
bhasha_sangi_frontend/
├── lib/
│   ├── config/
│   │   ├── api_config.dart       # Configurable API_BASE_URL (http://127.0.0.1:8000 default)
│   │   └── theme.dart            # Material 3 Warm Classroom theme
│   ├── models/
│   │   ├── language.dart         # GET /languages contract
│   │   ├── translation.dart      # GET /translations contract
│   │   └── translation_result.dart # POST /translate contract (with pending state handler)
│   ├── services/
│   │   ├── api_service.dart      # Centralized HTTP client, error handling, health ping
│   │   └── auth_service.dart     # Teacher classroom profile & demo session state
│   ├── state/
│   │   └── classroom_state.dart  # Reactive state for active languages, library, & sync
│   ├── widgets/
│   │   ├── app_drawer.dart       # Responsive drawer with all 11 required navigation items
│   │   ├── app_header.dart       # Responsive top bar, live connection pill, teacher chip
│   │   ├── language_card.dart    # Vernacular language cards with source/target selection
│   │   ├── lesson_card.dart      # Lesson translation cards with pending status awareness
│   │   ├── coming_soon_card.dart # Respectful placeholders for roadmap capabilities
│   │   ├── error_view.dart       # Friendly error messages + collapsible dev diagnostics
│   │   └── loading_skeleton.dart # Shimmer card placeholders
│   ├── screens/
│   │   ├── home_screen.dart      # Classroom hero, compact "Speak & Translate", dashboard cards
│   │   ├── language_screen.dart  # Dynamic languages browser (GET /languages)
│   │   ├── translation_screen.dart # Core lesson translation tool (POST /translate)
│   │   ├── lessons_screen.dart   # Translation library with search & filter (GET /translations)
│   │   ├── downloads_screen.dart # Offline packs concept (Coming Soon)
│   │   ├── worksheets_screen.dart# Printable bilingual worksheets (Coming Soon)
│   │   ├── learning_cards_screen.dart # Interactive vernacular flashcards (Demo)
│   │   ├── community_voice_screen.dart # Community voice recordings (Coming Soon)
│   │   ├── sync_screen.dart      # Live backend health monitor & contract manifest
│   │   ├── settings_screen.dart  # Base URL switcher, language defaults & accessibility
│   │   └── login_screen.dart     # Teacher login and session profile
│   └── main.dart                 # Application shell & non-blocking startup
```

---

## 🚀 Running the Frontend

```bash
cd C:\Users\asus\.gemini\antigravity\scratch\bhasha_sangi_frontend

# Install dependencies
flutter pub get

# Run on Microsoft Edge
flutter run -d edge

# Or run on Chrome / Web server
flutter run -d chrome
```

---

## ⚙️ Backend Integration & CORS Configuration

Because Flutter Web runs in the browser, modern web standards require the FastAPI backend to allow Cross-Origin Resource Sharing (CORS) from the local Flutter origin.

In your FastAPI backend (`main.py`), add the following middleware:

```python
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session
from database import get_db

app = FastAPI(title="BhashaSangi API")

# Add CORS Middleware for Flutter Web:
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:*",
        "http://127.0.0.1:*",
        "*"  # Or specific port during development
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 📡 Backend API Contract Compliance

| Method | Endpoint | Frontend Handling |
|---|---|---|
| `GET` | `/` | Health check badge (Connected / Offline) & live sync ping |
| `GET` | `/languages` | Dynamically populates language cards and dropdowns (no hardcoded IDs) |
| `GET` | `/translations` | Translation library with search, filtering, and lesson title grouping |
| `POST` | `/translate` | Sends `source_language_id`, `target_language_id`, `source_text`, optional `lesson_id` & `dialect_id`. Handles `AI_TRANSLATION_PENDING` with clear teacher notice: *"Your request reached Bhasha Sangi. The AI translation service is not connected yet."* |

---

## 📌 Roadmap Features (No Fake APIs)

Features not currently exposed by the backend are clearly surfaced with **Coming Soon** notices explaining backend integration status:
* **Speak & Translate (ASR)**: One-tap button on Home page informs teacher that speech recognition is pending integration and routes to Text Translate.
* **Offline Downloads**: Local caching concept displayed with planned package sizes.
* **Worksheets**: Bilingual PDF generation concept presented.
* **Learning Cards**: Educational flip cards with Ol Chiki / Devanagari vocabulary.
* **Community Voice**: Dialect recording concept for tribal elders and storytellers.
* **Authentication**: Frontend demo session state structured for plug-and-play JWT integration later.
