import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = <_ChatMessage>[
      const _ChatMessage(
        author: 'Aanya',
        message: 'Sketch the parabola for x^2 - 4x + 3?',
        time: '10:21',
        isHost: false,
      ),
      const _ChatMessage(
        author: 'You',
        message: 'Start with the vertex form: (x-2)^2 - 1.',
        time: '10:22',
        isHost: true,
      ),
      const _ChatMessage(
        author: 'Liam',
        message: 'Got it. So the axis is x=2, right?',
        time: '10:23',
        isHost: false,
      ),
      const _ChatMessage(
        author: 'You',
        message: 'Exactly. Plot (2, -1) and move up 1 for zeros.',
        time: '10:24',
        isHost: true,
      ),
    ];

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final message = messages[index];
        final bubbleColor = message.isHost
            ? AppPalette.accent.withValues(alpha: 0.12)
            : AppPalette.wash;
        final borderColor = message.isHost
            ? AppPalette.accent.withValues(alpha: 0.35)
            : AppPalette.border;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    message.author,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.time,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppPalette.muted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Send a quick note...',
              filled: true,
              fillColor: AppPalette.wash,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppPalette.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.author,
    required this.message,
    required this.time,
    required this.isHost,
  });

  final String author;
  final String message;
  final String time;
  final bool isHost;
}
