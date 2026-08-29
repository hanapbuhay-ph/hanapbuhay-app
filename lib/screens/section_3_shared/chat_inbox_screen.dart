import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../data/models/chat_model.dart';
import '../../widgets/navigation/client_bottom_nav.dart';
import '../../widgets/navigation/worker_bottom_nav.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  late Future<List<Conversation>> _conversationsFuture;
  String _filter = 'All'; // 'All', 'Unread', 'Bookings'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    _conversationsFuture = chatRepository.getConversations();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isWorker = authProvider.userRole == 'worker';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: FutureBuilder<List<Conversation>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final allConversations = snapshot.data ?? [];
                final filtered = allConversations.where((c) {
                  // Search filter
                  if (_searchQuery.isNotEmpty && !c.otherUserName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }
                  // Type filter
                  if (_filter == 'Unread' && !c.isUnread) return false;
                  if (_filter == 'Bookings' && c.bookingId == null) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loadConversations());
                  },
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildConversationRow(filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWorker 
          ? const WorkerBottomNav(currentIndex: 2) 
          : const ClientBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 16),
            Text('Messages', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=current_user')),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search messages...',
          prefixIcon: const Icon(Icons.search, color: AppColors.outline),
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: ['All', 'Unread', 'Bookings'].map((label) {
          final isSelected = _filter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) => setState(() => _filter = label),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              checkmarkColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConversationRow(Conversation conversation) {
    return InkWell(
      onTap: () async {
        await context.push('${AppRouter.chatThread}/${conversation.id}');
        setState(() => _loadConversations()); // Refresh in case marked as read
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildAvatar(conversation),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${conversation.otherUserName} ${conversation.isSupport ? "" : "(${conversation.otherUserRole})" }',
                        style: AppTypography.bodyLarge.copyWith(fontWeight: conversation.isUnread ? FontWeight.w800 : FontWeight.w700),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: AppTypography.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: AppTypography.bodyMedium.copyWith(
                            color: conversation.isUnread ? AppColors.onSurface : AppColors.onSurfaceVariant,
                            fontWeight: conversation.isUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.leafBright, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (conversation.bookingId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Re: Booking #${conversation.bookingId}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Conversation conversation) {
    if (conversation.isSupport) {
      return Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
      );
    }

    return Stack(
      children: [
        CircleAvatar(radius: 26, backgroundImage: NetworkImage(conversation.otherUserAvatar)),
        if (conversation.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.leafBright,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return 'Yesterday';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          const Text('No messages found', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try adjusting your search or filters.', style: TextStyle(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
