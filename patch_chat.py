import os

# 1. New file: lib/services/key_encryptor.dart
os.makedirs("lib/services", exist_ok=True)
with open("lib/services/key_encryptor.dart", "w") as f:
    f.write('''import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

/// Simple symmetric encryption for API keys before they are stored in
/// Supabase. The key is derived from the user's own uid so it is not a
/// single shared secret hardcoded in the app.
class KeyEncryptor {
  static enc.Encrypter _encrypterFor(String userId) {
    final paddedKey = userId.padRight(32, '0').substring(0, 32);
    final key = enc.Key.fromUtf8(paddedKey);
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  static String encrypt(String plainText, String userId) {
    final iv = enc.IV.fromLength(16);
    final encrypter = _encrypterFor(userId);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return jsonEncode({'iv': iv.base64, 'data': encrypted.base64});
  }

  static String decrypt(String cipherJson, String userId) {
    final map = jsonDecode(cipherJson) as Map<String, dynamic>;
    final iv = enc.IV.fromBase64(map['iv'] as String);
    final encrypter = _encrypterFor(userId);
    return encrypter.decrypt64(map['data'] as String, iv: iv);
  }
}
''')
print("created lib/services/key_encryptor.dart")

# 2. New file: lib/services/ai_chat_service.dart
with open("lib/services/ai_chat_service.dart", "w") as f:
    f.write('''import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';
import '../supabase_config.dart';
import 'key_encryptor.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String text;
  ChatMessage({required this.role, required this.text});
}

/// Providers that don't have a simple direct REST chat-completions API
/// (need special hosting / no public consumer key), so we show a clear
/// message instead of pretending to call something that will 404.
const Set<String> _unsupportedChatProviders = {'llama', 'copilot'};

class AiChatService {
  /// Fetch + decrypt the stored API key for a provider. Returns null if
  /// no key has been saved yet.
  static Future<String?> fetchApiKey(String providerId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await supabase
          .from('user_api_keys')
          .select('encrypted_key')
          .eq('user_id', userId)
          .eq('provider_id', providerId)
          .maybeSingle();
      if (row == null) return null;
      return KeyEncryptor.decrypt(row['encrypted_key'] as String, userId);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasApiKey(String providerId) async {
    final key = await fetchApiKey(providerId);
    return key != null && key.isNotEmpty;
  }

  static Future<String> sendMessage({
    required AiProvider provider,
    required String apiKey,
    required List<ChatMessage> history,
    required String message,
  }) async {
    if (_unsupportedChatProviders.contains(provider.id)) {
      throw Exception(
          '${provider.name} does not have a direct chat API yet. Coming soon.');
    }

    switch (provider.id) {
      case 'gemini':
        return _callGemini(apiKey, history, message);
      case 'anthropic':
        return _callAnthropic(apiKey, history, message);
      case 'openai':
        return _callOpenAiCompatible(
          apiKey: apiKey,
          url: 'https://api.openai.com/v1/chat/completions',
          model: 'gpt-4o-mini',
          history: history,
          message: message,
        );
      case 'deepseek':
        return _callOpenAiCompatible(
          apiKey: apiKey,
          url: 'https://api.deepseek.com/chat/completions',
          model: 'deepseek-chat',
          history: history,
          message: message,
        );
      case 'mistral':
        return _callOpenAiCompatible(
          apiKey: apiKey,
          url: 'https://api.mistral.ai/v1/chat/completions',
          model: 'mistral-small-latest',
          history: history,
          message: message,
        );
      case 'qwen':
        return _callOpenAiCompatible(
          apiKey: apiKey,
          url: 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
          model: 'qwen-plus',
          history: history,
          message: message,
        );
      case 'grok':
        return _callOpenAiCompatible(
          apiKey: apiKey,
          url: 'https://api.x.ai/v1/chat/completions',
          model: 'grok-2-latest',
          history: history,
          message: message,
        );
      case 'perplexity':
        return _callOpenAiCompatible(
          apiKey: apiKey,
          url: 'https://api.perplexity.ai/chat/completions',
          model: 'sonar',
          history: history,
          message: message,
        );
      case 'kimi':
        return _callOpenAiCompatible(
          apiKey: apiKey,
          url: 'https://api.moonshot.cn/v1/chat/completions',
          model: 'moonshot-v1-8k',
          history: history,
          message: message,
        );
      default:
        throw Exception('${provider.name} is not wired up yet.');
    }
  }

  // ---- Gemini (different request shape) ----
  static Future<String> _callGemini(
      String apiKey, List<ChatMessage> history, String message) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    final contents = [
      ...history.map((m) => {
            'role': m.role == 'user' ? 'user' : 'model',
            'parts': [
              {'text': m.text}
            ],
          }),
      {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
    ];

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    );

    if (res.statusCode != 200) {
      throw Exception('Gemini error ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '(empty response)';
  }

  // ---- Anthropic (different request shape) ----
  static Future<String> _callAnthropic(
      String apiKey, List<ChatMessage> history, String message) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final messages = [
      ...history.map((m) => {'role': m.role, 'content': m.text}),
      {'role': 'user', 'content': message},
    ];

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-6',
        'max_tokens': 1024,
        'messages': messages,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Anthropic error ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data['content']?[0]?['text'] ?? '(empty response)';
  }

  // ---- Shared OpenAI-compatible chat/completions shape ----
  // Covers OpenAI, DeepSeek, Mistral, Qwen (DashScope), Grok (xAI),
  // Perplexity, and Kimi (Moonshot) they all speak this same format.
  static Future<String> _callOpenAiCompatible({
    required String apiKey,
    required String url,
    required String model,
    required List<ChatMessage> history,
    required String message,
  }) async {
    final messages = [
      ...history.map((m) => {'role': m.role, 'content': m.text}),
      {'role': 'user', 'content': message},
    ];

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'model': model, 'messages': messages}),
    );

    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data['choices']?[0]?['message']?['content'] ?? '(empty response)';
  }
}
''')
print("created lib/services/ai_chat_service.dart")

