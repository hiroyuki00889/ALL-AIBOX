import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/claude_api_service.dart';
import '../../data/models/chat_message.dart';

class ClaudeChatProvider extends ChangeNotifier {   // ChangeNotifier:アプリケーションの状態をカプセル化,リスナーに変更を通知するnotifyListeners()の呼び出し
  final ClaudeApiService _claudeApiService;
  final _uuid = Uuid(); // メッセージのユニークID生成用
  // 状態変数
  bool isLoading = false;
  String? error;
  List<ChatMessage> messages = [];

  // コンストラクタ　-　依存するサービスを注入
  ClaudeChatProvider(this._claudeApiService);

  // APIに送信するためのメッセージ履歴形式に変換
  List<Map<String, dynamic>> get _messageHistory {
    return messages.map((msg){
      return {
        'role': msg.isUserMessage ? 'user' : 'assistant',
        'content': msg.content,
      };
    }).toList();
  }

  /* メッセージを送信し、応答を取得する関数
   * buddy_chat_screenのsendMessage()から
   */
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      // ローディング状態の開始
      isLoading = true;
      error = null;
      notifyListeners();  // このモデルをリッスンしているウィジェットに再びbuildするよう指示します

      // 新しいユーザーメッセージを追加
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: text,
        isUserMessage: true,
        timestamp: DateTime.now(),
      );
      messages.add(userMessage); //チャット履歴<ChatMessage>のリストに追加
      notifyListeners();  // このモデルをリッスンしているウィジェットに再びbuildするよう指示します

      // APIにメッセージを送信して応答を取得
      final response = await _claudeApiService.sendMessage(text, _messageHistory);

      // AIの応答メッセージを追加
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        content: response,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      messages.add(assistantMessage); //チャット履歴<ChatMessage>のリストに追加

    } catch (e) {
      // エラー状態の設定
      error = e.toString();
    } finally {
      // ローディング状態の終了
      isLoading = false;
      notifyListeners();  // このモデルをリッスンしているウィジェットに再びbuildするよう指示します
    }
  }

  // 会話履歴をクリアする関数
  void clearChat() {
    messages.clear();
    error = null;
    notifyListeners();  // このモデルをリッスンしているウィジェットに再びbuildするよう指示します
  }
}