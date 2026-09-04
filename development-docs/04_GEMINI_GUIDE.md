# 04_GEMINI_GUIDE.md

## How to Use Gemini Code Assist in Android Studio for This Project

This guide is specific to **Gemini Code Assist**, not Amazon Q. The workflow differs slightly — Gemini works best with tightly scoped, single-screen prompts that include both visual and textual references attached together.

---

## 1. Before You Prompt: Gather Your References

For every screen, you need **two files** attached to the same Gemini prompt:

1. **The screen's Stitch HTML file** — visual reference for layout, spacing, and component placement
2. **The Stitch `DESIGN.md`** — design tokens (colors, typography, spacing) that back the HTML

Attaching both together matters: the HTML shows *what* to build, the DESIGN.md confirms *exact values* to use, and giving Gemini both at once significantly reduces flaw-correction iterations compared to attaching just the HTML.

Also keep on hand (referenced by path, not necessarily attached every time):
- `03_DESIGN_SYSTEM.md` (this project's finalized Dart token files)
- The relevant entry from `05_SCREEN_SPECS.md` for that screen

---

## 2. Prompt Structure Template

Use this structure for every screen prompt:

```
Build the Flutter screen: [ScreenName]

CONTEXT:
- This is part of HanapBuhay, a Flutter app using Provider for state
  management and go_router for navigation.
- Design tokens live in lib/core/theme/ (AppColors, AppTypography, AppSpacing)
  — use these, do not hardcode colors/fonts/spacing.
- This screen must use [RepositoryName] via [ProviderName] — never call
  http directly. See attached mock/api repository pattern.

ATTACHED REFERENCES:
1. [screen_name].html — Stitch visual reference for this screen
2. DESIGN.md — Stitch design tokens

KNOWN FLAWS TO FIX (use judgment beyond this list too):
- [list anything you already know is off, e.g. "spacing under the
  logo is inconsistent — use AppSpacing.lg"]

SPEC:
[Paste the relevant section from 05_SCREEN_SPECS.md — fields, validation
rules, navigation targets, states (loading/error/empty) for this screen]

OUTPUT:
- A single StatefulWidget or StatelessWidget file at
  lib/screens/section_0_onboarding_auth/[screen_name]_screen.dart
- Follow the naming conventions in 02_FOLDER_STRUCTURE.md
- Add brief doc comments explaining any deviation from the HTML reference
  and why
```

---

## 3. Fixing Stitch's Visual Flaws

The Stitch export is not pixel-perfect. Tell Gemini explicitly, every time, to:
- Fix obvious spacing/alignment inconsistencies using `AppSpacing` values (never arbitrary pixel numbers)
- Replace any hardcoded colors in the HTML with the matching `AppColors` token
- Ensure text uses `AppTypography` styles, not the HTML's raw font-sizes
- Preserve the overall **layout structure and design intent** — don't let Gemini "reimagine" the screen, only clean it up

If Gemini's output changes the layout structure significantly from the HTML, that's a sign it over-corrected — regenerate with a more constrained prompt.

---

## 4. Attaching Reference Screenshots/Files in Android Studio

1. Open the Gemini Code Assist panel (View → Tool Windows → Gemini, or the sidebar icon).
2. Use the attachment/context icon in the chat input to attach files.
3. Attach the screen's `.html` file and `DESIGN.md` from your local Stitch export folder.
4. Paste the structured prompt (Section 2 above) as your message text.
5. Review the generated Dart file before accepting — check against the checklist in Section 6.

If Gemini's context window truncates a large HTML file, trim it to just the relevant screen's markup/CSS block rather than the whole exported bundle.

---

## 5. Common Gemini Errors and Fixes

| Issue | Fix |
|---|---|
| Gemini hardcodes colors/fonts instead of using `AppColors`/`AppTypography` | Re-prompt explicitly: "Replace all hardcoded style values with the AppColors/AppTypography/AppSpacing tokens shown in 03_DESIGN_SYSTEM.md" |
| Gemini calls `http` directly in the widget | Re-prompt: "This screen must not call http directly — use [ProviderName] from provider, which wraps [RepositoryName]" |
| Gemini invents a repository method that doesn't exist | Check `data/repositories/` — if the method is genuinely needed, add it to the abstract interface + both mock/api implementations first, then re-prompt referencing the updated interface |
| Gemini ignores go_router and uses `Navigator.push` directly | Re-prompt: "Use go_router's context.push()/context.go() per app_router.dart, not Navigator.push" |
| Generated widget doesn't handle loading/error/empty states | Re-prompt with explicit state requirements from `05_SCREEN_SPECS.md` |
| Gemini "improves" the layout beyond fixing obvious flaws | Re-prompt with: "Preserve the original layout structure from the HTML exactly — only fix spacing/color/font token usage, not structure" |
| Screen doesn't match Section 0 navigation flow (e.g. wrong next screen) | Cross-check against `05_SCREEN_SPECS.md` navigation targets, correct manually if needed |

---

## 6. Code Quality Checklist (Before Marking a Screen Done)

```
[ ] Uses AppColors / AppTypography / AppSpacing — no hardcoded values
[ ] No direct http calls — goes through Provider → Repository
[ ] File placed in correct section_X folder per 02_FOLDER_STRUCTURE.md
[ ] Naming matches conventions (snake_case file, PascalCase class)
[ ] Handles loading, error, and empty states where applicable
[ ] Navigation uses go_router, matches 05_SCREEN_SPECS.md flow
[ ] Layout structure matches the Stitch HTML reference (flaws fixed,
structure preserved)
[ ] Runs without errors on emulator (flutter run / hot reload)
[ ] Mock repository returns data in the exact shape the real API will
(per {success, message, data/errors} envelope)
```

---

## 7. One Screen at a Time

Do not batch-prompt multiple screens in one Gemini request — this project has had better results scoping one screen per prompt. Complete, review, and commit one screen before moving to the next.

---

