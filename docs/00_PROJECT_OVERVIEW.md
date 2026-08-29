# 00_PROJECT_OVERVIEW.md

## Project: HanapBuhay

HanapBuhay is a **barangay-verified community skilled worker marketplace** serving **Trinidad, Bohol only** (20 barangays seeded in the database). It connects **Clients** who need local skilled workers with **Workers** who offer services, all verified through the barangay system.

The product is one Flutter mobile app (Client + Worker roles in a single app) + a React admin web panel, both consuming one shared Laravel REST API backend.

---

## Team & Roles

| Role | Person | Tool |
|---|---|---|
| Project Manager / Backend Dev | Otrebla (Alberto) | Laravel + Amazon Q |
| UI/UX Designer | — | Figma / Google Stitch |
| App Dev (you) | — | Flutter + **Gemini Code Assist** in Android Studio |
| Web Dev | — | React + Laravel |
| QA Tester | — | — |

You are the **App Dev**. You build the Flutter mobile app using **Gemini Code Assist inside Android Studio**. This is different from the backend team's Amazon Q workflow — all guides written for you are Gemini-specific.

---

## GitHub Repositories

```
Org:         github.com/hanapbuhay-ph
Backend:     github.com/hanapbuhay-ph/hanapbuhay-api    (branch: develop, main protected)
Flutter app: github.com/hanapbuhay-ph/hanapbuhay-app    (your repo)
React web:   github.com/hanapbuhay-ph/hanapbuhay-web
```

---

## Tech Stack (Locked — Do Not Change)

```
Mobile:       Flutter (Dart)
Backend:      Laravel 13, PHP 8.5
Database:     MySQL (via Laragon, local dev)
Auth:         Laravel Sanctum (tokens)
Google Auth:  Laravel Socialite
Email OTP:    Laravel Mail + Brevo (free SMTP)
Push Notifs:  Firebase FCM (Phase 3, deferred — not needed yet)
Real-Time:    Laravel Echo + Soketi (WebSocket)
Maps:         Google Maps Flutter
Dev Server:   php artisan serve → http://127.0.0.1:8000
```

---

## API Base URLs

```
Local dev (PM's machine):  http://127.0.0.1:8000/api
Android emulator:           http://10.0.2.2:8000/api
Physical device:            http://[PM's local IP]:8000/api  (same WiFi required)
```

## Standard API Response Format

```json
// Success
{
  "success": true,
  "message": "Description",
  "data": { }
}

// Error
{
  "success": false,
  "message": "Human readable error",
  "errors": { "field": ["message"] }
}
```

---

## Development Strategy: Mock-First, API-Ready

The backend is being built in parallel and most endpoints don't exist yet. To avoid being blocked:

- You will build against **repository interfaces** (e.g. `AuthRepository`), never call `http` directly from screens/widgets.
- Each interface gets a **Mock implementation** (fake data matching the real API's JSON shape above) and a **real API implementation**.
- Which implementation is "live" is controlled by dependency injection in one place — swapping a mock for the real thing later requires **zero screen code changes**.
- As of this writing, `POST /api/auth/register` and `POST /api/auth/verify-otp` are already built and tested on the backend — those two can point to the real API now if desired; everything else stays mocked until the PM confirms an endpoint is ready.

Full detail on this pattern is in `01_SETUP_GUIDE.md` and `04_GEMINI_GUIDE.md`.

---

## Section Gate Rule (Critical)

The app is built in **locked sections**. You must complete a section and get **PM approval** before starting the next one. Do not build ahead.

```
Section 0 (Onboarding & Auth) → PM approves → Section 1 (Client)
Section 1 (Client)            → PM approves → Section 2 (Worker)
Section 2 (Worker)            → PM approves → Section 3 (Shared Utility)
```

Currently unlocked: **Section 0 only.**

---

## UI Reference Source

All screen designs come from **Google Stitch**, exported as a ZIP with one subfolder per screen. Each screen subfolder contains:
- An **HTML file** — the visual reference for that screen
- A shared **DESIGN.md** — design tokens, color palette, typography scale, and component specs used by Stitch

**Always attach both the screen's HTML file AND the DESIGN.md together** in every Gemini prompt. The Stitch UI has some visual flaws/inconsistencies — use common sense to fix obvious flaws while staying true to the overall design intent (colors, layout structure, component style). Full prompting guidance is in `04_GEMINI_GUIDE.md`.

---

## Design System (Quick Reference)

```
Primary font:    Poppins (headings)
Secondary font:  Inter (body)
Primary green:   #2E9B2E
Dark green:      #1D7A37
Background:      #F5F5F5
Card white:      #FFFFFF
Text primary:    #1A1A1A
Text secondary:  #6B6B6B
Style reference: Tarsi app — card-based, clean, generous whitespace
Logo:            Filipino boy mascot, salakot hat, magnifying glass,
                 house icon, green gradient background
```

Full spec in `03_DESIGN_SYSTEM.md`.

---

## Out of Scope — Do Not Build

```
❌ Payments (all transactions offline/cash)
❌ SMS OTP (email OTP only — SMS costs money)
❌ IoT features
❌ Any barangay outside Trinidad, Bohol
```

---

## File Index

```
00_PROJECT_OVERVIEW.md   ← you are here
01_SETUP_GUIDE.md        Flutter project setup, pubspec.yaml, config files
02_FOLDER_STRUCTURE.md   Complete lib/ folder tree
03_DESIGN_SYSTEM.md      Colors, typography, spacing, component specs
04_GEMINI_GUIDE.md       How to prompt Gemini Code Assist effectively
05_SCREEN_SPECS.md       Section 0 detailed screen-by-screen specs
06_WORKFLOW_GUIDE.md     Git workflow, PR process, progress reporting
```
```

---

