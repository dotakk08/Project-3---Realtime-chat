import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool darkMode;
  final double fontSize;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    this.darkMode = false,
    this.fontSize = 16,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late bool darkMode;
  late double fontSize;

  @override
  void initState() {
    super.initState();
    darkMode = widget.darkMode;
    fontSize = widget.fontSize;
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    final displayName = user.displayName ?? user.email ?? "Ẩn danh";

    await _db.sendMessage(
        roomId: widget.roomId, sender: displayName, text: text);
    _controller.clear();

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 60,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: TextStyle(color: darkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: darkMode ? Colors.grey[850] : Colors.blueAccent,
        iconTheme: IconThemeData(color: darkMode ? Colors.white : Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _db.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final dataSnapshot = snapshot.data!;
                final data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

                if (data == null) return const Center(child: Text('Chưa có tin nhắn.'));

                final messages = data.entries.toList()
                  ..sort((a, b) =>
                      (a.value['timestamp'] ?? 0).compareTo(b.value['timestamp'] ?? 0));

                final currentUserName = AuthService().currentUser?.displayName ??
                    AuthService().currentUser?.email ??
                    "Ẩn danh";

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgId = messages[index].key;
                    final msg = messages[index].value;
                    final sender = msg['sender'] ?? 'Ẩn danh';
                    final isMe = sender == currentUserName;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: darkMode ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment:
                                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blueAccent : Colors.grey[300],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: isMe
                                          ? const Radius.circular(16)
                                          : const Radius.circular(0),
                                      bottomRight: isMe
                                          ? const Radius.circular(0)
                                          : const Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['text'] ?? '',
                                        style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black87,
                                            fontSize: fontSize),
                                      ),
                                      if (msg['edited'] == true)
                                        Text(
                                          '(đã sửa)',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: isMe
                                                  ? Colors.white70
                                                  : Colors.black54),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isMe)
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      final newText = await showDialog<String>(
                                        context: context,
                                        builder: (_) {
                                          final editController =
                                              TextEditingController(text: msg['text']);
                                          return AlertDialog(
                                            title: const Text('Sửa tin nhắn'),
                                            content: TextField(controller: editController),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Hủy')),
                                              ElevatedButton(
                                                  onPressed: () => Navigator.pop(
                                                      context, editController.text),
                                                  child: const Text('Lưu')),
                                            ],
                                          );
                                        },
                                      );
                                      if (newText != null && newText.trim().isNotEmpty) {
                                        await _db.updateMessage(
                                            roomId: widget.roomId,
                                            messageId: msgId,
                                            newText: newText.trim());
                                      }
                                    } else if (value == 'delete') {
                                      await _db.deleteMessage(
                                          roomId: widget.roomId, messageId: msgId);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: darkMode ? Colors.grey[850] : Colors.grey[200],
              boxShadow: const [
                BoxShadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, -1))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: darkMode ? Colors.white54 : Colors.black45),
                    ),
                    style: TextStyle(color: darkMode ? Colors.white : Colors.black87),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
