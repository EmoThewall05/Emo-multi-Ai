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

class VaultCardGrid extends StatelessWidget {
  final Function(AiProvider) onAddKey;
  const VaultCardGrid({super.key, required this.onAddKey});

  @override
  Widget build(BuildContext context) {
    final categories = ['text', 'image', 'video'];
    final randomMix = List<AiProvider>.from(aiProviders)..shuffle(Random(7));

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
        _ProviderGrid(providers: randomMix, onTap: onAddKey),

        // --- DEBUG MARKER: confirms this code path runs ---
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          color: Colors.red,
          child: Text(
            'DEBUG: total providers=${aiProviders.length}, '
            'text=${aiProviders.where((p) => p.category == "text").length}, '
            'image=${aiProviders.where((p) => p.category == "image").length}, '
            'video=${aiProviders.where((p) => p.category == "video").length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        // --- END DEBUG MARKER ---

        ...categories.map((cat) {
          final providers = aiProviders.where((p) => p.category == cat).toList();
          final displayProviders = List<AiProvider>.from(providers)..shuffle();
          final limited = displayProviders.take(5).toList();
          return Container(
            key: categorySectionKeys[cat],
            child: _CategorySection(
              title: categoryTitles[cat]!,
              providers: limited,
              onTap: onAddKey,
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
  final Function(AiProvider) onTap;

  const _CategorySection({
    required this.title,
    required this.providers,
    required this.onTap,
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
        _ProviderGrid(providers: providers, onTap: onTap),
      ],
    );
  }
}

class _ProviderGrid extends StatelessWidget {
  final List<AiProvider> providers;
  final Function(AiProvider) onTap;
  const _ProviderGrid({required this.providers, required this.onTap});

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
        return _ProviderCard(provider: provider, onTap: () => onTap(provider));
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final AiProvider provider;
  final VoidCallback onTap;
  const _ProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(provider.colorValue);
    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF12121F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(getProviderIcon(provider), color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                provider.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 8)),
                ],
              )
            ],
          ),
      ),
    );
  }
}
