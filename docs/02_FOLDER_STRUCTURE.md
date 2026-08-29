# 02_FOLDER_STRUCTURE.md

## Complete lib/ Folder Tree

```
lib/
├── main.dart
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   ├── constants/
│   │   └── app_constants.dart
│   ├── routing/
│   │   └── app_router.dart          # go_router config, section-gated routes
│   └── utils/
│       ├── validators.dart          # email/password/OTP input validation
│       └── formatters.dart          # date, distance ("~X.X km") formatting
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── worker_profile_model.dart
│   │   ├── barangay_model.dart
│   │   ├── booking_model.dart       # added Section 1
│   │   └── auth_result_model.dart   # wraps {success, message, data/errors}
│   │
│   └── repositories/
│       ├── auth_repository.dart             # abstract interface
│       ├── worker_repository.dart           # abstract interface (Section 1+)
│       ├── booking_repository.dart          # abstract interface (Section 1+)
│       ├── mock/
│       │   ├── mock_auth_repository.dart
│       │   ├── mock_worker_repository.dart
│       │   └── mock_booking_repository.dart
│       └── api/
│           ├── api_auth_repository.dart
│           ├── api_worker_repository.dart
│           └── api_booking_repository.dart
│
├── providers/
│   ├── auth_provider.dart           # ChangeNotifier — current user, token, auth state
│   ├── worker_search_provider.dart  # Section 1
│   └── booking_provider.dart        # Section 1
│
├── services/
│   ├── service_locator.dart         # single swap point: mock vs api repositories
│   ├── secure_storage_service.dart  # token storage wrapper
│   └── google_auth_service.dart     # google_sign_in wrapper
│
├── widgets/                          # shared/reusable widgets, used across screens
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   └── google_signin_button.dart
│   ├── inputs/
│   │   ├── text_input_field.dart
│   │   └── otp_input_row.dart
│   ├── cards/
│   │   ├── worker_card.dart          # Section 1
│   │   └── booking_card.dart         # Section 1
│   ├── navigation/
│   │   ├── client_bottom_nav.dart    # Section 1
│   │   └── worker_bottom_nav.dart    # Section 2
│   └── states/
│       ├── empty_state.dart
│       └── loading_shimmer.dart
│
└── screens/
├── section_0_onboarding_auth/
│   ├── splash_screen.dart
│   ├── onboarding_slides_screen.dart
│   ├── registration_role_screen.dart
│   ├── registration_account_screen.dart
│   ├── email_verification_screen.dart
│   ├── complete_profile_screen.dart      # Google path only
│   ├── login_screen.dart
│   ├── forgot_password_screen.dart
│   └── security_settings_screen.dart
│
├── section_1_client/                     # locked until PM approves Section 0
│   ├── client_home_screen.dart
│   ├── worker_search_screen.dart
│   ├── worker_profile_view_screen.dart
│   ├── send_booking_request_screen.dart
│   ├── booking_history_screen.dart
│   ├── booking_detail_screen.dart
│   ├── live_worker_tracking_widget.dart   # embedded in booking_detail
│   ├── rate_review_screen.dart
│   ├── file_report_screen.dart
│   └── report_status_screen.dart
│
├── section_2_worker/                     # locked until PM approves Section 1
│   ├── worker_home_dashboard_screen.dart
│   ├── verification_document_screen.dart
│   ├── verification_status_screen.dart
│   ├── portfolio_skills_screen.dart
│   ├── booking_schedule_screen.dart
│   ├── job_detail_screen.dart             # includes map
│   ├── rate_client_screen.dart
│   └── worker_report_screen.dart
│
└── section_3_shared/                     # locked until PM approves Section 2
├── chat_inbox_screen.dart
├── chat_thread_screen.dart
├── notification_center_screen.dart
├── profile_tab_screen.dart
├── edit_profile_screen.dart
├── notification_preferences_screen.dart
└── help_faq_screen.dart
```

---

## Folder Purpose Reference

| Folder | Purpose |
|---|---|
| `core/theme/` | Design tokens — colors, typography, spacing. Filled in `03_DESIGN_SYSTEM.md`. |
| `core/routing/` | Single `go_router` config; enforce the section-gate rule here (routes for locked sections simply don't exist yet). |
| `core/utils/` | Pure functions — no state, no widgets. |
| `data/models/` | Plain Dart classes mirroring the Laravel API's JSON `data` payloads. |
| `data/repositories/` | Abstract interfaces + `mock/` and `api/` implementations. See `01_SETUP_GUIDE.md` §5. |
| `providers/` | `ChangeNotifier` classes consumed via `provider`. Screens read state from these, never call repositories directly. |
| `services/` | Cross-cutting singletons: DI wiring, secure storage, Google auth. |
| `widgets/` | Anything reused across 2+ screens. If a widget is only used on one screen, keep it private to that screen's file instead. |
| `screens/section_X_.../` | One folder per section, matching the section-gate rule exactly. Do not create a `section_1_client/` file until Section 0 is PM-approved. |

---

## Naming Conventions

```
Files:      snake_case.dart
Classes:    PascalCase
Screens:    <Name>Screen           (e.g. LoginScreen)
Widgets:    <Name>Widget or plain descriptive name (e.g. PrimaryButton)
Providers:  <Name>Provider         (e.g. AuthProvider)
Repositories: <Name>Repository (interface), Mock<Name>Repository, Api<Name>Repository
Models:     <Name>Model            (e.g. UserModel)
```

---

## Rule of Thumb for New Files

- A new **screen** → goes in its section's folder. Only create files for the current unlocked section.
- A new **shared visual component** → `widgets/`, in the most specific subfolder that fits.
- A new **API call** → add a method to the relevant abstract repository, then implement in both `mock/` and `api/`.
- Never call `http` directly inside a screen or widget — always go through a provider → repository.

---
