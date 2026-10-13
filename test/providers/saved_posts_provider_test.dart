import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/models/job_post_model.dart';
import 'package:hanapbuhayapp/data/models/worker_model.dart';
import 'package:hanapbuhayapp/providers/saved_posts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and restores listings for the same client account', () async {
    final provider = SavedPostsProvider();
    final listing = _listing();

    await provider.toggleSavedPost(userId: 'client-1', listing: listing);

    expect(provider.isSaved(listing.post.id), isTrue);
    expect(provider.savedPosts.single.post.title, listing.post.title);

    final restoredProvider = SavedPostsProvider();
    await restoredProvider.loadForUser('client-1');

    expect(restoredProvider.isSaved(listing.post.id), isTrue);
    expect(restoredProvider.savedPosts.single.worker.name, listing.worker.name);
    expect(
      restoredProvider.savedPosts.single.post.images.single.imageUrl,
      listing.post.images.single.imageUrl,
    );
  });

  test('keeps saved services separate for different client accounts', () async {
    final provider = SavedPostsProvider();
    final listing = _listing();

    await provider.toggleSavedPost(userId: 'client-1', listing: listing);
    await provider.loadForUser('client-2');

    expect(provider.savedPosts, isEmpty);
    expect(provider.isSaved(listing.post.id), isFalse);

    await provider.loadForUser('client-1');
    expect(provider.isSaved(listing.post.id), isTrue);
  });

  test('unsaving removes the listing from persistent storage', () async {
    final provider = SavedPostsProvider();
    final listing = _listing();

    await provider.toggleSavedPost(userId: 'client-1', listing: listing);
    await provider.toggleSavedPost(userId: 'client-1', listing: listing);

    final restoredProvider = SavedPostsProvider();
    await restoredProvider.loadForUser('client-1');
    expect(restoredProvider.savedPosts, isEmpty);
  });
}

JobPostListing _listing() {
  return JobPostListing(
    worker: Worker(
      id: 'worker-profile-1',
      userId: 'worker-user-1',
      name: 'Maria Santos',
      avatarUrl: 'https://example.com/avatar.jpg',
      specialty: 'Home cleaning',
      rating: 4.8,
      reviewCount: 12,
      barangay: 'Poblacion',
      hourlyRate: 350,
      isVerified: true,
      tags: const ['Cleaning'],
      distance: '1 km away',
      bio: 'Experienced cleaner',
    ),
    post: JobPost(
      id: 'post-1',
      workerId: 'worker-profile-1',
      category: 'Cleaning',
      title: 'Home cleaning service',
      description: 'Reliable home cleaning.',
      startingRate: 350,
      rateType: RateType.perSession,
      images: const [
        JobPostImage(
          id: 'image-1',
          imageUrl: 'https://example.com/service.jpg',
        ),
      ],
    ),
  );
}
