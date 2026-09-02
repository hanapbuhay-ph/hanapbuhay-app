# Implementation Plan - Email Verification Screen (S6) UI Overhaul

Redesign the Email Verification Screen to strictly follow the `05_APP_CLIENT_WIREFRAME.md` specification.

## User Review Required
> [!IMPORTANT]
> The screen features a prominent 72px green email icon and a dedicated 6-box OTP input row.
> All typography will be synced to **Plus Jakarta Sans**.
> The resend logic will include a 60-second countdown timer.

## Proposed Changes

### Section 0: Shared Screens
#### [MODIFY] [email_verification_screen.dart](file:///C:/Users/iza/AndroidStudioProjects/hanapbuhayapp/lib/screens/section_0_onboarding_auth/email_verification_screen.dart)
- **Top Section**:
    - Back arrow.
    - `Icons.mark_email_unread` (72px, #2E9B2E).
    - "Check Your Email" (SemiBold 22px).
    - "We sent a verification code to [email]" (Inter Regular 14px / SemiBold 14px).
- **OTP Input**:
    - Row of 6 individual boxes (46x56px, radius 12).
    - Auto-focus next/previous on input/backspace.
- **Button**:
    - [Verify Email] green button (#2E9B2E).
- **Footer**:
    - "Didn't receive the code?" + "Resend Code" (Green) or "Resend in 60s" (Gray).
- **Branding**:
    - Primary green: #2E9B2E.

## Verification Plan

### Automated Tests
- `flutter analyze` to ensure 0 errors.

### Manual Verification
- Enter 6 digits and verify auto-submission or button activation.
- Test backspace behavior in OTP boxes.
- Verify resend timer countdown.
- Confirm dark theme compatibility.
