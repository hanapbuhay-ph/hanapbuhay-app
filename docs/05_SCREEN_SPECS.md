# 05_SCREEN_SPECS.md

## Section 0 — Onboarding & Auth (9 Screens) — FULLY DETAILED

Section 1, 2, 3 specs remain **locked** and will be added only after PM approves the prior section.

---

### 0.1 Splash Screen

**File:** `splash_screen.dart`

**Purpose:** Brief branded loading screen while the app checks auth state.

**Layout:**
- Full-screen, `AppColors.primaryGreen` background (or gradient per Stitch HTML)
- Centered mascot logo (`assets/images/logo.png`)
- App name "HanapBuhay" below logo, white text, `AppTypography.h1`

**Logic:**
- On init, check `SecureStorageService` for a saved auth token
- Token exists + valid → navigate to appropriate home (`client_home` or `worker_home_dashboard` based on saved role)
- No token → navigate to `onboarding_slides_screen` (first launch) or `login_screen` (returning user, use a `hasSeenOnboarding` flag in `shared_preferences`)
- Minimum display time: 1.5s (avoid flash even if the check is instant)

**States:** none (transient screen)

---

### 0.2 Onboarding Slides

**File:** `onboarding_slides_screen.dart`

**Purpose:** 4-slide intro carousel for first-time users.

**Layout:**
- `PageView` with 4 slides, illustration + `h2` title + `bodyMedium` description per slide
- `smooth_page_indicator` dots below the PageView
- "Skip" button top-right (all slides except last)
- Bottom: "Next" `PrimaryButton` (slides 1–3), "Get Started" `PrimaryButton` (slide 4)

**Logic:**
- "Skip" or "Get Started" → set `hasSeenOnboarding = true` in shared_preferences, navigate to `registration_role_screen`

**States:** none

---

### 0.3 Registration — Role Selection

**File:** `registration_role_screen.dart`

**Purpose:** User picks Client or Worker before entering account details.

**Layout:**
- Two large selectable cards: "I need a worker" (Client) / "I offer services" (Worker), each with icon + short description
- Selected card gets `primaryGreen` border highlight
- `PrimaryButton` "Continue" (disabled until a role is selected)
- Small text link at bottom: "Already have an account? Log in" → `login_screen`

**Logic:**
- Store selected role in local state, pass forward to `registration_account_screen` via navigation extra/argument

**States:** default, selected

---

### 0.4 Registration — Account Details (Manual)

**File:** `registration_account_screen.dart`

**Purpose:** Collect manual signup details, or offer Google Sign-In.

**Fields:**
- Full name (`TextInputField`)
- Email (`TextInputField`, email validation)
- Mobile number (`TextInputField`, PH format — collected but NOT OTP-verified)
- Barangay (dropdown, populated from `GET /api/barangays` — 20 Trinidad barangays only, no freeform input)
- Password (`TextInputField`, obscured, visibility toggle)
- Confirm password (`TextInputField`, obscured, must match)

**Layout:**
- Fields above, in order
- `PrimaryButton` "Create Account"
- Divider with "or"
- `GoogleSignInButton` "Continue with Google"
- Bottom link: "Already have an account? Log in"

**Logic:**
- Manual path: validate all fields client-side → call `AuthRepository.register()` → on success, navigate to `email_verification_screen` (pass email as argument)
- On validation/API error: show inline field errors from the `errors` map in the API response envelope
- Google path: trigger `GoogleAuthService`, on success call `AuthRepository.registerWithGoogle()` (mocked until backend endpoint exists) → navigate to `complete_profile_screen`
- Role selected in 0.3 is submitted as part of the register payload

**States:** default, field errors, loading (button shows spinner), submit error (snackbar/banner for non-field errors, e.g. "Email already registered")

**API:** `POST /api/auth/register` — **already live**, point `ApiAuthRepository` at the real endpoint.

---

### 0.5 Email Verification Screen (Manual Only)

**File:** `email_verification_screen.dart`

**Purpose:** 6-digit OTP entry sent to the email used in 0.4.

**Layout:**
- Header: "Verify your email", `bodyMedium` subtext showing the masked/full email
- `OtpInputRow` (6 boxes, auto-advance, auto-submit on complete)
- "Resend code" text link, disabled with a countdown timer (e.g. 60s) after each send
- `PrimaryButton` "Verify" (also triggered by auto-submit)

**Logic:**
- On complete/submit → call `AuthRepository.verifyOtp(email, otp)`
- Success → store Sanctum token via `SecureStorageService`, navigate to role-appropriate home screen
- Error (wrong/expired code) → shake animation on `OtpInputRow`, error text below, clear boxes
- "Resend" → re-trigger the register/OTP-send flow (or a dedicated resend endpoint if the PM confirms one), restart the countdown

**States:** default, loading, error, resend-cooldown

**API:** `POST /api/auth/verify-otp` — **already live**, point `ApiAuthRepository` at the real endpoint.

---

### 0.5b Complete Your Profile (Google Path Only)

