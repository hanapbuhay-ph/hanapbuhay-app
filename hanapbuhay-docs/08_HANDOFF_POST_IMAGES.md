# HanapBuhay Handoff: Worker Post Images

**Date:** September 4, 2026  
**Project:** HanapBuhay Flutter app  
**Purpose:** Continue implementation of worker post images and client post detail flow

## Handoff Prompt

You are continuing work on the HanapBuhay Flutter project at:

`c:\Users\iza\AndroidStudioProjects\hanapbuhayApp`

The product requirement is:

- Workers can attach multiple pictures to a job post.
- The first picture appears as the client home-feed card preview.
- A multiple-picture count appears on the feed card when applicable.
- Tapping post content opens a full post detail screen.
- The detail screen displays all post images in a vertical scrolling list.
- Tapping the worker identity still opens the worker profile.
- The detail screen has a Book button that preserves the selected post.

Read these documents before making further changes:

- `hanapbuhay-docs/00_PROJECT_OVERVIEW.md`
- `hanapbuhay-docs/02_APP_FUNCTIONALITIES.md`
- `hanapbuhay-docs/04_APP_WORKER_WIREFRAME.md`
- `hanapbuhay-docs/05_APP_CLIENT_WIREFRAME.md`
- `hanapbuhay-docs/06_DATABASE_SCHEMA.md`
- `hanapbuhay-docs/07_API_ENDPOINTS.md`

## Completed Work

### Documentation

The six documents above were updated in September 2026 to describe:

- Up to 10 ordered images per post.
- First image as feed preview.
- Image count on feed cards.
- Dedicated client post-detail screen.
- Vertical image list and full-screen image behavior.
- `job_post_images` database table.
- Worker image upload, delete, and reorder endpoints.
- Client post-detail endpoint.

### Flutter frontend

The following frontend changes are already implemented:

- `lib/data/models/job_post_model.dart`
  - Added `List<String> imageUrls` with a default empty list.
  - Updated `copyWith` to preserve/update image URLs.

- `lib/core/routing/app_router.dart`
  - Added route prefix `/client/posts`.
  - `/client/posts/{postId}` opens `JobPostDetailScreen`.
  - Booking routes accept an optional `postId` query parameter.

- `lib/screens/section_1_client/job_post_detail_screen.dart`
  - New screen for full post details.
  - Loads a post from the current `WorkerProvider` data.
  - Displays worker identity, category, location, title, description, price, availability, and all `imageUrls` in a vertical `ListView`.
  - Displays a Book button.
  - Tapping the worker header opens the worker profile.

- `lib/screens/section_1_client/client_home_screen.dart`
  - Post-card tap opens `/client/posts/{postId}`.
  - Worker avatar/name taps still open the worker profile.
  - First post image is shown on the card.
  - Multiple-image count is shown when there is more than one image.

- `lib/screens/section_2_worker/create_job_post_screen.dart`
  - Added `image_picker` multi-selection.
  - Added local image previews.
  - Limits selection to 10 images.
  - Stores selected paths in `JobPost.imageUrls` for the current mock flow.

- `lib/screens/section_1_client/send_booking_request_screen.dart`
  - Added optional `postId`.
  - Uses the selected post to preselect the booking category when available.

- `lib/data/repositories/mock/mock_worker_repository.dart`
  - Added sample image URLs to the first mock job post so the feed/detail UI can be exercised.

## Validation Already Passed

The focused analyzer passed with no issues:

```text
flutter analyze lib/screens/section_1_client/client_home_screen.dart lib/screens/section_1_client/job_post_detail_screen.dart lib/screens/section_2_worker/create_job_post_screen.dart lib/core/routing/app_router.dart lib/data/models/job_post_model.dart lib/data/repositories/mock/mock_worker_repository.dart lib/screens/section_1_client/send_booking_request_screen.dart

No issues found!
```

`git diff --check` also passed.

## Important Current Limitations

The current Flutter project is using mock repositories for worker/post data. The image picker currently stores local selected paths in the mock `JobPost` object; it does not yet upload files to a real backend.

The booking provider currently creates bookings using the existing worker/category fields. The `postId` is passed through the route and used for category preselection, but the booking repository/provider contract may still need to be extended to send `job_post_id` to the backend.

The detail screen currently locates posts by loading workers and searching their in-memory `jobPosts`. It should be changed to call the real `GET /api/posts/{postId}` endpoint once the API repository is available.

Do not remove the existing worker-profile route or the existing booking flow while integrating the API.

## Next Required Work

### Backend integration

Confirm that the backend implements the contracts documented in `07_API_ENDPOINTS.md`:

```text
GET /api/posts/{postId}
POST /api/worker/posts/{postId}/images
DELETE /api/worker/posts/{postId}/images/{imageId}
PUT /api/worker/posts/{postId}/images/order
```

The database should include `job_post_images` with:

- `job_post_id`
- `image_path`
- nullable `thumbnail_path`
- `display_order`
- timestamps

Verify authorization, file validation, 10-image limit, image compression, thumbnails, ordered responses, and cleanup of stored files.

### Flutter API integration

1. Inspect the current real API client/repository implementation.
2. Add image metadata to the API `JobPost` parsing model.
3. Add multipart upload support using the existing HTTP/auth conventions.
4. Add delete and reorder methods.
5. Add a post-detail repository method for `GET /api/posts/{postId}`.
6. Change `JobPostDetailScreen` to load the post through that method.
7. Change the client feed parser to use thumbnail URLs for card previews and full URLs for detail images.
8. Extend the booking request model/repository to send `job_post_id` when booking from a post detail screen.
9. Update create/edit post flows to upload and manage images after the post is created.
10. Add loading, retry, upload-progress, validation-error, empty-image, inactive-post, and not-found states.

### Worker edit flow

The create screen currently supports selection. The edit screen still needs visible media management:

- Show existing images in display order.
- Add new images.
- Remove images.
- Reorder images.
- Persist changes through the image endpoints.
- Keep post text updates independent from media updates.

### Testing

Add or update tests for:

- Post model image parsing.
- Feed image preview parsing.
- Post detail loading.
- Worker upload/delete/reorder actions.
- 10-image limit.
- Invalid file errors.
- Non-owner authorization errors.
- Booking requests containing `job_post_id`.
- Inactive/deleted post behavior.

Run at minimum:

```text
flutter analyze
flutter test
```

## Design and Routing Decisions

- A post tap opens the post detail screen.
- A worker avatar/name tap opens the worker profile.
- Post media belongs to a job post, not the worker profile portfolio.
- The first image is the feed preview.
- Images are rendered in saved `display_order`.
- The post detail booking button remains disabled for unavailable/inactive posts.
- Existing public APIs and the one-post-per-category-per-worker rule must remain compatible.

## Suggested First Action

Before editing, inspect the current API client, worker repository implementation, booking repository, and edit-post screen. Then implement the real API integration in small slices, running a focused analyzer/test command after each slice.
