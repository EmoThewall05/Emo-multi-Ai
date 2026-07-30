import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ChefChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;

  ChefChatMessage({required this.text, required this.isUser, this.imagePath});
}

class ChefModeScreen extends StatefulWidget {
  const ChefModeScreen({super.key});

  @override
  State<ChefModeScreen> createState() => _ChefModeScreenState();
}

class _ChefModeScreenState extends State<ChefModeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChefChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _activeFilter;

  static const Color chefColor = Colors.pinkAccent;
  static const String _fridgeWorkerUrl =
      'https://chef-mode-fridge.meradivin.workers.dev';

  final List<Map<String, dynamic>> _quickFilters = const [
    {'label': '10 min', 'icon': Icons.timer_outlined},
    {'label': 'Date night', 'icon': Icons.favorite_outline},
    {'label': 'Gym diet', 'icon': Icons.fitness_center_outlined},
  ];

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (_quickFilters.any((f) => f['label'] == text)) {
      setState(() => _activeFilter = text);
    }

    setState(() {
      _messages.add(ChefChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // TODO: wire actual Chef Mode AI provider call (Claude/GPT-4o/Gemini/Grok)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChefChatMessage(
          text: 'Chef AI response placeholder for: "$text"',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    });
  }

  Future<void> _pickFridgePhoto() async {
    try {
      final XFile? picked = await showModalBottomSheet<XFile?>(
        context: context,
        backgroundColor: const Color(0xFF12121F),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: chefColor),
                title: const Text('Take photo', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final img = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop(img);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined, color: chefColor),
                title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final img = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop(img);
                },
              ),
            ],
          ),
        ),
      );

      if (picked == null) return;

      setState(() {
        _messages.add(ChefChatMessage(
          text: 'Fridge photo uploaded',
          isUser: true,
          imagePath: picked.path,
        ));
        _isLoading = true;
      });
      _scrollToBottom();

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_fridgeWorkerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          if (_activeFilter != null) 'filter': _activeFilter,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ingredients = (data['ingredients'] as List?)?.join(', ') ?? '';
        final recipe = data['recipe'] ?? 'Could not generate a recipe.';

        setState(() {
          _messages.add(ChefChatMessage(
            text: ingredients.isNotEmpty
                ? 'Detected: $ingredients\n\n$recipe'
                : recipe,
            isUser: false,
          ));
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add(ChefChatMessage(
            text: 'Fridge photo analysis failed. Please try again.',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(ChefChatMessage(
          text: 'Error analyzing fridge photo: $e',
          isUser: false,
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: chefColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_menu_outlined,
                  color: chefColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chef Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Claude / GPT-4o / Gemini / Grok',
                  style: TextStyle(color: chefColor, fontSize: 10.5),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: chefColor),
            tooltip: 'Fridge photo',
            onPressed: _pickFridgePhoto,
          ),
          IconButton(
            icon: const Icon(Icons.mic_none_outlined, color: chefColor),
            tooltip: 'Voice mode (coming soon)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice mode — coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = _quickFilters[index];
                  final isActive = _activeFilter == f['label'];
                  return ActionChip(
                    avatar: Icon(f['icon'] as IconData, size: 16, color: chefColor),
                    label: Text(f['label'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                    backgroundColor: isActive
                        ? chefColor.withOpacity(0.35)
                        : chefColor.withOpacity(0.12),
                    side: BorderSide(
                        color: chefColor.withOpacity(isActive ? 0.8 : 0.35)),
                    onPressed: () => _sendMessage(f['label'] as String),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ask for recipes, meal ideas, or tap a quick filter above',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 13.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? chefColor.withOpacity(0.18)
                                : const Color(0xFF12121F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: msg.isUser
                                  ? chefColor.withOpacity(0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: chefColor),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask Chef Mode...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF12121F),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: chefColor.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: chefColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: chefColor),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: chefColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.black),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
