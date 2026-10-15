import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/worker_repository.dart';

void main() {
  test('serializes search and all selected feed filters', () {
    final params = const FeedFilters(
      search: '  pipe repair ',
      categoryIds: ['2', '5'],
      barangayId: '14',
      rateTypes: ['hourly', 'per_project'],
      verification: 'verified',
      availability: 'available',
      page: 3,
    ).toQueryParams();

    expect(params, {
      'search': 'pipe repair',
      'category_ids': '2,5',
      'barangay_id': '14',
      'rate_types': 'hourly,per_project',
      'verification': 'verified',
      'availability': 'available',
      'page': '3',
    });
  });

  test('omits empty search and default filters', () {
    final params = const FeedFilters(search: '  ').toQueryParams();

    expect(params, {'page': '1'});
  });
}
