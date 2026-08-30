import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../data/models/chat_model.dart';

class ChatThreadScreen extends StatefulWidget {
  final String conversationId;

  const ChatThreadScreen({
    super.key,
    required this.conversationId,
  });

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
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final chatProvider = context.read<ChatProvider>();
    final conversations = await chatProvider.getConversations();
    final conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
    final messages = await chatProvider.getMessages(widget.conversationId);
    
    if (mounted) {
      setState(() {
        _conversation = conversation;
        _messages = messages;
        _isLoading = false;
      });
      chatProvider.markAsRead(widget.conversationId);
      _scrollToBottom();
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

    final msgText = text?.trim();
    _messageController.clear();

    // Mock send
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(widget.conversationId, 'current_user', text: msgText, imageUrl: imageUrl);
    
    // Refresh local list
    final updated = await chatProvider.getMessages(widget.conversationId);
    if (mounted) {
      setState(() => _messages = updated);
      _scrollToBottom();
      
      // Simulate typing indicator from other party after 1 second
      Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isTyping = true);
        _scrollToBottom();
        
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isTyping = false);
        });
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      _handleSend(imageUrl: image.path);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                final isMe = message.senderId == 'current_user';
                final showAvatar = !isMe && (index == 0 || _messages[index-1].senderId != message.senderId);
                
                return _buildMessageBubble(message, isMe, showAvatar);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: const BackButton(color: AppColors.onSurface),
      titleSpacing: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_conversation!.isSupport) return;
              if (_conversation!.otherUserRole == 'Client') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client profiles coming soon!')),
                );
              } else {
                Navigator.pushNamed(context, '${AppRouter.workerProfile}/${_conversation!.otherUserId}');
              }
            },
            child: CircleAvatar(
              radius: 18, 
              backgroundImage: _conversation!.isSupport 
                ? null 
                : NetworkImage(_conversation!.otherUserAvatar),
              child: _conversation!.isSupport ? const Icon(Icons.support_agent, size: 20) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversation!.otherUserName, 
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (_conversation!.bookingId != null)
                  Text(
                    'Re: ${_conversation!.otherUserRole} #${_conversation!.bookingId}',
                    style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
          onSelected: (value) {
            switch (value) {
              case 'view_profile':
                _navigateToProfile();
                break;
              case 'report_user':
                Navigator.pushNamed(context, '${AppRouter.fileReport}/${_conversation!.bookingId ?? 'placeholder'}');
                break;
              case 'clear_chat':
                _confirmClearChat();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!_conversation!.isSupport)
              const PopupMenuItem(
                value: 'view_profile',
                child: Text('View Profile'),
              ),
            const PopupMenuItem(
              value: 'report_user',
              child: Text('Report User'),
            ),
            const PopupMenuItem(
              value: 'clear_chat',
              child: Text('Clear Chat'),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToProfile() {
    if (_conversation!.isSupport) return;
    if (_conversation!.otherUserRole == 'Client') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client profiles coming soon!')),
      );
    } else {
      Navigator.pushNamed(context, '${AppRouter.workerProfile}/${_conversation!.otherUserId}');
    }
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages in this conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ChatProvider>().clearMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = [];
        });
      }
    }
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            SizedBox(
              width: 32,
              child: showAvatar 
                ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(_conversation!.otherUserAvatar))
                : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : (showAvatar ? 4 : 20)),
                      bottomRight: Radius.circular(isMe ? (showAvatar ? 4 : 20) : 20),
                    ),
                  ),
                  child: message.imageUrl != null 
                    ? _buildImageContent(message.imageUrl!)
                    : Text(
                        message.text ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isMe ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all, size: 12, color: message.isRead ? AppColors.primary : AppColors.outlineVariant),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildImageContent(String path) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: path.startsWith('http') 
          ? Image.network(path, height: 180, width: 140, fit: BoxFit.cover)
          : Image.file(File(path), height: 180, width: 140, fit: BoxFit.cover),
      ),
    );
  }

  void _showFullScreenImage(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            path.startsWith('http') ? Image.network(path) : Image.file(File(path)),
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        width: 60,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) => _buildDot()),
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 4, height: 4,
      decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.outline),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.outline),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleSend(text: _messageController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
