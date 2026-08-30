# HanapBuhay — Mobile App Wireframe Description
**For: UI/UX Designer (Figma)**
**Platform:** Single mobile app, role-based (Client & Worker), built in Flutter
**Navigation Pattern:** Bottom navigation bar (role-specific tabs)
**Prepared by:** Project Manager

---

## How to Use This Document

Each screen below includes:
- **Purpose** — what the screen is for
- **Layout Zones** — how the screen is divided (top to bottom)
- **Key Elements** — components that must appear
- **Navigation / Interactions** — what happens when the user taps things
- **States** — empty, loading, or error variations to design if relevant

Screens are grouped in the order a user actually encounters them (user journey), not by database module. Each screen is tagged:
- 🔁 **Shared** — same screen for Client and Worker
- 👤 **Client Only**
- 🛠️ **Worker Only**

---

## SECTION 0 — Onboarding & Authentication (🔁 Shared)

### 0.1 Splash Screen
**Purpose:** Brief branded loading screen while the app initializes.
**Layout Zones:** Full-screen, centered.
**Key Elements:** HanapBuhay logo (centered), app name, subtle loading indicator.
**Navigation:** Auto-transitions to Onboarding (first-time users) or Login (returning users) after 1–2 seconds.

---

### 0.2 Onboarding Slides (4 slides, swipeable)
**Purpose:** Briefly introduce the app's value before requiring sign-up.
**Layout Zones:** Top illustration/icon area (60% of screen), bottom text + navigation area (40%).
**Key Elements per slide:**
- Illustration or icon
- Headline + short supporting text
- Pagination dots indicating slide position
- "Skip" text link (top right, all slides except last)
- "Next" button (slides 1–3) / "Get Started" button (slide 4)

**Slide Content:**
| Slide | Headline | Supporting Text |
|---|---|---|
| 1 | What is HanapBuhay? | Find skilled workers in your community — verified and trusted through your local barangay. |
| 2 | For Clients | Book electricians, plumbers, tutors, cleaners, and more — right in your neighborhood. |
| 3 | For Workers | Offer your skills, grow your reputation, and earn from what you do best. |
| 4 | Safe & Verified | Every worker is barangay-document verified — so you always know who you're hiring. |

**Navigation:** "Get Started" on slide 4 → Registration Screen. "Skip" → Login Screen.

---

### 0.3 Registration Screen — Step 1: Role Selection
**Purpose:** Let the user declare whether they're signing up to hire or to work.
**Layout Zones:** Header ("How will you use HanapBuhay?"), two large selectable cards stacked vertically, continue button at bottom.
**Key Elements:**
- Card 1: "I want to hire" (icon: search/briefcase) — becomes a **Client**
- Card 2: "I want to work" (icon: toolbox/hammer) — becomes a **Worker**
- Selected card shows a highlighted border/checkmark
- "Continue" button (disabled until a card is selected)

**Navigation:**
- Manual sign-up path: Continue → Registration Screen Step 2 (0.4)
- Google sign-up path: This screen appears after Google authentication completes → Continue → Complete Your Profile (0.5b)

---

### 0.4 Registration Screen — Step 2: Account Details
**Purpose:** Collect basic account info to create the profile.
**Layout Zones:** Scrollable form, header showing selected role as a small badge/chip at top (e.g., "Signing up as: Client" with a "change" link).
**Key Elements:**
- Full Name field
- Mobile Number field (collected for contact purposes — no verification required)
- Email Address field
- Password field (with show/hide toggle)
- Confirm Password field
- Terms & Privacy checkbox with inline links
- "Create Account" button
- "Already have an account? Log In" link at bottom

**States:** Inline validation errors under each field (e.g., "Passwords do not match").
**Navigation:** Create Account → Email Verification Screen (0.5).
---

### 0.5 Email Verification Screen (Manual Sign-Up Only)
**Purpose:** Confirm the user's email address before activating the account. This screen is skipped entirely for users who signed up via Google, since Google already verifies their email.
**Layout Zones:** Centered content — icon, instructional text, 6-digit OTP input boxes, resend link, confirm button.
**Key Elements:**
- "We sent a verification code to your email address [email]" text
- 6 individual OTP input boxes
- Countdown timer + "Resend Code" link (disabled until timer ends)
- "Verify" button

