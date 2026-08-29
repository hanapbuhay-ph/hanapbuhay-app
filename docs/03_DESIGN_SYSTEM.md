# 03_DESIGN_SYSTEM.md

> Note: The Stitch export's `DESIGN.md` is the source of truth for exact values. This file gives Gemini a locked Dart-code baseline consistent with what's known from the handoff; if the Stitch `DESIGN.md` specifies a different exact shade/spacing scale, **Stitch DESIGN.md wins** — update the token files to match it, then treat that as final.

---

## 1. Colors — `lib/core/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF2E9B2E);
  static const Color darkGreen    = Color(0xFF1D7A37);

  static const Color background   = Color(0xFFF5F5F5);
  static const Color cardWhite    = Color(0xFFFFFFFF);

  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Semantic colors — confirm exact hex against Stitch DESIGN.md
  static const Color error   = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E9B2E); // reuse primary
  static const Color warning = Color(0xFFF59E0B);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFBDBDBD);
}
```

---

## 2. Typography — `lib/core/theme/app_typography.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String headingFont = 'Poppins';
  static const String bodyFont    = 'Inter';

  static const TextStyle h1 = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    color: AppColors.textSecondary,
  );
}
```

---

## 3. Spacing — `lib/core/theme/app_spacing.dart`

```dart
class AppSpacing {
  AppSpacing._();

  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;

  static const double cardRadius   = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius  = 12.0;

  static const double screenPadding = 20.0;
}
```

---

## 4. Shadows

```dart
import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000), // ~8% black
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
```

Cards should read as light and "floaty" per the Tarsi-style reference — avoid heavy/dark shadows.

---

## 5. Component Specs

### PrimaryButton
- Height: 52
- Radius: `AppSpacing.buttonRadius` (12)
- Fill: `AppColors.primaryGreen`, pressed/darker state uses `AppColors.darkGreen`
- Text: `AppTypography.button`
- Disabled state: `AppColors.disabled` fill, no shadow
- Loading state: replace label with a small centered spinner, keep button size fixed (no layout shift)

### GoogleSignInButton
- Height: 52, white fill, 1px `AppColors.divider` border, `AppSpacing.buttonRadius`
- Google "G" logo left-aligned, label "Continue with Google" centered, `AppTypography.bodyLarge` weight 600

### TextInputField
- Height: 52, radius `AppSpacing.inputRadius`
- Default border: `AppColors.divider`; focused border: `AppColors.primaryGreen`; error border: `AppColors.error`
- Label floats above on focus/filled (Material-style), helper/error text below in `AppTypography.bodySmall`
- Optional leading icon slot, optional trailing icon slot (e.g. password visibility toggle)

### OtpInputRow
- 6 individual boxes (per `AppConstants.otpLength`)
- Each box: 48x56, radius `AppSpacing.inputRadius`, `AppTypography.h2` centered digit
- Auto-advance focus to next box on input, auto-submit when all 6 filled
- Error state: all boxes get `AppColors.error` border + shake animation

### WorkerCard (Section 1)
- White card, `AppSpacing.cardRadius`, `AppShadows.card`
- Row layout: circular avatar (56x56) — worker name (`h3`) + service category (`bodySmall`) — trust badge if verified
- Bottom row: rating stars + review count, distance label `"~X.X km · Barangay Name"` (`bodySmall`, `textSecondary`)

### BookingCard (Section 1/2)
- White card, `AppSpacing.cardRadius`, `AppShadows.card`
- Status pill top-right (color-coded: pending=warning, accepted/active=primaryGreen, completed=textSecondary, cancelled=error)
- Worker/client name + service + scheduled date/time
- Tap → navigates to detail screen

### Bottom Navigation Bars
- `ClientBottomNav`: Home, Bookings, Messages, Notifications, Profile (5 tabs)
- `WorkerBottomNav`: Home, Jobs, Messages, Notifications, Profile (5 tabs)
- Active tab: `primaryGreen` icon + label; inactive: `textSecondary`
- Icons filled when active, outlined when inactive (Material 3 convention)

### EmptyState
- Centered illustration/icon slot, `h3` title, `bodyMedium` description (`textSecondary`), optional `PrimaryButton` action below
- Used for: no bookings yet, no search results, no notifications, etc.

### LoadingShimmer
- Uses the `shimmer` package
- Card-shaped skeletons matching `WorkerCard`/`BookingCard` dimensions, shown while mock/API calls are in flight

---

## 6. Applying to MaterialApp Theme

```dart
ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryGreen,
    primary: AppColors.primaryGreen,
  ),
  fontFamily: AppTypography.bodyFont,
  useMaterial3: true,
)
```

---

## 7. Logo Usage

The mascot logo (Filipino boy, salakot hat, magnifying glass, house icon, green gradient background) is used:
- Splash screen — centered, large
- Onboarding slides — small, top-left or top-center
- Login/registration headers — medium size

Never recolor, stretch, or recreate the logo — always use the exact asset from `assets/images/logo.png`. If a screen's Stitch HTML shows a different logo treatment, flag it to the PM rather than guessing.

---
