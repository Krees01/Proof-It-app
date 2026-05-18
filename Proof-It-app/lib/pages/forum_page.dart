import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:main/API/api_storage.dart';
import 'package:main/API/api_user.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/data_models.dart';
import '../data/mock_database.dart';
import '../services/notification_service.dart';
import 'package:main/API/api_forum.dart';

class ForumPage extends StatefulWidget {
  final EventModel event;
  const ForumPage({super.key, required this.event});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postController = TextEditingController();
  Map<String, String> _userMap = {};

  Map<String, dynamic>? _replyingTo;
  Map<String, dynamic>? _editingMessage;
  bool _isUploading = false;

  final Set<String> _collapsedPosts = {};
  late Future<List<dynamic>> _forumFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserNames();
    _fetchForums();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _fetchForums() {
    setState(() {
      _forumFuture = ApiForum.getMessages(widget.event.id);
    });
  }

  Future<void> _fetchUserNames() async {
    try {
      final response = await ApiUser.getUsers();
      final Map<String, String> tempMap = {};

      for (var row in response) {
        tempMap[row['id'].toString()] = row['username'].toString();
      }

      if (mounted) {
        setState(() {
          _userMap = tempMap;
        });
      }
    } catch (e) {
      print("Gagal fetch users: $e");
    }
  }

