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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((cat) {
        final providers = aiProviders.where((p) => p.category == cat).toList();
        return Container(
          key: categorySectionKeys[cat],
          child: _CategorySection(
            title: categoryTitles[cat]!,
            providers: providers,
            onAddKey: onAddKey,
            showAddCard: cat == categories.last,
          ),
        );
      }).toList(),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<AiProvider> providers;
  final Function(AiProvider) onAddKey;
  final bool showAddCard;

  const _CategorySection({
    required this.title,
    required this.providers,
    required this.onAddKey,
    this.showAddCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = providers.length + (showAddCard ? 1 : 0);
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == providers.length && showAddCard) {
              return _AddKeyCard(onTap: () {});
            }
            final provider = providers[index];
            return _ProviderCard(provider: provider, onTap: () => onAddKey(provider));
          },
        ),
      ],
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

class _AddKeyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddKeyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.6), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 20),
              SizedBox(height: 4),
              Text('ADD NEW', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 9), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