**Navigation:**
- If role = Client → Client Home Screen (registration complete)
- If role = Worker → Worker Home Screen, with a **verification banner** visible (see 0.9)

---

### 0.5b Complete Your Profile Screen (Google Sign-Up Path Only)
**Purpose:** Collect missing information after Google authentication, since Google only provides name, email, and profile photo. This screen appears only for users who signed up via Google Sign-In — manual sign-up users never see this screen.
**Layout Zones:** Centered form, profile photo at top, fields below, action button at bottom.
**Key Elements:**
- Profile photo (pre-filled from Google account, tappable to change)
- Full Name field (pre-filled from Google, editable)
- Email field (pre-filled from Google, non-editable — greyed out with a small "Provided by Google" label)
- Mobile Number field (empty, required — collected for contact/booking coordination purposes, no OTP verification)
- "Continue" button

**Navigation:** Continue → Client Home Screen (if role = Client) or Worker Home Screen with verification banner (if role = Worker). No OTP step.

---

### 0.6 Login Screen
**Purpose:** Authenticate a returning user.
**Layout Zones:** Logo/brand mark top, form fields middle, actions bottom.
**Key Elements:**
- "Continue with Google" button (placed above the manual form, full-width)
- Divider text "or"
- Email/Mobile Number field
- Password field (show/hide toggle)
- "Forgot Password?" link (right-aligned under password field)
- "Log In" button
- "Don't have an account? Sign Up" link at bottom

**Google Sign-In Flow:** Tapping "Continue with Google" → Google account picker → if existing account found, goes directly to role-appropriate Home Screen. If new Google user, goes to Role Selection (0.3) → Complete Your Profile (0.5b) → Home Screen.

**Navigation:** Log In → role-appropriate Home Screen. Forgot Password → 0.7.

---

### 0.7 Forgot Password Screen
**Purpose:** Recover account access.
**Layout Zones:** Instructional text top, single input field, action button.
**Key Elements:**
- Email/Mobile input field
- "Send Reset Code" button
**Navigation:** Send → OTP screen (reused from 0.5) → New Password screen (two fields: New Password, Confirm Password) → success confirmation → Login Screen.

---

### 0.8 Security Settings Screen (🔁 Shared, accessed via Profile tab)
**Purpose:** Manage password and 2FA.
**Layout Zones:** Simple stacked list of settings rows.
**Key Elements:**
- "Change Password" row → opens form (Current Password, New Password, Confirm New Password). For Google-linked accounts, this row is replaced with "Set a Password" (allows adding password login as a backup method).
- "Linked Accounts" row → shows which sign-in method is connected (e.g., "Google account linked: [email]")
- "Two-Factor Authentication" row with toggle switch
- "Login Activity" row → opens a list of recent logins (date, device, location) with a "Log out this device" action per entry

---

### 0.9 Verification Banner (🛠️ Worker Only — appears on Worker Home until verified)
**Purpose:** Prompt unverified workers to complete document submission without blocking app use.
**Layout Zones:** Dismissible banner/card pinned near the top of the Worker Home screen.
**Key Elements:** Warning-colored banner, icon, text ("Your account isn't verified yet — verified workers get more bookings"), "Complete Verification" button.
**Navigation:** Tapping banner → Verification Document Submission Screen (3.2).

---

## SECTION 1 — Client Journey (👤 Client Only)

### 1.1 Client Home / Discovery Screen
**Purpose:** Main landing screen for clients to discover workers.
**Layout Zones (top to bottom):**
- Top bar: greeting ("Hi, [Name]") + notification bell icon
- Search bar (tappable, opens Search & Filter screen)
- Horizontal scrollable chips: service categories (Electrical, Plumbing, Tutoring, Cleaning, etc.)
- "Top Rated Near You" horizontal scroll of worker cards
- "Recently Viewed" section (if applicable)
- Bottom navigation bar (Home, Bookings, Messages, Notifications, Profile)

