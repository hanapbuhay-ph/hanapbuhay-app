# Testing Guide: Session 7 ï¿½ Section A (Shared Features)

**Last Updated:** 2026-09-08  
**Testing Target:** Profile Management, Notifications, In-App Messaging, FCM Token Registration

---

## Prerequisites

### 1. Backend Setup
```bash
# Navigate to backend
cd C:\laragon\www\hanapbuhay-api

# Start Laravel server
php artisan serve
# Should start on http://127.0.0.1:8000
```

**Backend Requirements:**
- Database must be migrated (SQLite or MySQL configured in `.env`)
- At least 2 test users exist (1 client, 1 worker)
- At least 1 booking exists between the two users (for messaging)
- Sample notifications should exist for test user

### 2. Flutter App Setup
```bash
# Navigate to Flutter project
cd C:\Users\iza\AndroidStudioProjects\hanapbuhayApp

# Verify base URL is set correctly
# Open: lib/config/app_constants.dart
# Should contain: static const String baseUrl = ''http://10.0.2.2:8000/api'';
# (10.0.2.2 is the emulator''s localhost alias)

# Run the app
flutter run
```

### 3. Test Accounts
You need credentials for at least 2 users to test messaging:

**User 1 (Client):**
- Email: `client@test.com` (or whatever exists in your DB)
- Password: from your seeder

**User 2 (Worker):**
- Email: `worker@test.com`
- Password: from your seeder

**To check existing users in backend:**
```bash
cd C:\laragon\www\hanapbuhay-api
php artisan tinker
>>> User::all([''id'', ''name'', ''email'', ''role'']);
```

---

## Test 1: Profile Management (A2)

### What Was Implemented
- **GET /api/user** ï¿½ fetch authenticated user''s profile
- **POST /api/user/profile** ï¿½ update profile fields

### Test Steps

#### 1.1 View Current Profile
1. Login with any test account
2. Navigate to **Profile** tab (bottom navigation)
3. **Expected:** Profile screen loads showing user''s name, email, mobile, barangay, photo, role

#### 1.2 Edit Profile
1. On Profile screen, tap **Edit Profile** button
2. **Expected:** Form shows Profile photo, Full Name, Mobile Number, Barangay dropdown (pre-selected, 20 options), Email (greyed out, non-editable)
3. Change the Barangay dropdown; modify name/mobile
4. Tap **Save**
5. **Expected:** Loading indicator, success message, data refreshes; barangay change persisted
#### 1.3 Error Handling
1. Edit profile and enter invalid mobile number (e.g., "123")
2. Tap Save
3. **Expected:** 422 validation error displays inline

#### 1.4 Backend Verification
```bash
php artisan tinker
>>> User::find(1)->mobile_number;  // Should show updated value
```

**? Pass:** Profile fetches, updates save, validation works

---

## Test 2: Notifications (A4)

### What Was Implemented
- **GET /api/notifications** ï¿½ fetch notifications
- **POST /api/notifications/{id}/read** ï¿½ mark single as read
- **POST /api/notifications/read-all** ï¿½ mark all as read
- Unread count badge on bottom nav

### Test Steps

#### 2.1 View Notifications
1. Login as user with notifications
2. Check bottom nav for unread badge
3. Tap **Notifications** tab
4. **Expected:** List loads, shows title/body/timestamp, sorted newest first

#### 2.2 Mark Single as Read
1. Tap any unread notification
2. **Expected:** Marked as read, badge count decreases

#### 2.3 Mark All as Read
1. Tap **Mark All as Read** button
2. **Expected:** All marked read, badge clears

#### 2.4 Backend Verification
```bash
php artisan tinker
>>> Notification::where(''user_id'', 1)->where(''is_read'', false)->count();  // Should be 0
```

**? Pass:** Notifications load, badge updates, mark-as-read works

---

## Test 3: In-App Messaging (A3)

### What Was Implemented
- **GET /api/messages** ï¿½ chat inbox
- **GET /api/messages/{bookingId}** ï¿½ message thread
- **POST /api/messages/{bookingId}** ï¿½ send message
- Auto-mark-as-read

### Test Steps

#### 3.1 View Chat Inbox
1. Login as User 1 (Client)
2. Tap **Messages** tab
3. **Expected:** Conversations list shows other party name, booking code, last message, timestamp, unread badge

#### 3.2 Open Chat Thread
1. Tap any conversation
2. **Expected:** Thread opens, messages load (newest at bottom), shows sender/text/timestamp

