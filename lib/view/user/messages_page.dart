import 'package:flutter/material.dart';

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cChip = Color(0xFFF0EEE9);

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      appBar: AppBar(
        backgroundColor: _cBg,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            Text(
              '3 conversations',
              style: TextStyle(fontSize: 12, color: _cMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _cInk),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search conversations',
              hintStyle: const TextStyle(color: _cMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: _cMuted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _cBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _cBorder),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Conversation 1 (Unread)
          _MessageTile(
            initials: 'JL',
            name: 'Jamie Lee',
            time: '10:32',
            item: 'Oak study desk',
            message: '5:30 PM works for me!',
            isUnread: true,
            imageUrl: 'https://via.placeholder.com/50', // ใส่รูปจริงที่นี่
          ),

          // Conversation 2
          _MessageTile(
            initials: 'NP',
            name: 'Noah Park',
            time: 'Yesterday',
            item: 'Acoustic guitar',
            message: 'I can hold it until tomorrow.',
            imageUrl: 'https://via.placeholder.com/50',
          ),

          // Conversation 3
          _MessageTile(
            initials: 'AS',
            name: 'Alex Smith',
            time: 'May 18',
            item: 'City bike',
            message: 'Thanks again!',
            imageUrl: 'https://via.placeholder.com/50',
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final String initials, name, time, item, message, imageUrl;
  final bool isUnread;

  const _MessageTile({
    required this.initials,
    required this.name,
    required this.time,
    required this.item,
    required this.message,
    required this.imageUrl,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _cChip,
            radius: 24,
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.w600, color: _cInk),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isUnread) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: _cInk,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 11, color: _cMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item,
                  style: const TextStyle(fontSize: 12, color: _cMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    color: isUnread ? _cInk : _cMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
