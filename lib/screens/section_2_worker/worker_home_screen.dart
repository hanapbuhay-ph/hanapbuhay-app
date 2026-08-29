import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/navigation/worker_bottom_nav.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  late Future<Worker?> _workerFuture;
  late Future<List<Booking>> _requestsFuture;
  WorkerAvailability _currentStatus = WorkerAvailability.available;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // For demo/mock, we assume worker ID 'w1'
    _workerFuture = workerRepository.getWorkerById('w1');
    _requestsFuture = bookingRepository.getBookings().then(
      (list) => list.where((b) => b.status == BookingStatus.pending).toList()
    );
  }

  Future<void> _handleResponse(String bookingId, bool accept) async {
    final result = await bookingRepository.respondToBooking(bookingId: bookingId, accept: accept);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: accept ? AppColors.primary : AppColors.error),
      );
      if (accept) {
        context.push('${AppRouter.jobDetail}/$bookingId');
      }
      setState(() => _loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firstName = authProvider.userEmail?.split('@').first ?? 'Ricardo';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Worker?>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final worker = snapshot.data;
          if (worker == null) return const Center(child: Text('Worker profile not found'));

          return Column(
            children: [
              _buildHeader(worker),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loadData());
                  },
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(firstName),
                        const SizedBox(height: 24),
                        if (worker.verificationStatus != VerificationStatus.verified) ...[
                          _buildVerificationBanner(worker),
                          const SizedBox(height: 24),
                        ],
                        _buildAvailabilityCard(),
                        const SizedBox(height: 24),
                        _buildStatsRow(worker),
                        const SizedBox(height: 32),
                        _buildIncomingRequestsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
      bottomNavigationBar: const WorkerBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeader(Worker worker) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 16),
            const Text(
              'HanapBuhay',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(AppRouter.notificationCenter),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: StreamBuilder<int>(
                      stream: notificationRepository.getUnreadCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(radius: 16, backgroundImage: NetworkImage(worker.avatarUrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hi, $name!', style: AppTypography.headlineMedium.copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Ready for a great day of work.', style: AppTypography.bodyMedium),
      ],
    );
  }

  Widget _buildVerificationBanner(Worker worker) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE082).withOpacity(0.3), // Amber/Tertiary fixed-ish
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.verificationStatus == VerificationStatus.rejected 
                        ? 'Verification Rejected'
                        : 'Your account isn\'t verified yet', 
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      worker.verificationStatus == VerificationStatus.rejected
                        ? 'Please review the reason and try again.'
                        : 'Verified workers get more bookings.', 
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (worker.verificationStatus == VerificationStatus.notStarted) {
                  context.push(AppRouter.verificationDocuments);
                } else {
                  context.push(AppRouter.verificationStatus);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                worker.verificationStatus == VerificationStatus.notStarted 
                  ? 'Complete Verification' 
                  : 'Check Status', 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Status', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildStatusToggle(WorkerAvailability.available, 'Available', AppColors.primary),
                _buildStatusToggle(WorkerAvailability.busy, 'Busy', Colors.orange),
                _buildStatusToggle(WorkerAvailability.offline, 'Offline', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(WorkerAvailability status, String label, Color color) {
    final isSelected = _currentStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Worker worker) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.verified,
          label: 'Trust Tier',
          value: worker.isVerified ? 'Verified' : 'Unverified',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.star,
          label: 'Rating',
          value: worker.rating.toString(),
          color: Colors.amber,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.work,
          label: 'Jobs',
          value: '${worker.completedJobsCount} Done',
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequestsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Incoming Requests', style: AppTypography.headlineMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () {
                context.push(AppRouter.bookingSchedule);
              },
              child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Booking>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.outlineVariant),
                    SizedBox(height: 12),
                    Text('No pending requests', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              );
            }
            return Column(
              children: requests.map((req) => _buildRequestCard(req)).toList(),
            );
          }
        ),
      ],
    );
  }

  Widget _buildRequestCard(Booking request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=client')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client Name', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(request.category, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Text('Just now', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('${request.date.day}/${request.date.month}/${request.date.year} • ${request.time}', style: AppTypography.bodySmall),
              const Spacer(),
              const Icon(Icons.location_on, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(request.barangay, style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleResponse(request.id, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleResponse(request.id, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