#### 3.3 Send a Message
1. Type: "Test message from Session 7"
2. Tap Send
3. **Expected:** `POST /api/messages/{bookingId}` sends with field `message` (NOT `content`), appears in thread

#### 3.4 Critical Fix Verification: `message` vs `content`
**This was the #1 critical fix from backend verification.**

**Backend expects** (MessageController.php line 140):
```php
$validated = $request->validate([
    ''message'' => ''required|string|max:1000'',  // ? NOT ''content''
]);
```

**Flutter sends** (api_chat_repository.dart line 71):
```dart
fields[''message''] = text;  // ? Correct
```

**Test:** Send message and verify 201 Created (not 422 validation error)

#### 3.5 Backend Verification
```bash
php artisan tinker
>>> Message::latest()->first()->content;  // Should show your message text
```

**? Pass:** Inbox loads, thread opens, messages send with field `message`, auto-mark-as-read works

---

## Test 4: FCM Token Registration (A5)

### What Was Implemented
- **POST /api/user/fcm-token** ï¿½ register FCM device token
- Sends `fcm_token` + `device_type` (`android`)

### Test Steps

#### 4.1 Automatic Registration on Login
**Note:** Firebase FCM is not yet fully configured (commented out in `fcm_service.dart`), so this test is **partial**.

1. Login as any user
2. Check Flutter console
3. **Expected:** Console log: `[FcmService] initializeAndRegister: Firebase FCM not yet configured`

#### 4.2 Critical Fix Verification: `device_type` Required
**This was the #2 critical fix from backend verification.**

**Backend expects** (RegisterDeviceRequest.php):
```php
return [
    ''fcm_token'' => ''required|string|max:255'',
    ''device_type'' => ''required|in:android,ios,web'',  // ? required
];
```

**Flutter sends** (fcm_service.dart line 22):
```dart
body: {
  ''fcm_token'': fcmToken,
  ''device_type'': ''android'',  // ? now included
},
```

**When Firebase is configured (future):** Login ? check backend receives both fields ? 200 OK (not 422)

#### 4.3 Backend Verification
```bash
php artisan tinker
>>> DB::table(''fcm_tokens'')->where(''user_id'', 1)->first();
# Should show: fcm_token, device_type = ''android'', user_id, created_at
```

**? Pass:** Service exists, `device_type` included, backend accepts it when called

---

## Test 5: Error Handling

### 5.1 Network Offline
1. Turn off WiFi / Mobile Data on device/emulator
2. Try to load notifications or send a message
3. **Expected:** User-friendly SnackBar: "Network error", loading state ends

### 5.2 Expired Token (401 Unauthorized)
1. Login successfully
2. In backend, delete user''s token:
   ```bash
   php artisan tinker
   >>> DB::table(''personal_access_tokens'')->where(''tokenable_id'', 1)->delete();
   ```
3. In Flutter app, try to load notifications
4. **Expected:** ApiClient detects 401, clears token, redirects to Login

### 5.3 Backend Down (500 Error)
1. Stop Laravel server
2. Try any API call in Flutter
3. **Expected:** SnackBar: "Something went wrong. Please try again."

---

## Critical Fixes Re-Test

### Fix #1: Message Field Name (CRITICAL)
**Issue:** Docs said `content`, backend expects `message`

**Test:**
1. Send a message in chat
2. Check backend logs ? should see 201 Created (not 422)
3. Verify database:
   ```bash
   php artisan tinker
   >>> Message::latest()->first()->content;  // Should show your text
   ```

**? Pass:** Message sends successfully (no 422 validation error)

---

### Fix #2: FCM device_type Required (CRITICAL)
**Issue:** Backend requires `device_type` field

**Test:**
1. When Firebase is configured, login and check backend logs
2. Should see: `{ "fcm_token": "...", "device_type": "android" }`
3. Backend returns 200 OK (not 422)

**? Pass:** Token registration includes `device_type`

---

### Fix #3: FCM DELETE Endpoint Doesn''t Exist (CRITICAL)
**Issue:** App tried to call `DELETE /api/user/fcm-token` (doesn''t exist)

**Test:**
1. Logout from app
2. Check Flutter console
3. Should see: `[FcmService] deleteToken: No DELETE endpoint in backend`
4. No error thrown

**? Pass:** Logout completes without trying to DELETE token

---

## Expected Outcomes Summary

