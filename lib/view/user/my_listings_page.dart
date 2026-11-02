import 'package:flutter/material.dart';

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cLink = Color(0xFF4A5C8F);

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

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
              'My listings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            Text(
              '3 active listings',
              style: TextStyle(fontSize: 12, color: _cMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _cInk),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _cInk),
            onPressed: () {}, // TODO: Action add listing
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('3', 'Active'),
                Container(width: 1, height: 40, color: _cBorder),
                _buildStat('8', 'Sold'),
                Container(width: 1, height: 40, color: _cBorder),
                _buildStat('124', 'Total views'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Listings
          _ListingItem(
            status: 'Urgent',
            statusColor: Colors.red.shade100,
            statusTextColor: Colors.red.shade700,
            views: '48 views',
            title: 'Oak study desk',
            subtitle: '\$45 · Maple Hall',
            imageUrl: 'https://via.placeholder.com/80', // ใส่รูปจริงที่นี่
          ),
          const Divider(color: _cBorder, height: 32),

          _ListingItem(
            status: 'Active',
            statusColor: Colors.green.shade100,
            statusTextColor: Colors.green.shade700,
            views: '31 views',
            title: 'Acoustic guitar',
            subtitle: '\$80 · Maple Hall',
            imageUrl: 'https://via.placeholder.com/80',
          ),
          const Divider(color: _cBorder, height: 32),

          _ListingItem(
            status: 'Free',
            statusColor: Colors.teal.shade100,
            statusTextColor: Colors.teal.shade700,
            views: '45 views',
            title: 'City bike',
            subtitle: '\$0 · Oak Residence',
            imageUrl: 'https://via.placeholder.com/80',
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _cMuted)),
      ],
    );
  }
}

class _ListingItem extends StatelessWidget {
  final String status, views, title, subtitle, imageUrl;
  final Color statusColor, statusTextColor;

  const _ListingItem({
    required this.status,
    required this.views,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.statusColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                  Text(
                    views,
                    style: const TextStyle(fontSize: 11, color: _cMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _cInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: _cMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Edit listing',
                    style: TextStyle(
                      fontSize: 12,
                      color: _cLink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: _cLink),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
