import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/claude_chat_provider.dart';
import '../../../data/models/chat_message.dart';
import '../../../widgets/chat_bubble.dart';

class BuddyChatScreen extends StatefulWidget {
  const BuddyChatScreen({Key? key}) : super(key: key);
  @override
  State<BuddyChatScreen> createState() => _BuddyChatScreenState();
}

class _BuddyChatScreenState extends State<BuddyChatScreen> {
  final TextEditingController _messageController = TextEditingController();  // テキスト入力で画面変化を付ける
  final ScrollController _scrollController = ScrollController();  // スクロール可能なウィジェット（ListView、GridView、SingleChildScrollViewなど）を制御するためのクラス

  @override
  void initState() {
    super.initState();

    // 必要に応じて初期メッセージをロードする
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {  // ウィジットが画面から削除されるときに呼び出される　リソース開放、リスナー解除
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // プロバイダーからメッセージを取得
    final chatProvider = Provider.of<ClaudeChatProvider>(context, listen: false);

    // メッセージがある場合は、画面を最下部にスクロール
    if (chatProvider.messages.isNotEmpty) {
      // UIの更新が完了した後にスクロール処理を実行
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
  // sendボタンを押したら実行
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // プロバイダーを取得してメッセージを送信する
    final chatProvider = Provider.of<ClaudeChatProvider>(context, listen: false);
    chatProvider.sendMessage(message);

    _messageController.clear();

    // メッセージを送信した後、一番下までスクロールします
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOURBUDDY'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Consumer<ClaudeChatProvider>(
        builder: (context, chatProvider, child) {
          // 新しいメッセージが到着したときにスクロールするためのリスナーを追加します
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          return Column(
            children: [
              // チャットメッセージ
              Expanded(
                child: chatProvider.isLoading && chatProvider.messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ChatBubble(message: message);
                  },
                ),
              ),

              // AI応答を待機しているときの読み込みインジケーター
              if (chatProvider.isLoading && chatProvider.messages.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),

              // エラーメッセージ（ある場合）
              if (chatProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.red.shade100,
                  width: double.infinity,
                  child: Text(
                    'Error: ${chatProvider.error}', // エラーテキスト
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              // メッセージや写真などのインプット部分
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: () {
                        // 画像アップロード機能はここに配置します
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () {
                        // カメラ機能はここに配置します
                      },
                    ),
                    // メッセージ入力部分
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'メッセージを入力...',
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}