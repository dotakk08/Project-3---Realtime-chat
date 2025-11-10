import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Phòng chat
  Stream<DatabaseEvent> getRoomsStream() => _db.child('rooms').onValue;

  Future<void> createRoom(String name) async {
    final newRoomRef = _db.child('rooms').push();
    await newRoomRef.set({'name': name, 'createdAt': ServerValue.timestamp});
  }

  Future<void> updateRoomName(String roomId, String newName) async {
    await _db.child('rooms/$roomId').update({'name': newName});
  }

  Future<void> deleteRoom(String roomId) async {
    await _db.child('rooms/$roomId').remove();
  }

  // Tin nhắn
  Stream<DatabaseEvent> getMessagesStream(String roomId) =>
      _db.child('rooms/$roomId/messages').orderByChild('timestamp').onValue;

  Future<void> sendMessage({
    required String roomId,
    required String sender,
    required String text,
  }) async {
    final msgRef = _db.child('rooms/$roomId/messages').push();
    await msgRef.set({
      'sender': sender,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required String newText,
  }) async {
    await _db.child('rooms/$roomId/messages/$messageId').update({
      'text': newText,
      'edited': true,
    });
  }

  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    await _db.child('rooms/$roomId/messages/$messageId').remove();
  }
}
