import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_app/screens/chat_screen.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Colors and alignment change based on the sender
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? const Color(0xFF673AB7) : Colors.white; // Purple for user, white for AI
    final textColor = message.isUser ? Colors.white : Colors.black87;
    final padding = message.isUser ? const EdgeInsets.only(left: 40) : const EdgeInsets.only(right: 40);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0).add(padding),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
              bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // New: Display the image if it was sent by the user
              if (message.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Note: Since we are using a mock placeholder image, 
                  // this may not display a valid image.
                  child: Image.memory(
                    message.imageBytes!,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Image Placeholder',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        )
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Display the text message
              message.isUser
                  ? Text(
                      message.text,
                      style: TextStyle(color: textColor, fontSize: 16),
                    )
                  // Use MarkdownBody for AI responses to handle formatting
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: textColor, fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple 'typing' indicator with pulsating dots
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('AI is typing', style: TextStyle(color: Colors.black54)),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}