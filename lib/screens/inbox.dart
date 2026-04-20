import 'package:flutter/material.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Title
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "COMMS ",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                TextSpan(
                  text: "LINK",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF39FF14),
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Color(0xFF39FF14),
                        blurRadius: 8,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Unread Message - Rider Alpha
          _buildMessageCard(
            context,
            name: "Rider Alpha (Host)",
            message: "Route change for tonight's sprint! We are meeting at the North Gate instead. Be sharp.",
            time: "JUST NOW",
            imageUrl:
                "https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-1.2.1&auto=format&fit=crop&w=256&q=80",
            isUnread: true,
            showOnlineStatus: true,
          ),
          const SizedBox(height: 12),

          // Read Message - Sunday Chill Group
          _buildMessageCard(
            context,
            name: "Sunday Chill Group",
            message: "Great ride everyone! Photos have been uploaded to the gallery.",
            time: "YESTERDAY",
            icon: Icons.group,
            isUnread: false,
          ),
          const SizedBox(height: 12),

          // System Message
          _buildMessageCard(
            context,
            name: "System Link",
            message: "You earned 500 PTS for completing the \"Gravel Grind\" event. Keep it pushing!",
            time: "2 DAYS AGO",
            icon: Icons.emoji_events,
            isSystem: true,
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context, {
    required String name,
    required String message,
    required String time,
    String? imageUrl,
    IconData? icon,
    bool isUnread = false,
    bool isSystem = false,
    bool showOnlineStatus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? const Color(0xFF39FF14).withOpacity(0.05)
            : const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? const Color(0xFF39FF14).withOpacity(0.3)
              : const Color(0xFFFFFFFF).withOpacity(0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              if (imageUrl != null)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(imageUrl),
                )
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isSystem
                      ? const Color(0xFF1F2937).withOpacity(0.8)
                      : const Color(0xFF27272A),
                  child: Icon(
                    icon,
                    color: isSystem ? const Color(0xFF60A5FA) : Colors.white54,
                    size: 16,
                  ),
                ),
              // Online status dot
              if (showOnlineStatus)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF050505),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSystem ? const Color(0xFF60A5FA) : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUnread
                            ? const Color(0xFF39FF14)
                            : const Color(0xFF71717A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUnread
                        ? const Color(0xFFD4D4D8)
                        : const Color(0xFFA1A1AA),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}