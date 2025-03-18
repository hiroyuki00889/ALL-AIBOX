import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/claude_api_service.dart';
import '../../data/models/chat_message.dart';

class ClaudeChatProvider extends ChangeNotifier {
  final ClaudeApiService _apiService;
  final _uuid = Uuid(); // メッセージのユニークID生成用

  // 状態変数
  bool isLoading = false;
  String? error;
  List<ChatMessage> messages = [];

  // コンストラクタ　-　依存するサービスを注入
  ClaudeChatProvider(this._apiService);

  // APIに送信するためのメッセージ履歴形式に変換
  List<Map<String, dynamic>> get _messageHistory {
    return messages.map((msg){
      return {
        'role': msg.isUserMessage ? 'user' : 'assistant',
        'content': msg.content,
      };
    }).toList();
  }

  // メッセージを送信し、応答を取得する関数
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      // ローディング状態の開始
      isLoading = true;
      error = null;
      notifyListeners();

      // 新しいユーザーメッセージを追加
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: text,
        isuserMessage: true,
        timestamp: DateTime.now(),
      );
      messages.add(userMessage);
      notifyListeners();

      // APIにメッセージを送信して応答を取得
      final response = await _apiService.sendMessage(text, _messageHistory);

      // AIの応答メッセージを追加
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        content: response,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      messages.add(assistantMessage);

    } catch (e) {
      // エラー状態の設定
      error = e.toString();
    } finally {
      // ローディング状態の終了
      isLoading = false;
      notifyListeners();
    }
  }

  // 会話履歴をクリアする関数
  void clearChat() {
    messages.clear();
    error = null;
    notifyListeners();
  }
}