import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartnerChatHeader extends StatelessWidget {
  const PartnerChatHeader({
    super.key,
    required this.isConnected,
    required this.partnerName,
    required this.partnerAvatar,
  });

  final bool isConnected;
  final String partnerName;
  final String partnerAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: partnerAvatar.isEmpty
                    ? null
                    : NetworkImage(partnerAvatar),
                child: partnerAvatar.isEmpty
                    ? const Icon(Icons.person, color: Color(0xFFA03B56))
                    : null,
              ),
              Positioned(
                right: -1,
                bottom: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF42C66D)
                        : const Color(0xFFB6BBC2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName.isEmpty ? 'Nguoi ay' : partnerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'Dang hoat dong' : 'Khong hoat dong',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6D7278),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_outlined),
            color: const Color(0xFFA03B56),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_outlined),
            color: const Color(0xFFA03B56),
          ),
        ],
      ),
    );
  }
}
