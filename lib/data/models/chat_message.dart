class ChatMessage {
  final String    id;             // どの文章か判別
  final String    content;        // 中身の文章
  final bool      isUserMessage;  // trueならユーザー、falseならAI
  final DateTime  timestamp;      // 日時

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
  });

}