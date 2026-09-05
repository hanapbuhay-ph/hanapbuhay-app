import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_worker_repository.dart';

void main() {
  late MockWorkerRepository repository;

  setUp(() {
    repository = MockWorkerRepository();
  });

  group('WorkerRepository Post Detail Tests', () {
    test('getJobPostDetail retrieves existing post and associated worker', () async {
      final listing = await repository.getJobPostDetail('jp1');

      expect(listing, isNotNull);
      expect(listing!.post.id, 'jp1');
      expect(listing.post.title, 'Expert Pipe & Leak Repair');
      expect(listing.worker.id, 'w1');
      expect(listing.post.images.length, 3);
      expect(listing.post.images.first.displayOrder, 0);
    });

    test('getJobPostDetail returns null for non-existent post', () async {
      final listing = await repository.getJobPostDetail('non_existent_id');

      expect(listing, isNull);
    });
  });

  group('WorkerRepository Post Image Management Tests', () {
    test('uploadPostImages adds new images preserving order', () async {
      final initialListing = await repository.getJobPostDetail('jp1');
      final initialCount = initialListing!.post.images.length; // 3

      final uploaded = await repository.uploadPostImages('jp1', [
        'local_path_1.png',
        'local_path_2.png',
      ]);

      expect(uploaded.length, initialCount + 2);
      expect(uploaded[initialCount].displayOrder, initialCount);
      expect(uploaded[initialCount + 1].displayOrder, initialCount + 1);

      final updatedListing = await repository.getJobPostDetail('jp1');
      expect(updatedListing!.post.images.length, initialCount + 2);
    });

    test('uploadPostImages enforces 10-image limit', () async {
      // jp1 already has 3 images. Try uploading 8 more (total 11).
      final eightImages = List.generate(8, (i) => 'img_$i.png');

      // The repository takes remaining slots up to 10
      final uploaded = await repository.uploadPostImages('jp1', eightImages);
      expect(uploaded.length, 10);

      // Now it has 10 images. Attempting to add one more throws Exception
      expect(
        () => repository.uploadPostImages('jp1', ['one_more.png']),
        throwsException,
      );
    });

    test('deletePostImage removes image and renumbers display orders', () async {
      final initialListing = await repository.getJobPostDetail('jp1');
      final secondImageId = initialListing!.post.images[1].id;

      final result = await repository.deletePostImage('jp1', secondImageId);
      expect(result.success, true);

      final updatedListing = await repository.getJobPostDetail('jp1');
      expect(updatedListing!.post.images.length, 2);
      expect(updatedListing.post.images.any((img) => img.id == secondImageId), false);
      expect(updatedListing.post.images[0].displayOrder, 0);
      expect(updatedListing.post.images[1].displayOrder, 1);
    });

    test('reorderPostImages changes image order to match given ID list', () async {
      final initialListing = await repository.getJobPostDetail('jp1');
      final ids = initialListing!.post.images.map((i) => i.id).toList(); // [img_jp1_1, img_jp1_2, img_jp1_3]
      final reversedIds = ids.reversed.toList();

      final result = await repository.reorderPostImages('jp1', reversedIds);
      expect(result.success, true);

      final updatedListing = await repository.getJobPostDetail('jp1');
      final newIds = updatedListing!.post.images.map((i) => i.id).toList();
      expect(newIds, reversedIds);
      expect(updatedListing.post.images[0].displayOrder, 0);
      expect(updatedListing.post.images[1].displayOrder, 1);
      expect(updatedListing.post.images[2].displayOrder, 2);
    });
  });
}