**Key Elements — Worker Card (reused throughout app):** profile photo, name, service category, star rating, verification badge icon, distance/area text.
**Navigation:** Tapping a category chip → filtered Search Results. Tapping a worker card → Worker Profile View (1.3).

---

### 1.2 Worker Search & Filter Screen
**Purpose:** Let clients actively search/filter for workers.
**Layout Zones:** Search input pinned at top, filter button beside it, scrollable results list below.
**Key Elements:**
- Search input (auto-focused when opened)
- Filter icon → opens bottom sheet with: Service Category (multi-select), Distance/Area, Minimum Rating, Verification Status toggle ("Verified only")
- Results list using Worker Card component
- "No results found" empty state illustration + suggestion text

**Navigation:** Tap card → Worker Profile View.

---

### 1.3 Worker Profile View Screen
**Purpose:** Let the client review a specific worker before booking.
**Layout Zones (top to bottom):**
- Cover/header area: profile photo, name, verification badge + trust tier label (Verified / Trusted), star rating summary
- Tab row: "About" | "Portfolio" | "Reviews"
- About tab: bio, service categories offered, availability status indicator (Available/Busy/Offline)
- Portfolio tab: grid of past work photos
- Reviews tab: list of past client reviews with star ratings and comments
- Sticky bottom bar: "Book Now" button

**Navigation:** Book Now → Booking Request Screen (1.4).

---

