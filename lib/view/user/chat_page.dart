import 'package:flutter/material.dart';

// ไฟล์นี้ใช้งานได้ด้วยตัวเอง: หน้าแชทกับผู้ขาย (เปิดจากปุ่ม Chat with seller)

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
  static const mine = Color(0xFFE1E9F7); // ฟองข้อความของเรา
  static const online = Color(0xFF3F6B52);
}

class _Msg {
  const _Msg(this.text, this.time, {required this.mine});
  final String text;
  final String time;
  final bool mine;
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.sellerName,
    required this.productTitle,
    required this.price,
    this.urgent = false,
    this.imageUrl,
    this.ended = false,
  });

  final String sellerName;
  final String productTitle;
  final int price;
  final bool urgent;
  final String? imageUrl;

  /// true = แชทจบแล้ว (ออเดอร์เสร็จสิ้น/ยกเลิก) อ่านได้แต่พิมพ์ไม่ได้
  final bool ended;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // TODO: แทนด้วยข้อความจริงจาก API/WebSocket (ข้อความด้านล่างเป็นตัวอย่าง)
  final List<_Msg> _messages = [
    const _Msg('Hi! Is the desk still available?', '10:18', mine: true),
    const _Msg('Yes, it is! Are you in Maple Hall too?', '10:20', mine: false),
    const _Msg('I am. Could we meet in the lobby?', '10:21', mine: true),
    const _Msg('Sure — 5:30 PM works for me!', '10:32', mine: false),
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _nowLabel() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}';
  }

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    // TODO: ส่งข้อความไปที่ API แล้วค่อยเพิ่มเข้ารายการเมื่อสำเร็จ
    setState(() => _messages.add(_Msg(text, _nowLabel(), mine: true)));
    _inputCtrl.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildProductCard(),
            ),
            Expanded(child: _buildMessages()),
            widget.ended ? _buildEndedBar() : _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.sellerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                // TODO: เวลาตอบกลับเฉลี่ยจริงจาก API
                const Text(
                  'Usually replies in 10 min',
                  style: TextStyle(fontSize: 13, color: _C.muted),
                ),
              ],
            ),
          ),
          // จุดสถานะออนไลน์
          const SizedBox(
            width: 48,
            child: Icon(Icons.circle, size: 10, color: _C.online),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // กลับไปหน้าสินค้า (ถ้าเปิดแชทมาจากหน้าสินค้า)
        onTap: () => Navigator.maybePop(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: widget.imageUrl == null
                      ? Container(
                          color: _C.surface,
                          child: const Icon(Icons.image_outlined,
                              size: 22, color: _C.faint),
                        )
                      : Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _C.surface,
                            child: const Icon(Icons.image_outlined,
                                size: 22, color: _C.faint),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat about',
                      style: TextStyle(fontSize: 11, color: _C.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.productTitle} · ${widget.price} THB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.urgent) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: _C.ink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      // +1 สำหรับป้าย "Today" ด้านบน
      itemCount: _messages.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Center(
              child: Text(
                'Today',
                style: TextStyle(fontSize: 11, color: _C.faint),
              ),
            ),
          );
        }
        return _Bubble(msg: _messages[i - 1]);
      },
    );
  }

  Widget _buildEndedBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 16, color: _C.muted),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'This conversation has ended',
              style: TextStyle(fontSize: 13, color: _C.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _C.bg,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 14, color: _C.ink),
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: const TextStyle(color: _C.faint),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: _C.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: _C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: _C.ink, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _C.ink,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _send,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send_outlined, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Align(
      alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: msg.mine ? _C.mine : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: msg.mine ? null : Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: _C.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: const TextStyle(fontSize: 10, color: _C.muted),
            ),
          ],
        ),
      ),
    );
  }
}
