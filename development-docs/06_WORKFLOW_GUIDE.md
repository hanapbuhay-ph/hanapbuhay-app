```markdown
# 06_WORKFLOW_GUIDE.md

## 1. Daily Git Workflow

Branch strategy: **feature branches → `develop`**. Never commit directly to `develop` or `main`.

```bash
# Start of a new screen/task
git checkout develop
git pull origin develop
git checkout -b feature/section0-login-screen

# ...work, commit as you go...

git add .
git commit -m "feat(auth): implement login screen"
git push -u origin feature/section0-login-screen
```

### Branch naming

```
feature/section<N>-<short-description>   e.g. feature/section0-otp-screen
fix/<short-description>                   e.g. fix/otp-resend-timer
chore/<short-description>                 e.g. chore/update-pubspec
```

---

## 2. Commit Message Conventions

Use Conventional Commits:

```
feat(auth): add email verification screen
fix(otp): correct resend cooldown timer
style(theme): adjust card shadow opacity
refactor(repo): extract auth result parsing
chore(deps): add shimmer package
docs: update screen spec for forgot password
```

Format: `type(scope): short description`, imperative mood, lowercase, no trailing period.

---

## 3. Pull Request Process

1. Push your feature branch, open a PR **into `develop`** (never `main`).
2. PR title follows the same convention as commits: `feat(auth): login screen`.
3. PR description should include:
    - Which screen(s)/section this covers
    - Screenshot or short screen recording of the result on emulator
    - Whether it uses mock or real API repository, and which
    - Any known deviations from the Stitch HTML (and why)
4. Request review from the PM (Otrebla).
5. Do not merge your own PR — wait for PM approval.
6. After merge, delete the feature branch (local + remote).

```bash
git branch -d feature/section0-login-screen
git push origin --delete feature/section0-login-screen
```

---

## 4. Reporting Progress to PM

At the end of each work session, report:

```
Screen(s) completed:      [list]
Section:                  [0/1/2/3]
Repository mode:          mock | real API (specify endpoint if real)
Blockers:                 [any Stitch ambiguity, missing asset, etc.]
Ready for review:         yes/no
```

When a full section is done, explicitly flag it for **section approval** before starting the next section's folder — this is the gate rule from `00_PROJECT_OVERVIEW.md`.

---

## 5. Connecting to the Laravel Backend

```
Android emulator:   http://10.0.2.2:8000/api
Physical device:    http://[PM's local IP]:8000/api   (same WiFi as PM's machine required)
```

Set the active URL in `lib/core/constants/app_constants.dart` → `AppConstants.apiBaseUrl`. Do not hardcode URLs anywhere else in the codebase.

**Current setup (per PM):** development proceeds mock-first. As the PM confirms individual backend endpoints are live and tested, swap that specific repository's `service_locator.dart` entry from `Mock*Repository` to `Api*Repository` — this should never require touching screen or provider code (see `01_SETUP_GUIDE.md` §5). Confirm with the PM before flipping any endpoint from mock to real, since the response shape needs to match exactly.

If you hit a connection error on a physical device: confirm both devices are on the same WiFi network, and that the PM's `php artisan serve` is bound to `0.0.0.0` (not just `127.0.0.1`) so it's reachable over LAN:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

---

## 6. Testing Before Marking Work Done

- Run on an emulator at minimum; physical device testing when auth/network flows are involved
- Hot reload during development; full restart before final verification (some state/DI changes need a cold start)
- Re-check the Code Quality Checklist in `04_GEMINI_GUIDE.md` §6 before opening a PR

---

## 7. When You're Blocked

- **Missing asset/screenshot** → ask PM, don't placeholder-guess
- **Ambiguous spec vs. Stitch HTML conflict** → written spec (`05_SCREEN_SPECS.md`) wins, per project rule; still flag it to PM
- **Need a backend endpoint that doesn't exist yet** → build against the mock, note it in your PR/progress report, don't block on backend

---
