import 'package:flutter/material.dart';
import '../models/ai_provider.dart';
import '../services/ai_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final AiProvider provider;
  const ChatScreen({super.key, required this.provider});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String? _apiKey;
  bool _loadingKey = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    try {
      final key = await AiChatService.fetchApiKey(widget.provider.id);
      if (!mounted) return;
      setState(() {
        _apiKey = key;
        _loadingKey = false;
        if (key == null) {
          _error = 'No API key saved for ${widget.provider.name} yet.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingKey = false;
        _error = 'Failed to load API key: $e';
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _apiKey == null || _sending) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _controller.clear();
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await AiChatService.sendMessage(
        provider: widget.provider,
        apiKey: _apiKey!,
        history: _messages.sublist(0, _messages.length - 1),
        message: text,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', text: reply));
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerColor = Color(widget.provider.colorValue);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: providerColor.withOpacity(0.2),
              child: Icon(Icons.smart_toy_outlined, color: providerColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(widget.provider.name,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Dot-pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: _DotBackgroundPainter(dotColor: providerColor.withOpacity(0.08)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (_loadingKey)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  )
                else
                  Expanded(
                    child: _messages.isEmpty && _error == null
                        ? Center(
                            child: Text(
                              'Say hi to ${widget.provider.name} ðŸ‘‹',
                              style: const TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length + (_sending ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length) {
                                return _TypingIndicator(color: providerColor);
                              }
                              final msg = _messages[index];
                              return _MessageBubble(
                                message: msg,
                                accentColor: providerColor,
                              );
                            },
                          ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                _InputBar(
                  controller: _controller,
                  enabled: _apiKey != null && !_sending,
                  accentColor: providerColor,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color accentColor;
  const _MessageBubble({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? accentColor.withOpacity(0.18) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUser ? accentColor.withOpacity(0.4) : Colors.white12,
          ),
        ),
        child: Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onSend;
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.accentColor,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: enabled ? 'Type a message...' : 'Add an API key first',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onSend : null,
            icon: Icon(Icons.send_rounded, color: enabled ? accentColor : Colors.white24),
          ),
        ],
      ),
    );
  }
}

/// A small butterfly whose wings flap while waiting for the AI response.
class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // wing flap angle: 0.0 (open) -> 1.0 (closed)
            final flap = _controller.value;
            return SizedBox(
              width: 26,
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left wing
                  Transform(
                    alignment: Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(flap * 1.1),
                    child: CustomPaint(
                      size: const Size(13, 20),
                      painter: _WingPainter(color: widget.color, isLeft: true),
                    ),
                  ),
                  // Right wing
                  Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(-flap * 1.1),
                    child: CustomPaint(
                      size: const Size(13, 20),
                      painter: _WingPainter(color: widget.color, isLeft: false),
                    ),
                  ),
                  // Body
                  Container(
                    width: 2.4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Paints a single butterfly wing (upper + lower lobe) as a soft teardrop.
class _WingPainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  const _WingPainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (isLeft) {
      path.moveTo(w, h * 0.5);
      path.quadraticBezierTo(w * 0.1, 0, 0, h * 0.32);
      path.quadraticBezierTo(w * 0.05, h * 0.5, w, h * 0.5);
      path.moveTo(w, h * 0.5);
      path.quadraticBezierTo(w * 0.15, h * 0.62, w * 0.08, h);
      path.quadraticBezierTo(w * 0.35, h * 0.7, w, h * 0.5);
    } else {
      path.moveTo(0, h * 0.5);
      path.quadraticBezierTo(w * 0.9, 0, w, h * 0.32);
      path.quadraticBezierTo(w * 0.95, h * 0.5, 0, h * 0.5);
      path.moveTo(0, h * 0.5);
      path.quadraticBezierTo(w * 0.85, h * 0.62, w * 0.92, h);
      path.quadraticBezierTo(w * 0.65, h * 0.7, 0, h * 0.5);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Subtle repeating dot-grid background for the chat screen.
class _DotBackgroundPainter extends CustomPainter {
  final Color dotColor;
  const _DotBackgroundPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 22.0;
    const radius = 1.4;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotBackgroundPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}
