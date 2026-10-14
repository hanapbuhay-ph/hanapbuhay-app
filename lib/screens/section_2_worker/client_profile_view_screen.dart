import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/user_avatar.dart';

class ClientProfileViewScreen extends StatefulWidget {
  final String clientId;

  const ClientProfileViewScreen({super.key, required this.clientId});

  @override
  State<ClientProfileViewScreen> createState() => _ClientProfileViewScreenState();
}

class _ClientProfileViewScreenState extends State<ClientProfileViewScreen> {
  Map<String, dynamic>? _client;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    final response = await ApiClient.get('/clients/${widget.clientId}', requiresAuth: true);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response['success'] == true && response['data']?['client'] is Map) {
        _client = Map<String, dynamic>.from(response['data']['client'] as Map);
      } else {
        _error = response['message']?.toString() ?? 'Unable to load client profile.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colors.primary)));
    }
    if (_client == null) {
      return Scaffold(
            body: Column(
              children: [
                const AppHeader(title: 'Client Profile'),
                Expanded(child: Center(child: Text(_error ?? 'Client profile not found.'))),
              ],
            ),
      );
    }

    final client = _client!;
    final photo = client['profile_photo_path']?.toString() ?? client['profile_photo_url']?.toString();
    final barangay = client['barangay'] is Map ? client['barangay']['name']?.toString() : null;
    final bookings = (client['bookings'] as List<dynamic>? ?? const []).whereType<Map>().toList();
    final ratings = (client['ratings'] as List<dynamic>? ?? const []).whereType<Map>().toList();
    final averageRating = double.tryParse(client['average_rating']?.toString() ?? '');

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Client Profile'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 58,
                      backgroundColor: colors.primaryContainer,
                      backgroundImage: photo == null ? null : NetworkImage(AppConstants.getPhotoUrl(photo)),
                      child: photo == null ? Icon(Icons.person_outline, size: 52, color: colors.onPrimaryContainer) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(client['name']?.toString() ?? 'Client', style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w800))),
                  const SizedBox(height: 6),
                  Center(child: Text('Client account', style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant))),
                  const SizedBox(height: 28),
                  _sectionTitle('Contact and Location'),
                  _infoRow(Icons.email_outlined, 'Email', client['email']?.toString() ?? 'Not provided'),
                  _infoRow(Icons.phone_outlined, 'Mobile number', client['mobile_number']?.toString() ?? 'Not provided'),
                  _infoRow(Icons.location_on_outlined, 'Barangay', barangay ?? 'Not provided'),
                  _infoRow(Icons.calendar_today_outlined, 'Member since', _formatDate(client['joined_at'])),
                  const SizedBox(height: 24),
                  _sectionTitle('Worker Ratings'),
                  _ratingsSummary(
                    averageRating,
                    int.tryParse(client['rating_count']?.toString() ?? '') ?? ratings.length,
                  ),
                  const SizedBox(height: 12),
                  if (ratings.isEmpty)
                    Text(
                      'This client has not received any worker ratings yet.',
                      style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    )
                  else
                    ...ratings.map(_ratingCard),
                  const SizedBox(height: 24),
                  _sectionTitle('Booking History'),
                  Row(
                    children: [
                      Expanded(child: _statCard('Bookings', '${client['booking_count'] ?? bookings.length}', Icons.receipt_long_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Completed', '${client['completed_booking_count'] ?? 0}', Icons.check_circle_outline)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (bookings.isEmpty)
                    Text('No booking history available.', style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant))
                  else
                    ...bookings.map((booking) => _bookingCard(booking)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
      );

  Widget _infoRow(IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [Icon(icon, size: 20, color: colors.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)), const SizedBox(height: 2), Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600))]))]),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, color: colors.primary), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)), Text(label, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant))])]));
  }

  Widget _ratingsSummary(double? rating, int count) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 30),
          const SizedBox(width: 10),
          Text(
            rating == null ? '—' : rating.toStringAsFixed(1),
            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1 ? '1 rating from a worker' : '$count ratings from workers',
              style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard(Map rating) {
    final colors = Theme.of(context).colorScheme;
    final reviewerName = rating['rated_by_name']?.toString() ?? 'Worker';
    final reviewerPhoto = AppConstants.getOptionalPhotoUrl(
      rating['reviewer_avatar_url']?.toString(),
    );
    final score = double.tryParse(rating['score']?.toString() ?? '') ?? 0;
    final comment = rating['comment']?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: reviewerName, radius: 20, photoPath: reviewerPhoto),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatDate(rating['created_at']),
                      style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < score ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bookingCard(Map booking) {
    final colors = Theme.of(context).colorScheme;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.work_outline, color: colors.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking['service']?.toString() ?? 'Service', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)), Text(booking['booking_code']?.toString() ?? '', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant))])), Text(booking['status']?.toString() ?? '', style: AppTypography.labelSmall.copyWith(color: colors.primary, fontWeight: FontWeight.w700))]));
  }

  String _formatDate(dynamic value) {
    final date = value == null ? null : DateTime.tryParse(value.toString());
    if (date == null) return 'Not available';
    return '${date.month}/${date.day}/${date.year}';
  }
}