**File:** `complete_profile_screen.dart`

**Purpose:** Collect the fields Google doesn't provide (mobile number, barangay) after Google Sign-In, since Google-verified email skips OTP entirely.

**Fields:**
- Email (`TextInputField`, **greyed out / disabled**, pre-filled from Google, label "Provided by Google")
- Full name (pre-filled from Google, editable)
- Mobile number (`TextInputField`, required)
- Barangay (dropdown, required, same source as 0.4)

**Layout:**
- Same visual pattern as 0.4 minus password fields, email field visually disabled
- `PrimaryButton` "Complete Profile"

**Logic:**
- Submit → call `AuthRepository.completeGoogleProfile()` (mock until backend endpoint exists) → store token → navigate to role-appropriate home
- No OTP step in this path at all — do not add one

**States:** default, field errors, loading

**API:** `POST /api/auth/google/complete-profile` — not yet built, use mock.

---

### 0.6 Login Screen

**File:** `login_screen.dart`

**Purpose:** Returning user sign-in.

**Fields:**
- Email (`TextInputField`)
- Password (`TextInputField`, obscured, visibility toggle)

**Layout:**
- Fields above
- "Forgot Password?" link — appears **only under the manual login form, not near the Google button**
- `PrimaryButton` "Log In"
- Divider "or"
- `GoogleSignInButton` "Continue with Google"
- Bottom link: "Don't have an account? Sign up" → `registration_role_screen`

**Logic:**
- Manual path → `AuthRepository.login(email, password)` (mock until backend endpoint exists) → store token → navigate to role-appropriate home
- Google path → same as registration's Google path, but for an existing account: if the Google account is new, backend/mock should route to `complete_profile_screen`; if it already has a complete profile, go straight to home
- Invalid credentials → non-field error banner, do not specify whether it was email or password (security best practice)

**States:** default, field errors, loading, invalid-credentials error

**API:** `POST /api/auth/login`, `POST /api/auth/google` — not yet built, use mock.

---

### 0.7 Forgot Password Screen

**File:** `forgot_password_screen.dart`

**Purpose:** Email-OTP-based password reset (no SMS).

**Flow (single screen file, multi-step internal state):**
1. **Step 1 — Enter email:** `TextInputField` + `PrimaryButton` "Send Code" → calls `AuthRepository.forgotPassword(email)` (mock until backend endpoint exists)
2. **Step 2 — Enter OTP:** `OtpInputRow` (reuse same widget as 0.5), "Resend code" with cooldown
3. **Step 3 — New password:** New password + confirm password fields, `PrimaryButton` "Reset Password"

**Logic:**
- Each step's "Next"/submit action calls the corresponding repository method, advances internal step state on success
- On full success → show a brief success state, then navigate to `login_screen`

**States per step:** default, loading, error (invalid email / wrong OTP / password mismatch)

**API:** `POST /api/auth/password/forgot`, `POST /api/auth/password/verify-otp`, `POST /api/auth/password/reset` — not yet built, use mock.

---

### 0.8 Security Settings Screen

**File:** `security_settings_screen.dart`

**Purpose:** Post-login settings for changing password / managing account security. (Reachable from Profile tab in Section 3, but scaffolded now since it's part of Section 0's auth flow.)

**Layout:**
- List-style settings screen: "Change Password" row → navigates to a change-password form (reuse password field pattern from 0.7 step 3, but requires current password too)
- "Log Out" row (destructive style, confirmation dialog before action)

**Logic:**
- Change password → calls an authenticated password-change endpoint (mock until backend endpoint exists)
- Log out → clear token via `SecureStorageService`, clear `AuthProvider` state, navigate to `login_screen`, clear navigation stack

**States:** default, loading, error, success (toast/snackbar confirmation)

**API:** not yet built, use mock.

---

## Section 0 Navigation Flow Summary

```
splash_screen
├─(no token, first launch)→ onboarding_slides_screen → registration_role_screen
├─(no token, returning)→ login_screen
└─(valid token)→ client_home / worker_home_dashboard (Section 1/2, locked)

registration_role_screen → registration_account_screen
registration_account_screen
├─(manual)→ email_verification_screen → [home, locked]
└─(google)→ complete_profile_screen → [home, locked]

login_screen
├─(manual, success)→ [home, locked]
├─(google, new account)→ complete_profile_screen
├─(google, existing)→ [home, locked]
└─(forgot password link)→ forgot_password_screen → login_screen (after reset)

security_settings_screen ← reachable post-login (Section 3 Profile tab will link here)
```

---

## Sections 1, 2, 3 — LOCKED

Do not generate detailed specs for these until the PM confirms Section 0 is approved. When unlocked, each will follow the same format as above: Purpose, Fields/Layout, Logic, States, API endpoint(s) with live/mock status.

```
Section 1 (Client, 10 screens)  — LOCKED
Section 2 (Worker, 8 screens)   — LOCKED
Section 3 (Shared Utility, 7 screens) — LOCKED
```

---