  Future<void> _sendPost({
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    final text = _postController.text.trim();

    if (text.isEmpty && attachmentUrl == null) {
      return;
    }

    final isEdit = _editingMessage != null;
    final editId = _editingMessage?['id'];
    final replyId = _replyingTo?['id'];
    final messageToSend = text.isNotEmpty ? text : '';

    try {
      if (isEdit) {
        await ApiForum.editMessage(editId.toString(), messageToSend);
      } else {
        await ApiForum.sendMessage({
          'project_id': widget.event.id,
          'user_id': AuthSession.currentUser!.id,
          'message': messageToSend,
          'attachment_url': attachmentUrl,
          'reply_to_text': attachmentName,
          'reply_to_id': replyId?.toString(),
        });

        if (replyId != null) {
          final originalUserId = _replyingTo?['user_id']?.toString() ?? '';
          if (originalUserId.isNotEmpty &&
              originalUserId != AuthSession.currentUser!.id) {
            await NotificationService.send(
              userId: originalUserId,
              type: 'new_reply',
              title: 'Balasan Baru',
              message:
                  '${AuthSession.currentUser!.username} membalas post kamu di "${widget.event.title}"',
              projectId: widget.event.id,
            );
          }
        } else {
          final memberIds = widget.event.teamEmails
              .where(
                (email) => email != AuthSession.currentUser!.email,
              )
              .toList();

          if (memberIds.isNotEmpty) {
            await NotificationService.sendToMany(
              userIds: memberIds,
              type: 'new_post',
              title: 'Post Baru di Forum',
              message:
                  '${AuthSession.currentUser!.username} membuat post baru di "${widget.event.title}"',
              projectId: widget.event.id,
            );
          }
        }
      }

      _postController.clear();
      FocusScope.of(context).unfocus();
      _fetchForums();

      if (mounted) {
        setState(() {
          _editingMessage = null;
          _replyingTo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
      );
      if (result == null) return;

      setState(() {
        _isUploading = true;
      });

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) throw Exception("File bytes null");

      final response = await ApiStorage.uploadFile(bytes, file.name);

      await _sendPost(
        attachmentUrl: response['url'],
        attachmentName: response['fileName'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload gagal: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  Future<void> _downloadFile(String url) async {
    try {
      String downloadUrl = url;
      if (!url.toLowerCase().contains('download=')) {
        downloadUrl = url.contains('?') ? '$url&download=' : '$url?download=';
      }

      final uri = Uri.parse(downloadUrl);
      
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Memulai proses download...")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mendownload file: $e")),
        );
      }
    }
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            elevation: 0,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      iconSize: 24,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachment(String url, String? fileName) {
    final isImage = _isImageUrl(url);
    final displayName = fileName ?? url.split('/').last.split('?').first;

    if (isImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () => _downloadFile(url),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "Download",
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.indigo, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download, size: 18, color: Colors.green),
            tooltip: "Download",
            onPressed: () => _downloadFile(url),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTree(
    Map<String, dynamic> post,
    List<dynamic> allPosts,
    int depth,
  ) {
    final String currentPostId = post['id']?.toString() ?? '';
    final replies = allPosts.where((m) {
      final String replyToId = m['reply_to_id']?.toString() ?? '';
      return replyToId.isNotEmpty && replyToId == currentPostId;
    }).toList();

    final bool hasReplies = replies.isNotEmpty;
    final bool isCollapsed = _collapsedPosts.contains(currentPostId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildForumCard(
          post,
          depth,
          hasReplies: hasReplies,
          isCollapsed: isCollapsed,
        ),
        if (hasReplies && !isCollapsed)
          ...replies
              .map((reply) => _buildPostTree(reply, allPosts, depth + 1))
              .toList(),
        if (hasReplies && isCollapsed)
          Padding(
            padding: EdgeInsets.only(
              left: 16 + (depth > 4 ? 4.0 * 20.0 : depth * 20.0) + 20,
              bottom: 8,
            ),
            child: InkWell(
              onTap: () =>
                  setState(() => _collapsedPosts.remove(currentPostId)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Tampilkan ${replies.length} balasan",
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForumCard(
    Map<String, dynamic> post,
    int depth, {
    bool hasReplies = false,
    bool isCollapsed = false,
  }) {
    try {
      final currentUser = AuthSession.currentUser;
      final currentUserId = currentUser?.id?.toString() ?? '';
      final postUserId = post['user_id']?.toString() ?? 'unknown';
      final isMe = currentUserId.isNotEmpty && postUserId == currentUserId;

      final rawName = _userMap[postUserId] ?? 'User';
      final senderName = rawName.trim().isEmpty ? 'User' : rawName;
      final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';

      final message = post['message']?.toString() ?? '';
      final attachmentUrl = post['attachment_url']?.toString();
      final attachmentName = post['reply_to_text']?.toString();
      final postId = post['id']?.toString() ?? '';

      final double indent = depth > 4 ? 4.0 * 20.0 : depth * 20.0;
      final accentColor = depth == 0 ? Colors.indigo : Colors.grey.shade400;
      final accentWidth = depth == 0 ? 4.0 : 2.0;

      return Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 4,
          left: 16 + indent,
          right: 16,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: accentWidth,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                      right: BorderSide(color: Colors.grey.shade200),
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                    boxShadow: depth == 0
                        ? [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.indigo,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  senderName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "You",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (hasReplies)
                                InkWell(
                                  onTap: () => setState(() {
                                    if (isCollapsed) {
                                      _collapsedPosts.remove(postId);
                                    } else {
                                      _collapsedPosts.add(postId);
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCollapsed
                                              ? Icons.keyboard_arrow_down
                                              : Icons.keyboard_arrow_up,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          isCollapsed ? "Tampilkan" : "Sembunyikan",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (message.isNotEmpty)
                            Text(
                              message,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          if (attachmentUrl != null) ...[
                            if (message.isNotEmpty) const SizedBox(height: 12),
                            _buildAttachment(attachmentUrl, attachmentName),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => setState(() {
                                  _replyingTo = post;
                                  _editingMessage = null;
                                }),
                                child: const Text(
                                  "Reply",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () => setState(() {
                                    _editingMessage = post;
                                    _replyingTo = null;
                                    _postController.text = message;
                                  }),
                                  child: const Text(
                                    "Edit",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text("Hapus Post?"),
                                        content: const Text(
                                          "Tindakan ini tidak bisa dibatalkan.",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text("Batal"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () => Navigator.pop(c, true),
                                            child: const Text("Hapus"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ApiForum.deleteMessage(postId);
                                        _fetchForums();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Gagal Hapus: $e"),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Text(
          "Error Render: $e",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text("Forum: ${widget.event.title}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _forumFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allMessages = snapshot.data ?? [];
                final mainPosts = allMessages
                    .where((m) => m['reply_to_id'] == null)
                    .toList();

                if (mainPosts.isEmpty) {
                  return const Center(child: Text("Belum ada diskusi"));
                }

                return ListView.builder(
                  itemCount: mainPosts.length,
                  itemBuilder: (context, index) {
                    final post = mainPosts[index];
                    return _buildPostTree(post, allMessages, 0);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    String hint = "Buat postingan diskusi baru...";
    if (_replyingTo != null) hint = "Menulis balasan...";
    if (_editingMessage != null) hint = "Mengedit pesan...";

    return Column(
      children: [
        if (_replyingTo != null || _editingMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                Icon(
                  _editingMessage != null ? Icons.edit : Icons.reply,
                  size: 16,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _editingMessage != null
                        ? "Editing post..."
                        : "Replying to: ${_userMap[_replyingTo!['user_id'].toString()] ?? 'User'}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.indigo),
                  onPressed: () => setState(() {
                    _replyingTo = null;
                    _editingMessage = null;
                    _postController.clear();
                    FocusScope.of(context).unfocus();
                  }),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: _pickAndUploadFile,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _postController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _sendPost(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}