| Feature | Endpoint | Expected Behavior |
|---------|----------|-------------------|
| **Profile View** | GET /api/user | Loads user data, displays in Profile screen |
| **Profile Update** | POST /api/user/profile | Saves changes to DB, shows success |
| **Notifications List** | GET /api/notifications | Loads paginated list, shows unread badge |
| **Mark as Read** | POST /api/notifications/{id}/read | Updates is_read, decreases badge |
| **Mark All Read** | POST /api/notifications/read-all | Sets all is_read = true, clears badge |
| **Chat Inbox** | GET /api/messages | Lists conversations, shows unread count |
| **Chat Thread** | GET /api/messages/{bookingId} | Loads messages, auto-marks as read |
| **Send Message** | POST /api/messages/{bookingId} | Sends with field `message` (not `content`), 201 Created |
| **FCM Registration** | POST /api/user/fcm-token | Includes `device_type: android`, succeeds |

---

## Common Issues & Troubleshooting

### Issue: "Connection refused" / "Network error"
**Cause:** Backend not running or wrong base URL
**Fix:**
1. Check Laravel server: `php artisan serve`
2. Verify base URL in `lib/config/app_constants.dart`:
   - Emulator: `http://10.0.2.2:8000/api`
   - Physical device: `http://[your-local-ip]:8000/api`

### Issue: "401 Unauthorized" on every request
**Cause:** Token not saved or expired
**Fix:** Logout and login again

### Issue: Messages show 422 "The content field is required"
**Cause:** Old code using `content` instead of `message`
**Fix:** Verify `api_chat_repository.dart` line 71 uses `fields[''message'']`

### Issue: Notifications don''t show unread count
**Cause:** Notifications table empty
**Fix:**
```bash
php artisan tinker
>>> Notification::factory()->create([''user_id'' => 1, ''is_read'' => false]);
```

### Issue: Chat inbox is empty
**Cause:** No bookings exist
**Fix:**
```bash
php artisan tinker
>>> Booking::factory()->create([''client_id'' => 1, ''worker_id'' => 2, ''status'' => ''accepted'']);
```

---

## Testing Checklist

### Profile Management (A2)
- [ ] Profile loads with correct user data
- [ ] Edit profile saves changes
- [ ] Validation errors display inline
- [ ] Backend database reflects updates

### Notifications (A4)
- [ ] Notifications list loads
- [ ] Unread badge shows correct count
- [ ] Mark single as read works
- [ ] Mark all as read clears badge
- [ ] Pagination loads older notifications

### In-App Messaging (A3)
- [ ] Chat inbox loads conversations
- [ ] Each conversation shows booking code, last message, unread count
- [ ] Chat thread loads messages
- [ ] Send message succeeds with field `message` (not `content`)
- [ ] Auto-mark-as-read clears unread count
- [ ] Messages appear for both parties

### FCM Token Registration (A5)
- [ ] Service file exists and compiles
- [ ] `device_type: android` included in request
- [ ] Placeholder logs show when Firebase not configured
- [ ] No error on logout (DELETE not called)

### Error Handling
- [ ] Network error shows user-friendly message
- [ ] 401 redirects to Login
- [ ] 500 shows generic error message
- [ ] No raw exceptions crash the app

### Backend Verification Fixes
- [ ] Message field uses `message` (not `content`) ? CRITICAL
- [ ] FCM includes `device_type` field ? CRITICAL
- [ ] FCM DELETE not called on logout ? CRITICAL

---

## Completion Criteria

**Session 7 is fully validated when:**
1. ? All 4 features (Profile, Notifications, Messaging, FCM) work end-to-end
2. ? All 3 critical fixes from backend verification are confirmed working
3. ? Error handling gracefully handles network/auth/server errors
4. ? No crashes, no raw exceptions shown to user
5. ? Backend database reflects all changes

---

## Next Steps After Testing

**If all tests pass:**
- Mark Session 7 as ? Complete
- Move to Session 8: Section B (Client Features ï¿½ Home Feed, Worker Discovery, Bookings)

**If tests fail:**
- Document the failing test scenario
- Check backend logs for error details
- Check Flutter console for exception stack traces

---

**References:**
- `BACKEND_VERIFICATION_REPORT.md` ï¿½ detailed backend code references
- `HANDOFF.md` Session 7 ï¿½ implementation details
- `hanapbuhay-docs/07_API_ENDPOINTS.md` ï¿½ endpoint contracts
