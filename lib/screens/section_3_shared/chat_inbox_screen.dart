import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/booking_model.dart';

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
    _conversationsFuture = context.read<ChatProvider>().getConversations();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isWorker = authProvider.userRole == 'worker';
    final theme = Theme.of(context);

    return Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: FutureBuilder<List<Conversation>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }

                final allConversations = snapshot.data ?? [];
                final filtered = allConversations.where((c) {
                  if (_searchQuery.isNotEmpty && !c.otherUserName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }
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
                  color: theme.colorScheme.primary,
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
    );
  }

  Widget _buildHeader() => const SizedBox.shrink();

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search, color: colorScheme.outline),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.1),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              checkmarkColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConversationRow(Conversation conversation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = conversation.isUnread;

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '${AppRouter.chatThread}/${conversation.id}');
        setState(() => _loadConversations()); 
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isUnread ? colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.15), width: 0.5)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (conversation.isSupport) return;
                if (conversation.otherUserRole == 'Client') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client profiles coming soon!')),
                  );
                } else {
                  Navigator.pushNamed(context, '${AppRouter.workerProfile}/${conversation.otherUserId}');
                }
              },
              child: _buildAvatar(conversation),
            ),
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
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: AppTypography.bodySmall.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
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
                            color: isUnread ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (conversation.bookingId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.surfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Re: Booking #${Booking.formatBookingCode(conversation.bookingId!, conversation.lastMessageTime)}',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (conversation.isSupport) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
        child: Icon(Icons.support_agent, color: colorScheme.onPrimary, size: 28),
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
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
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
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No messages found', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