# 3. New file: lib/screens/chat_screen.dart
os.makedirs("lib/screens", exist_ok=True)
with open("lib/screens/chat_screen.dart", "w") as f:
    f.write('''import 'dart:math';
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
    final key = await AiChatService.fetchApiKey(widget.provider.id);
    if (!mounted) return;
    setState(() {
      _apiKey = key;
      _loadingKey = false;
      if (key == null) {
        _error = 'No API key saved for ${widget.provider.name} yet.';
      }
    });
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
              radius: 14,
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
                              'Say hi to ${widget.provider.name} 👋',
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
      decoration: const BoxDecoration(
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

/// Three bouncing dots shown while waiting for the AI response.
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
      duration: const Duration(milliseconds: 900),
    )..repeat();
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_controller.value - (i * 0.2)) % 1.0;
                final bounce = t < 0 ? 0.0 : sin(t * pi).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(0, -4 * bounce),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
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
''')
print("created lib/screens/chat_screen.dart")

# 4. Patch lib/widgets/add_key_dialog.dart
path = "lib/widgets/add_key_dialog.dart"
with open(path, "r") as f:
    content = f.read()

original_len = len(content)

# 4a. Replace the header (imports + KeyEncryptor class) with slim imports
old_header_start = "import 'dart:convert';"
old_class_end_marker = "}\n\nFuture<void> showAddKeyDialog"
header_start_idx = content.find(old_header_start)
class_end_idx = content.find(old_class_end_marker)
assert header_start_idx != -1, "Could not find old import block start"
assert class_end_idx != -1, "Could not find KeyEncryptor class end"

new_header = (
    "import 'package:flutter/material.dart';\n"
    "import '../models/ai_provider.dart';\n"
    "import '../supabase_config.dart';\n"
    "import '../screens/chat_screen.dart';\n"
    "import '../services/key_encryptor.dart';\n"
)
content = content[:header_start_idx] + new_header + content[class_end_idx + 1:]

# 4b. On successful save, navigate to ChatScreen instead of just popping
old_save_success = (
    "}, onConflict: 'user_id,provider_id');\n"
    "                if (ctx.mounted) Navigator.pop(ctx);"
)
new_save_success = (
    "}, onConflict: 'user_id,provider_id');\n"
    "                if (ctx.mounted) {\n"
    "                  Navigator.pop(ctx);\n"
    "                  Navigator.push(\n"
    "                    context,\n"
    "                    MaterialPageRoute(builder: (_) => ChatScreen(provider: provider)),\n"
    "                  );\n"
    "                }"
)
assert old_save_success in content, "Could not find save-success block to patch"
content = content.replace(old_save_success, new_save_success)

with open(path, "w") as f:
    f.write(content)
print(f"patched {path} ({original_len} -> {len(content)} chars)")

# 5. Patch lib/main.dart _onKeyTap to skip dialog when a key already exists
path = "lib/main.dart"
with open(path, "r") as f:
    content = f.read()

old_import_anchor = "import 'widgets/app_sidebar.dart';"
if old_import_anchor in content and "services/ai_chat_service.dart" not in content:
    content = content.replace(
        old_import_anchor,
        old_import_anchor + "\nimport 'screens/chat_screen.dart';\nimport 'services/ai_chat_service.dart';",
    )
else:
    # fallback: just make sure the imports exist near other relative imports
    if "services/ai_chat_service.dart" not in content:
        content = "import 'screens/chat_screen.dart';\nimport 'services/ai_chat_service.dart';\n" + content

old_tap = (
    "  void _onKeyTap(BuildContext context, AiProvider provider) {\n"
    "    showAddKeyDialog(context, provider);\n"
    "  }"
)
new_tap = (
    "  void _onKeyTap(BuildContext context, AiProvider provider) async {\n"
    "    final hasKey = await AiChatService.hasApiKey(provider.id);\n"
    "    if (!context.mounted) return;\n"
    "    if (hasKey) {\n"
    "      Navigator.push(\n"
    "        context,\n"
    "        MaterialPageRoute(builder: (_) => ChatScreen(provider: provider)),\n"
    "      );\n"
    "    } else {\n"
    "      showAddKeyDialog(context, provider);\n"
    "    }\n"
    "  }"
)
assert old_tap in content, "Could not find _onKeyTap to patch - check spacing manually"
content = content.replace(old_tap, new_tap)

with open(path, "w") as f:
    f.write(content)
print(f"patched {path}")

print("\\nAll done. Now run: flutter pub get && flutter run")
