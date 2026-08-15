import 'dart:math';
import 'package:flutter/material.dart';
import '../data/provider_data.dart';
import '../models/ai_provider.dart';

/// Global keys so the sidebar can scroll to a given category section.
final Map<String, GlobalKey> categorySectionKeys = {
  'text': GlobalKey(),
  'image': GlobalKey(),
  'video': GlobalKey(),
};

const Map<String, String> categoryTitles = {
  'text': 'Coding & Text AI',
  'image': 'Image Engines',
  'video': 'Video Studio & Reels',
};

class VaultCardGrid extends StatefulWidget {
  final Function(AiProvider) onAddKey;
  final Function(AiProvider) onOpenChat;
  const VaultCardGrid({
    super.key,
    required this.onAddKey,
    required this.onOpenChat,
  });

  @override
  State<VaultCardGrid> createState() => _VaultCardGridState();
}

class _VaultCardGridState extends State<VaultCardGrid> {
  static const _categories = ['text', 'image', 'video'];
  late final List<AiProvider> _randomMix;
  late final Map<String, List<AiProvider>> _categoryProviders;

  @override
  void initState() {
    super.initState();
    // Shuffled once per app session (widget created fresh only on app restart).
    _randomMix = List<AiProvider>.from(aiProviders)..shuffle(Random(7));
    _categoryProviders = {
      for (final cat in _categories)
        cat: (List<AiProvider>.from(
                aiProviders.where((p) => p.category == cat))
              ..shuffle())
            .take(5)
            .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            'All Engines',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        _ProviderGrid(
          providers: _randomMix,
          onAddKey: widget.onAddKey,
          onOpenChat: widget.onOpenChat,
        ),
        ..._categories.map((cat) {
          return Container(
            key: categorySectionKeys[cat],
            child: _CategorySection(
              title: categoryTitles[cat]!,
              providers: _categoryProviders[cat]!,
              onAddKey: widget.onAddKey,
              onOpenChat: widget.onOpenChat,
            ),
          );
        }),

        // bottom padding so the last section isn't flush with screen edge
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<AiProvider> providers;
  final Function(AiProvider) onAddKey;
  final Function(AiProvider) onOpenChat;

  const _CategorySection({
    required this.title,
    required this.providers,
    required this.onAddKey,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        _ProviderGrid(
          providers: providers,
          onAddKey: onAddKey,
          onOpenChat: onOpenChat,
        ),
      ],
    );
  }
}

class _ProviderGrid extends StatelessWidget {
  final List<AiProvider> providers;
  final Function(AiProvider) onAddKey;
  final Function(AiProvider) onOpenChat;
  const _ProviderGrid({
    required this.providers,
    required this.onAddKey,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _ProviderCard(
          provider: provider,
          onTapChat: () => onOpenChat(provider),
          onTapKey: () => onAddKey(provider),
        );
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final AiProvider provider;
  final VoidCallback onTapChat;
  final VoidCallback onTapKey;
  const _ProviderCard({
    required this.provider,
    required this.onTapChat,
    required this.onTapKey,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(provider.colorValue);
    return GestureDetector(
      onTap: onTapChat,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(getProviderIcon(provider), color: color, size: 20),
                const SizedBox(height: 6),
                Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ACTIVE',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
            // Key icon — tap to add/manage this provider's API key
            // without opening the chat screen.
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onTapKey,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    size: 12,
                    color: Colors.white70,
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