### 1.4 Send Booking Request Screen
**Purpose:** Client submits a booking request to the chosen worker.
**Layout Zones:** Scrollable form.
**Key Elements:**
- Selected worker summary card (photo, name) at top
- Service category dropdown/selector (pre-filled from worker's offered categories)
- Date picker
- Time picker
- Service address field (with "use current location" option)
- Notes/description text area (optional, e.g., "leaking pipe under kitchen sink")
- "Send Request" button

**Navigation:** Send Request → confirmation modal ("Request sent! You'll be notified once the worker responds.") → Booking History Screen (1.5), new entry shown as "Pending."

---

### 1.5 Booking History Screen (Bottom Nav Tab: "Bookings")
**Purpose:** Client's overview of all bookings.
**Layout Zones:** Top segmented control/tabs: "Upcoming" | "Ongoing" | "Completed" | "Cancelled". Scrollable list below.
**Key Elements — Booking Card:** worker photo/name, service category, date/time, status badge (color-coded), tap to view details.
**Navigation:** Tap card → Booking Detail Screen (1.6).

---

### 1.6 Booking Detail Screen
**Purpose:** Full view of a specific booking, adapts based on status.
**Layout Zones:**
- Worker summary card (photo, name, "Message" icon button)
- Booking details block (service, date/time, address, notes)
- Status timeline/stepper (Requested → Accepted → En Route → In Progress → Completed)
- Conditional action area (see below)

**Conditional Elements by Status:**
- **Pending:** "Cancel Request" button
- **Accepted, not yet en route:** Status text only
- **En Route:** Embedded map showing worker's live location + ETA (see 1.7)
- **In Progress:** "Confirm Job Completed" button (appears once worker marks job as started)
- **Completed:** "Rate & Review" button (if not yet reviewed) or a summary of the submitted review
- **Any active status:** "File a Report" link (small, secondary, bottom of screen)

---

### 1.7 Live Worker Tracking View (embedded within 1.6, "En Route" status)
**Purpose:** Let the client watch the worker's location update in real time.
**Layout Zones:** Full-width map component with a bottom card overlay.
**Key Elements:** Map with worker's live location pin and destination pin, bottom card showing worker photo/name, ETA text, "Message" and "Call" icon buttons.
**Note for Designer:** This view only appears while booking status = "En Route." It should feel similar to a ride-hailing app's driver-tracking screen.

---

### 1.8 Rate & Review Screen
**Purpose:** Client rates the worker after job completion.
**Layout Zones:** Centered content.
**Key Elements:** Worker photo/name, 5-star rating selector (large, tappable), text area for written review, "Submit Review" button.
**Navigation:** Submit → returns to Booking Detail Screen, now showing the submitted review.

---

### 1.9 File a Report Screen
**Purpose:** Client reports an issue tied to a specific booking.
**Layout Zones:** Scrollable form.
**Key Elements:**
- Booking summary card (auto-filled, non-editable)
- Reason dropdown (No-show, Unsatisfactory work, Misconduct, Other)
- Description text area
- "Attach Photo Evidence" upload button (multiple image support, shows thumbnail previews)
- "Submit Report" button

**Navigation:** Submit → confirmation → Report Status Screen (1.10).

---

### 1.10 Report Status Screen
**Purpose:** Client tracks the status of reports they've filed.
**Layout Zones:** List view.
**Key Elements — Report Card:** short description, date filed, status badge (Under Review / Resolved), tap to expand for admin remarks/resolution notes.

---

## SECTION 2 — Worker Journey (🛠️ Worker Only)

### 2.1 Worker Home / Dashboard Screen
**Purpose:** Main landing screen for workers — manage incoming work and status.
**Layout Zones (top to bottom):**
- Top bar: greeting + notification bell
- Verification banner (0.9), if unverified
- Availability toggle card: large switch — "Available" / "Busy" / "Offline"
- "Incoming Requests" section — list of pending booking requests awaiting Accept/Decline
- Quick stats row: Trust Tier badge, average rating, completed jobs count
- Bottom navigation bar (Home, Jobs, Messages, Notifications, Profile)

**Key Elements — Incoming Request Card:** client name/photo, service category, requested date/time, address (approximate), "Accept" and "Decline" buttons inline.
**Navigation:** Accept → Booking Schedule Screen (2.5), new entry added as "Upcoming."

---

### 2.2 Verification Document Submission Screen
**Purpose:** Worker submits ID and barangay certificate for review.
**Layout Zones:** Scrollable form/checklist style.
**Key Elements:**
- Step indicator (e.g., "Step 1 of 3")
- Upload block for Valid Government ID (camera/gallery picker, shows thumbnail once uploaded)
- Upload block for Barangay Certificate/Clearance
- Upload block for Selfie holding ID
- "Submit for Review" button (disabled until all 3 uploaded)

**States:** After submission, replace with a status card: "Your documents are under review. This usually takes 1–3 business days."

---

### 2.3 Verification Status Screen
**Purpose:** Let worker check current verification standing anytime.
**Layout Zones:** Centered status card.
**Key Elements:**
- Status icon + label (Pending / Approved / Rejected)
- If Rejected: reason/remarks text + "Resubmit Documents" button (→ back to 2.2, pre-filled)
- If Approved: badge preview showing how it appears to clients + current Trust Tier (Verified / Trusted / Flagged)

---

### 2.4 Portfolio & Skills Management Screen
**Purpose:** Worker manages their public profile content.
**Layout Zones:** Scrollable sections.
**Key Elements:**
- "Service Categories" section — multi-select chips (Electrical, Plumbing, Tutoring, etc.) with "Edit" action
- "Portfolio Photos" section — grid with "+ Add Photo" tile, tap existing photo to remove
- "Bio" section — editable text area

---

### 2.5 Booking Schedule / History Screen (Bottom Nav Tab: "Jobs")
**Purpose:** Worker's overview of accepted bookings.
**Layout Zones:** Same segmented tabs pattern as Client's Booking History (Upcoming / Ongoing / Completed / Cancelled).
**Key Elements — Job Card:** client name/photo, service category, date/time, status badge.
**Navigation:** Tap card → Job Detail Screen (2.6).

---

### 2.6 Job Detail Screen
**Purpose:** Full view of a specific job, with worker-side actions.
**Layout Zones:** Mirrors Client's Booking Detail (1.6), but action buttons differ:
- **Accepted, not yet traveling:** "Start Traveling" button → begins live location sharing, status becomes "En Route"
- **En Route:** Map view showing worker's own shared location + "Arrived / Start Job" button
- **In Progress:** "Mark Job as Completed" button
- **Completed:** "Rate Client" button (if not yet rated)
- **Any active status:** "File a Report" link

---

### 2.7 Rate Client Screen
**Purpose:** Worker rates the client after job completion.
**Layout Zones/Elements:** Identical pattern to Client's Rate & Review screen (1.8), but rating a client instead.

---

### 2.8 File a Report / Report Status Screens (Worker Version)
**Purpose & Layout:** Identical structure to Client's 1.9 and 1.10, adjusted for reporting a client (reasons: non-payment, unsafe environment, abusive behavior, etc.).

---

## SECTION 3 — Shared Utility Screens (🔁 Shared)

### 3.1 In-App Messaging — Chat Inbox (Bottom Nav Tab: "Messages")
**Purpose:** List of all conversations.
**Layout Zones:** Scrollable list.
**Key Elements — Conversation Row:** other party's photo/name, last message preview, timestamp, unread indicator dot, linked booking reference tag (small text, e.g., "Re: Booking #HB-1042").
**Navigation:** Tap row → Chat Thread Screen (3.2).

---

### 3.2 Chat Thread Screen
**Purpose:** Conversation tied to a specific booking.
**Layout Zones:** Header (other party's name/photo + linked booking reference), scrollable message bubbles, bottom input bar with text field + attach photo icon + send button.

---

### 3.3 Notification Center (Bottom Nav Tab: "Notifications")
**Purpose:** Centralized list of all system notifications.
**Layout Zones:** Scrollable list, optionally grouped by "Today" / "Earlier."
**Key Elements — Notification Row:** icon (type-specific), message text, timestamp, unread indicator. Tapping routes to the relevant screen (e.g., booking notification → Booking Detail).

---

### 3.4 Profile Tab — Main Screen (Bottom Nav Tab: "Profile")
**Purpose:** Entry point to account-related screens.
**Layout Zones:** Profile summary card at top (photo, name, role badge), followed by a stacked settings list.
**Key Elements — List Rows:** Edit Profile, Security Settings (0.8), Notification Preferences, Help/FAQ, Log Out (bottom, distinct styling).
**Worker-only additions:** Verification Status (2.3), Portfolio & Skills (2.4), Trust Tier display.

---

### 3.5 Edit Profile Screen
**Purpose:** Update personal info and photo.
**Layout Zones:** Centered profile photo (tap to change) at top, form fields below.
**Key Elements:** Profile photo upload, Full Name, Contact Number, Email, "Save Changes" button.

---

### 3.6 Notification Preferences Screen
**Purpose:** Control which notifications the user receives and how.
**Layout Zones:** Simple stacked list with toggle switches per category (Booking Updates, Messages, Promotions/Announcements) and per channel (Push, Email).

---

### 3.7 Help / FAQ Screen
**Purpose:** Self-serve support.
**Layout Zones:** Search bar at top, expandable accordion list of FAQ items grouped by topic (Account, Bookings, Verification, Payments/Fees if applicable, Safety).
**Key Elements:** Accordion rows (tap to expand answer), "Still need help? Contact Support" button at the bottom → opens a simple contact form or email link.

---

## Summary Table — Screen Count by Section

| Section | Screen Count |
|---|---|
| Onboarding & Authentication (Shared) | 9 |
| Client Journey | 10 |
| Worker Journey | 8 |
| Shared Utility Screens | 7 |
| **Total unique screens to wireframe** | **34** |

---

## Notes for the UI/UX Designer
    
1. **Component reuse:** Build the *Worker Card*, *Booking/Job Card*, *Status Badge*, and *Notification Row* as reusable Figma components early — they repeat across many screens.
2. **Design system first:** Establish color palette (based on the HanapBuhay brand), typography scale, spacing units, and button/input styles as Figma styles/variables before wireframing individual screens, so all 34 screens stay visually consistent.
3. **Wireframe fidelity:** These descriptions are written for **low-to-mid fidelity wireframes** first (grayscale, boxes/placeholders, no final branding) — full high-fidelity visual design should come after the wireframes are reviewed and approved by the team and instructor.
4. **Status badge colors** should be consistent system-wide: e.g., Pending = amber/yellow, Accepted/Verified/Completed = green, Rejected/Flagged/Cancelled = red, En Route/Info = blue.
5. **Empty states matter:** Screens like Booking History, Notifications, and Search Results should each have a simple empty-state illustration + short message wireframed, not left blank.
