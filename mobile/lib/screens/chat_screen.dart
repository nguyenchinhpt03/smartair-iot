import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:ui';

class _Message {
  final String text;
  final bool isUser;
  final DateTime time;
  _Message(this.text, this.isUser) : time = DateTime.now();
}

class ChatScreen extends StatefulWidget {
  final String deviceId;
  const ChatScreen({super.key, required this.deviceId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[];
  bool _loading = false;

  // Aurora moving background controller
  late AnimationController _auroraController;
  late Animation<double> _auroraAnim;

  static const _quickQuestions = [
    {
      'q': 'Hôm nay không khí thế nào?',
      'color': Color(0xFFE8F5E9),
      'text': Color(0xFF2E7D32)
    }, // Pastel green
    {
      'q': 'Có nên mở cửa sổ không?',
      'color': Color(0xFFFFF3E0),
      'text': Color(0xFFEF6C00)
    }, // Pastel orange
    {
      'q': 'Gợi ý điểm du lịch trong lành cuối tuần cho gia đình',
      'color': Color(0xFFE0F7FA),
      'text': Color(0xFF00695C)
    }, // Teal
    {
      'q': 'Cuối tuần đi đâu tránh bụi mịn?',
      'color': Color(0xFFEDE7F6),
      'text': Color(0xFF512DA8)
    }, // Deep Purple
    {
      'q': 'Khí nào đang cao nhất?',
      'color': Color(0xFFE3F2FD),
      'text': Color(0xFF1565C0)
    }, // Pastel blue
    {
      'q': 'Bụi mịn có nguy hiểm không?',
      'color': Color(0xFFF3E5F5),
      'text': Color(0xFF6A1B9A)
    }, // Pastel purple
  ];

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _auroraAnim = CurvedAnimation(
      parent: _auroraController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _auroraController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    text = text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_Message(text, true));
      _loading = true;
    });
    _scrollDown();

    final answer = await ApiService().chat(widget.deviceId, text);

    if (mounted) {
      setState(() {
        _messages.add(_Message(answer, false));
        _loading = false;
      });
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _bubble(_Message msg) {
    final bubbleColor = msg.isUser
        ? const Color(0xFF00796B).withOpacity(0.9)
        : Colors.white.withOpacity(0.7);

    final border = Border.all(
      color: msg.isUser
          ? const Color(0xFF00796B).withOpacity(0.3)
          : Colors.white.withOpacity(0.4),
      width: 1.5,
    );

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          border: border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(3, 3), // Neo-Brutalism shadow
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: msg.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color:
                          msg.isUser ? Colors.white : const Color(0xFF263238),
                      fontSize: 14.5,
                      fontWeight:
                          msg.isUser ? FontWeight.w500 : FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: msg.isUser ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI SmartAir',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.85),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa hội thoại',
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _auroraAnim,
        builder: (context, child) {
          // Calculate animated aurora gradient alignments
          final double t = _auroraAnim.value;
          final beginAlign = Alignment(
            lerpDouble(-0.8, 0.8, t)!,
            lerpDouble(-1.0, -0.6, t)!,
          );
          final endAlign = Alignment(
            lerpDouble(0.8, -0.8, t)!,
            lerpDouble(0.6, 1.0, t)!,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: beginAlign,
                end: endAlign,
                colors: const [
                  Color(0xFFE0F7FA), // Mint Aurora
                  Color(0xFFEDE7F6), // Lavender Aurora
                  Color(0xFFFFF3E0), // Peach Aurora
                ],
              ),
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            // Quick suggestions pastel scrolling chips
            Container(
              height: 52,
              color: Colors.white.withOpacity(0.7),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _quickQuestions.length,
                itemBuilder: (_, i) {
                  final item = _quickQuestions[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(item['q'] as String),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: item['text'] as Color,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      side: BorderSide(
                          color: (item['text'] as Color).withOpacity(0.3),
                          width: 1.5),
                      onPressed: () => _send(item['q'] as String),
                      backgroundColor: item['color'] as Color,
                      elevation: 0,
                      shadowColor: Colors.black12,
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            // Chat messages body
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00796B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome,
                                  size: 40, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Chào bạn! Tôi là Trợ lý AI SmartAir',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF263238)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hãy hỏi tôi bất cứ câu hỏi nào về sức khỏe, bảo vệ đường hô hấp và cách kiểm soát không khí xung quanh bạn.',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          // Typing status (AI is thinking...)
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00796B)),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'AI đang phân tích...',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54),
                                  )
                                ],
                              ),
                            ),
                          );
                        }
                        return _bubble(_messages[i]);
                      },
                    ),
            ),

            // Input panel (Glassmorphic)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 12,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                border: const Border(
                    top: BorderSide(color: Colors.black12, width: 1)),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _send,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF263238)),
                          decoration: InputDecoration(
                            hintText: 'Nhập câu hỏi của bạn...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold),
                            fillColor: Colors.white.withOpacity(0.6),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide:
                                  const BorderSide(color: Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide:
                                  const BorderSide(color: Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: const BorderSide(
                                  color: Color(0xFF00796B), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                        onPressed: _loading ? null : () => _send(_ctrl.text),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          padding: const EdgeInsets.all(12),
                          elevation: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
