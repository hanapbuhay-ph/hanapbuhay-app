import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/navigation/client_bottom_nav.dart';
import '../../widgets/navigation/worker_bottom_nav.dart';

class FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class FaqCategory {
  final String title;
  final IconData icon;
  final List<FaqItem> items;

  FaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FaqCategory> _categories = [
    FaqCategory(
      title: 'Account & Profile',
      icon: Icons.manage_accounts,
      items: [
        FaqItem(
          question: 'How do I verify my account?',
          answer: 'To verify your account, navigate to your Profile tab, tap on "Verification Settings", and follow the prompts to upload a valid government-issued ID and a clear selfie. Verification typically takes 24 hours.',
        ),
        FaqItem(
          question: 'I forgot my password',
          answer: 'On the login screen, tap "Forgot Password". Enter your registered email address or mobile number to receive a secure reset link.',
        ),
      ],
    ),
    FaqCategory(
      title: 'Bookings & Jobs',
      icon: Icons.assignment_turned_in,
      items: [
        FaqItem(
          question: "What happens if a worker doesn't show up?",
          answer: 'If a worker misses a scheduled booking without notice, please report the issue immediately through the "Bookings" tab. You will be fully refunded, and our team will assist you in finding a replacement worker.',
        ),
        FaqItem(
          question: 'How do I cancel a booking?',
          answer: 'Navigate to your active bookings, select the specific job, and tap "Cancel Booking". Please note that cancellations made within 24 hours of the start time may be subject to a cancellation fee.',
        ),
      ],
    ),
    FaqCategory(
      title: 'Safety & Privacy',
      icon: Icons.security,
      items: [
        FaqItem(
          question: 'Is my data safe?',
          answer: 'Absolutely. We use industry-standard end-to-end encryption to protect your personal and payment information. We never share your data with third parties without your explicit consent.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;

    return _categories.map((category) {
      final filteredItems = category.items
          .where((item) => item.question.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      return FaqCategory(title: category.title, icon: category.icon, items: filteredItems);
    }).where((category) => category.items.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isWorker = authProvider.userRole == 'worker';
    final filtered = _filteredCategories;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(title: 'Help Center'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 32),
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ...filtered.map((category) => _buildCategorySection(category)),
                  const SizedBox(height: 40),
                  _buildContactSupport(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWorker 
          ? const WorkerBottomNav(currentIndex: 4) 
          : const ClientBottomNav(currentIndex: 4),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search for help...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search, color: colorScheme.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategorySection(FaqCategory category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(category.icon, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                category.title,
                style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(category.items.length, (index) {
              final item = category.items[index];
              final isLast = index == category.items.length - 1;
              return Column(
                children: [
                  _buildAccordionItem(category, item),
                  if (!isLast) Divider(height: 1, indent: 20, endIndent: 20, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAccordionItem(FaqCategory category, FaqItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        ListTile(
          title: Text(
            item.question,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: item.isExpanded ? FontWeight.w700 : FontWeight.w500,
              color: item.isExpanded ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          trailing: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: item.isExpanded ? 0.5 : 0,
            child: Icon(Icons.expand_more, size: 20, color: colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            setState(() {
              final wasExpanded = item.isExpanded;
              for (var i in category.items) {
                i.isExpanded = false;
              }
              item.isExpanded = !wasExpanded;
            });
          },
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.answer,
              style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ),
          crossFadeState: item.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildContactSupport() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          "Can't find what you're looking for?",
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '${AppRouter.chatThread}/c2'); 
            },
            icon: const Icon(Icons.headset_mic_outlined),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.search_off_outlined, size: 64, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(
          'No results found for "$_searchQuery"',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(fontSize: 18, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Try using different keywords or check out the categories below.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
