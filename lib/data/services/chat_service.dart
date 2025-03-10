import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatService {
  final Box _chatBox = Hive.box('chatBox');
  final _uuid = const Uuid();

  // Send a message
  Future<ChatMessage> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      // Create a new message
      final message = ChatMessage(
        id: _uuid.v4(),
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        type: MessageType.sent,
      );

      // Save message to local storage
      await _saveMessageToLocal(message);

      // In a real app, you would send the message to a backend

      return message;
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }

  // Get messages between two users
  List<ChatMessage> getMessages(String userId, String buddyId) {
    try {
      final messagesData = _chatBox.get('messages_${userId}_$buddyId') ?? [];

      return (messagesData as List)
          .map((data) => ChatMessage.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      print('Get messages error: $e');
      return [];
    }
  }

  // Get all buddies the user has chatted with
  List<String> getBuddyIds(String userId) {
    try {
      // Get all keys in the chat box that start with 'messages_$userId'
      final keys = _chatBox.keys
          .where((key) => key.toString().startsWith('messages_$userId'))
          .toList();

      // Extract buddy IDs from the keys
      return keys
          .map((key) => key.toString().split('_').last)
          .toSet()
          .toList();
    } catch (e) {
      print('Get buddy IDs error: $e');
      return [];
    }
  }

  // Save message to local storage
  Future<void> _saveMessageToLocal(ChatMessage message) async {
    final chatKey = 'messages_${message.senderId}_${message.receiverId}';
    final existingMessages = _chatBox.get(chatKey) ?? [];

    existingMessages.add(message.toJson());
    await _chatBox.put(chatKey, existingMessages);
  }
}