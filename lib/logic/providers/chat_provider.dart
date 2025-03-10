import 'package:flutter/material.dart';
import '../../data/services/chat_service.dart';
import '../../data/models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load messages between user and buddy
  Future<void> loadMessages(String userId, String buddyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = _chatService.getMessages(userId, buddyId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final message = await _chatService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );

      _messages.add(message);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get all buddies the user has chatted with
  List<String> getBuddyIds(String userId) {
    return _chatService.getBuddyIds(userId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}