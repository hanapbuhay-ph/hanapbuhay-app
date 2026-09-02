# API Integration & Future-Proofing Analysis

I have audited the current Flutter frontend implementation against the `07_API_ENDPOINTS.md` specification. Below are the key findings and required structural adjustments to ensure the app is "Backend-Ready."

## 1. Data Model Alignment

### User & Authentication
- **Gap:** The API returns a nested `worker_profile` object inside the `user` object for worker accounts. Currently, our `AuthProvider` stores flat strings in SharedPreferences.
- **Future-Proofing:** Create a dedicated `UserModel` that can parse the full recursive structure from `/api/user`.
- **Field Mismatches:**
  - API uses `mobile_number`, frontend uses `userMobile`.
  - API uses `is_google_account` (bool), frontend uses `signInMethod` (String).

### Worker & Job Posts
- **Gap:** The API uses integer IDs for categories (`service_category_id`) and barangays (`barangay_id`). The frontend models currently use `String` IDs.
- **Structural Difference:** The Home Feed (`/api/feed`) returns a list of **Posts**, each containing a nested `worker` object. Our `JobPostListing` view model is a good bridge, but needs to match specific keys:
  - `rate_amount` vs `startingRate`
  - `rate_display` (server-generated string like "₱300.00/day")
  - `distance_label` (server-generated distance based on barangay centers)

### Bookings
- **Gap:** The API `Booking` object dynamically provides an `other_party` object (which is either the Client or Worker depending on who is logged in).
- **Tracking:** The API provides `worker_current_location` and `client_current_location` as dedicated objects with timestamps.

## 2. Parameter & Type Audit

| Feature | Frontend State | API Requirement | Impact |
| :--- | :--- | :--- | :--- |
| **ID Types** | `String` | `int` | High (Type errors during JSON decoding) |
| **Enum Values** | `RateType.perHour` | `hourly`, `daily`, etc. | Medium (Mapping needed in `toJson`) |
| **Verification** | 3 documents | 4 documents (Skill Cert optional) | Low (UI addition) |
| **Report Reasons**| PascalCase | snake_case (e.g. `no_show`) | Medium (Mapping needed) |

## 3. Recommended Structural Changes

### A. ID Type Transition
Move from `String id` to `dynamic id` or `int id` in models to support Laravel's auto-incrementing integers while maintaining mock compatibility.

### B. "FromJSON" Factory Patterns
Implement robust `factory Model.fromJson(Map<String, dynamic> json)` patterns that handle:
- Snake_case to camelCase conversion.
- String-to-Double parsing (Laravel often returns numbers as strings in JSON).
- Nested object instantiation (e.g., `user.barangay.name`).

### C. Repository Interface Refinement
Update repository methods to accept IDs matching the API:
- `getWorkerById(int id)`
- `createBooking(int workerProfileId, int categoryId, ...)`

## 4. Immediate Compliance Checklist (Next Tasks)

1. [ ] **Add `skill_certificate` field** to `VerificationDocumentScreen` (W5).
2. [ ] **Update `Booking` model** to include `otherPartyName`, `otherPartyAvatar`, and `bookingCode` as stored fields from JSON.
3. [ ] **Align `JobPost` fields** with snake_case keys (`rate_type`, `rate_amount`).
4. [ ] **Implement `UserModel`** to replace flat SharedPreferences storage in `AuthProvider`.

---

**Conclusion:** The frontend architecture is functionally sound, but the data serialization layer needs a "Snake-to-Camel" bridge and an ID type migration to be truly future-proof for the Laravel 13 integration.
