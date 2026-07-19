import 'package:flutter/material.dart';

class EmptyChatPlaceholder extends StatelessWidget {
  const EmptyChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Hãy gửi tin nhắn đầu tiên cho người ấy.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF8A8F96)),
        ),
      ),
    );
  }
}
