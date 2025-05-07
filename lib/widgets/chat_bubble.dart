import 'package:flutter/material.dart';
import '../../data/models/chat_message.dart';
import '../../core/theme.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: message.isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUserMessage)
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 20),
            ),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUserMessage
                    ? AppTheme.chatBubbleGreen
                    : AppTheme.chatBubbleBeige,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUserMessage ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUserMessage
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (message.isUserMessage)
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 20),
            ),
        ],
      ),
    );
  }
}