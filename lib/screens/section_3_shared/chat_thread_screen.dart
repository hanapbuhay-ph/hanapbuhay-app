import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/chat_model.dart';
import '../../services/pusher_service.dart';

class ChatThreadScreen extends StatefulWidget {
  final String conversationId;

  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  Conversation? _conversation;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasText = false;
  bool _isRefreshingMessages = false;
  bool _refreshPending = false;

  String? _currentUserId;
  final PusherService _pusherService = PusherService.instance;
  void Function(NewMessageEvent)? _newMessageHandler;
  bool _hasBookingSubscription = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthProvider>().userId;
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final chatProvider = context.read<ChatProvider>();
    final conversations = await chatProvider.getConversations();
    final conversation = conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => Conversation(
        id: widget.conversationId,
        otherUserId: '',
        otherUserName: 'Chat',
        otherUserRole: '',
        otherUserAvatar: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      ),
    );
    final messages = await chatProvider.getMessages(widget.conversationId);

    if (mounted) {
      setState(() {
        _conversation = conversation;
        _messages = messages;
        _isLoading = false;
      });
      chatProvider.markAsRead(widget.conversationId);
      _scrollToBottom();
      _newMessageHandler = _handleNewMessage;
      _pusherService.onNewMessage = _newMessageHandler;
      try {
        await _pusherService.subscribe(widget.conversationId);
      } catch (error) {
        if (_pusherService.onNewMessage == _newMessageHandler) {
          _pusherService.onNewMessage = null;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Live chat connection failed: $error')),
          );
        }
        return;
      }
      _hasBookingSubscription = true;
      if (!mounted) {
        _hasBookingSubscription = false;
        await _pusherService.unsubscribe(widget.conversationId);
        return;
      }
      try {
        await _refreshMessages();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not refresh chat messages: $error')),
          );
        }
      }
    }
  }

  void _handleNewMessage(NewMessageEvent event) {
    if (event.bookingId.toString() != widget.conversationId) return;
    unawaited(_refreshMessages());
  }

  Future<void> _refreshMessages() async {
    if (_isRefreshingMessages) {
      _refreshPending = true;
      return;
    }

    _isRefreshingMessages = true;
    try {
      do {
        _refreshPending = false;
        final updated = await context
            .read<ChatProvider>()
            .getMessages(widget.conversationId);
        if (mounted) {
          setState(() => _messages = updated);
          _scrollToBottom();
        }
      } while (_refreshPending && mounted);
    } finally {
      _isRefreshingMessages = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;
    if (_isSending) return;

    final msgText = text?.trim();
    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final sentMessage = await context.read<ChatProvider>().sendMessage(
        widget.conversationId,
        senderId: _currentUserId,
        text: msgText,
        imageUrl: imageUrl,
      );
      if (!mounted) return;

      setState(() {
        final sentIndex = _messages.indexWhere(
          (message) => message.id == sentMessage.id,
        );
        if (sentIndex == -1) {
          _messages = [..._messages, sentMessage];
        } else {
          _messages[sentIndex] = sentMessage;
        }
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      if (msgText != null && msgText.isNotEmpty) {
        _messageController.text = msgText;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message could not be sent: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) _handleSend(imageUrl: image.path);
  }

  bool _isMe(Message message) => message.senderId == _currentUserId;

  // A message shows its avatar when it's the LAST in a consecutive group from the other party
  bool _showAvatar(int index) {
    if (_isMe(_messages[index])) return false;
    final isLast = index == _messages.length - 1;
    final nextIsDifferent = !isLast && _isMe(_messages[index + 1]);
    final nextIsSameSender = !isLast && !_isMe(_messages[index + 1]);
    return isLast || nextIsDifferent || (!nextIsSameSender && index == _messages.length - 1);
  }

  // First message in a consecutive group shows the sender name
  bool _showSenderName(int index) {
    if (_isMe(_messages[index])) return false;
    if (index == 0) return true;
    return _isMe(_messages[index - 1]) || _messages[index - 1].senderId != _messages[index].senderId;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    if (_pusherService.onNewMessage == _newMessageHandler) {
      _pusherService.onNewMessage = null;
    }
    if (_hasBookingSubscription) {
      unawaited(_pusherService.unsubscribe(widget.conversationId));
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = _isMe(message);
                      final showAvatar = _showAvatar(index);
                      final showName = _showSenderName(index);
                      final isLastInGroup = showAvatar || (isMe && (index == _messages.length - 1 || !_isMe(_messages[index + 1])));
                      return _buildMessageRow(message, isMe, showAvatar, showName, isLastInGroup, index);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 56, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text('No messages yet', style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Say hello!', style: AppTypography.bodySmall.copyWith(color: colorScheme.outlineVariant)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final conv = _conversation!;
    final avatarUrl = conv.otherUserAvatar.isNotEmpty
        ? AppConstants.getPhotoUrl(conv.otherUserAvatar)
        : null;

    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      leading: BackButton(color: colorScheme.onSurface),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          if (conv.isSupport) return;
          if (conv.otherUserRole.toLowerCase() == 'client') {
            Navigator.pushNamed(
              context,
              '${AppRouter.clientProfile}/${conv.otherUserId}',
            );
          } else {
            Navigator.pushNamed(context, '${AppRouter.workerProfile}/${conv.otherUserId}');
          }
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: conv.isSupport || avatarUrl == null ? null : NetworkImage(avatarUrl),
              backgroundColor: conv.isSupport ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              child: conv.isSupport ? Icon(Icons.support_agent, size: 20, color: colorScheme.onPrimary) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.otherUserName,
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface),
                  ),
                  if (conv.bookingId != null)
                    Text(
                      'Booking #${conv.bookingId}',
                      style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  if (!conv.isSupport)
                    Text(
                      conv.otherUserRole.toLowerCase() == 'worker'
                          ? 'Availability: ${conv.availabilityStatus ?? 'unknown'}'
                          : (conv.isOnline ? 'Online' : 'Offline'),
                      style: TextStyle(
                        fontSize: 10,
                        color: conv.isOnline ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
          onSelected: (value) {
            switch (value) {
              case 'view_profile':
                _navigateToProfile();
              case 'report_user':
                if (conv.bookingId != null) {
                  Navigator.pushNamed(context, '${AppRouter.fileReport}/${conv.bookingId}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporting is only available for booking-related conversations.')),
                  );
                }
              case 'clear_chat':
                _confirmClearChat();
            }
          },
          itemBuilder: (context) => [
            if (!conv.isSupport)
              const PopupMenuItem(value: 'view_profile', child: Text('View Profile')),
            const PopupMenuItem(value: 'report_user', child: Text('Report User')),
            const PopupMenuItem(value: 'clear_chat', child: Text('Clear Chat')),
          ],
        ),
      ],
    );
  }

  void _navigateToProfile() {
    final conv = _conversation!;
    if (conv.isSupport) return;
    if (conv.otherUserRole.toLowerCase() == 'client') {
      Navigator.pushNamed(
        context,
        '${AppRouter.clientProfile}/${conv.otherUserId}',
      );
    } else {
      Navigator.pushNamed(context, '${AppRouter.workerProfile}/${conv.otherUserId}');
    }
  }

  Future<void> _confirmClearChat() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ChatProvider>().clearMessages(widget.conversationId);
      if (mounted) setState(() => _messages = []);
    }
  }

  Widget _buildMessageRow(Message message, bool isMe, bool showAvatar, bool showName, bool isLastInGroup, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarUrl = _conversation!.otherUserAvatar.isNotEmpty
        ? AppConstants.getPhotoUrl(_conversation!.otherUserAvatar)
        : null;

    // Bubble shape: tail on the last message of each group
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (isLastInGroup ? 4 : 18)),
      bottomRight: Radius.circular(isMe ? (isLastInGroup ? 4 : 18) : 18),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? 8 : 2,
        top: showName ? 8 : 0,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other party avatar placeholder (keeps alignment consistent)
          if (!isMe) ...[
            SizedBox(
              width: 32,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: avatarUrl == null ? Icon(Icons.person, size: 14, color: colorScheme.onSurfaceVariant) : null,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showName)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      _conversation!.otherUserName,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: message.imageUrl != null
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    borderRadius: radius,
                  ),
                  child: message.imageUrl != null
                      ? _buildImageContent(message.imageUrl!)
                      : Text(
                          message.text ?? '',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                ),
                if (isLastInGroup) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.done_all,
                          size: 13,
                          color: message.isRead ? colorScheme.primary : colorScheme.outlineVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildImageContent(String path) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: path.startsWith('http')
            ? Image.network(path, height: 200, width: 180, fit: BoxFit.cover)
            : Image.file(File(path), height: 200, width: 180, fit: BoxFit.cover),
      ),
    );
  }

  void _showFullScreenImage(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Center(
                child: path.startsWith('http')
                    ? Image.network(path)
                    : Image.file(File(path)),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.photo_outlined, color: colorScheme.onSurfaceVariant),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: colorScheme.onSurfaceVariant),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _isSending
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('send'),
                    onTap: _hasText ? () => _handleSend(text: _messageController.text) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _hasText ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: _hasText ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
