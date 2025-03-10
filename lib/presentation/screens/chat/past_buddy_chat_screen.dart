import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/chat_provider.dart';

class PastBuddyChatScreen extends StatefulWidget {
  const PastBuddyChatScreen({Key? key}) : super(key: key);

  @override
  State<PastBuddyChatScreen> createState() => _PastBuddyChatScreenState();
}

class _PastBuddyChatScreenState extends State<PastBuddyChatScreen> {
  late List<String> _buddyIds;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPastChats();
  }

  void _loadPastChats() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      setState(() {
        _buddyIds = chatProvider.getBuddyIds(authProvider.currentUser!.id);
        _isLoading = false;
      });
    } else {
      setState(() {
        _buddyIds = [];
        _isLoading = false;
      });
    }
  }

  void _openChat(String buddyId) {
    context.go('/chat?buddyId=$buddyId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('過去のチャット'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buddyIds.isEmpty
          ? const Center(child: Text('過去のチャットはありません'))
          : ListView.builder(
        itemCount: _buddyIds.length,
        itemBuilder: (context, index) {
          final buddyId = _buddyIds[index];
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('Buddy $buddyId'),
            subtitle: const Text('タップしてチャットを続ける'),
            onTap: () => _openChat(buddyId),
          );
        },
      ),
    );
  }
}