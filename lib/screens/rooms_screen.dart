import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../screens/chat_screen.dart';
import '../services/auth_service.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final DatabaseService _db = DatabaseService();
  bool darkMode = false;
  double fontSize = 16;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Danh sách phòng chat',
          style: TextStyle(color: darkMode ? Colors.white : Colors.black87),
        ),
        backgroundColor: darkMode ? Colors.grey[850] : Colors.blueAccent,
        iconTheme: IconThemeData(color: darkMode ? Colors.white : Colors.black87),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                  color: darkMode ? Colors.grey[800] : Colors.blueAccent),
              child: Center(
                  child: Text(
                'Menu',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              )),
            ),
            ListTile(
              leading: const Icon(Icons.format_size),
              title: const Text('Cỡ chữ chat'),
              subtitle: Slider(
                value: fontSize,
                min: 12,
                max: 30,
                divisions: 9,
                label: fontSize.toInt().toString(),
                onChanged: (value) => setState(() => fontSize = value),
              ),
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: darkMode,
              onChanged: (value) => setState(() => darkMode = value),
              secondary: const Icon(Icons.brightness_6),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                await AuthService().signOut();
                if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: _db.getRoomsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final dataSnapshot = snapshot.data!;
          final data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

          if (data == null)
            return Center(
              child: Text(
                'Chưa có phòng nào.',
                style: TextStyle(color: darkMode ? Colors.white70 : Colors.black87),
              ),
            );

          final rooms = data.entries.toList()
            ..sort((a, b) =>
                (a.value['createdAt'] ?? 0).compareTo(b.value['createdAt'] ?? 0));

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final roomId = rooms[index].key;
              final room = rooms[index].value;

              return Container(
                color: darkMode ? Colors.grey[800] : Colors.grey[50],
                child: ListTile(
                  title: Text(
                    room['name'] ?? 'Phòng Ẩn danh',
                    style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.black87),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (_) {
                            final controller =
                                TextEditingController(text: room['name']);
                            return AlertDialog(
                              title: const Text('Sửa tên phòng'),
                              content: TextField(controller: controller),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Hủy')),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                        context, controller.text.trim()),
                                    child: const Text('Lưu')),
                              ],
                            );
                          },
                        );
                        if (newName != null && newName.isNotEmpty) {
                          await _db.updateRoomName(roomId, newName);
                        }
                      } else if (value == 'delete') {
                        await _db.deleteRoom(roomId);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Sửa tên')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa phòng')),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(
                                  roomId: roomId,
                                  roomName: room['name'],
                                  darkMode: darkMode,
                                  fontSize: fontSize,
                                )));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final roomName = await showDialog<String>(
            context: context,
            builder: (_) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Tạo phòng mới'),
                content: TextField(controller: controller),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy')),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: const Text('Tạo')),
                ],
              );
            },
          );
          if (roomName != null && roomName.isNotEmpty) {
            await _db.createRoom(roomName);
          }
        },
      ),
    );
  }
}
