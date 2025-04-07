import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/claude_chat_provider.dart';
import '../../../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();  // テキスト入力で画面変化を付ける
  final ScrollController _scrollController = ScrollController();  // スクロール可能なウィジェット（ListView、GridView、SingleChildScrollViewなど）を制御するためのクラス
  String kariUser = 'ドラえもん';

  void _sendMessage() {
    final message = _messageController.text.trim();   // 文章入力から前後の空白を取り除いく
    if (message.isEmpty) return;

    // プロバイダーを取得してメッセージを送信する
    final chatProvider = Provider.of<ClaudeChatProvider>(context, listen: false);
    chatProvider.sendMessage(message);

    _messageController.clear();
    context.go('/buddy_chat');
  }

  void _openSettings() {
    context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = kariUser/*authProvider.currentUser*/;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム画面'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'あなたのBuddy${user/*?.buddyPrefix ?? ''*/}に相談してみましょう',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
    decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(8),
    ),

              child: TextField(
                controller: _messageController,
                maxLines: null, // 複数行の入力を可能にする
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _sendMessage,
              style: AppTheme.primaryButtonStyle,
              child: const Text('相談する'),
            ),
          ),
          // News section
          Container(
            color: AppTheme.secondaryYellow.withOpacity(0.3),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'お知らせ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('機能改善についてのお知らせ'),
                  subtitle: const Text('2025.3.6'),
                  onTap: () {
                    // Handle tapping on news item
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('大阪開催についてのお知らせ'),
                  subtitle: const Text('2025.3.10'),
                  onTap: () {
                    // Handle tapping on news item
                  },
                ),
              ],
            ),
          ),
          // Ad banner
          Container(
            width: double.infinity,
            height: 50,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Text('広告'),
          ),
        ],
      ),
    );
  }
}