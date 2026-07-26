import 'package:flutter/material.dart';
import '../data/provider_data.dart';
import '../models/ai_provider.dart';

class VaultCardGrid extends StatelessWidget {
  final Function(AiProvider) onAddKey;
  const VaultCardGrid({super.key, required this.onAddKey});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: aiProviders.length + 1,
      itemBuilder: (context, index) {
        if (index == aiProviders.length) {
          return _AddKeyCard(onTap: () {});
        }
        final provider = aiProviders[index];
        return _ProviderCard(provider: provider, onTap: () => onAddKey(provider));
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(getProviderIcon(provider), color: color, size: 28),
            const SizedBox(height: 10),
            Text(provider.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
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
      child: DottedBorderBox(
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 30),
              SizedBox(height: 8),
              Text('ADD NEW KEY', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.6), style: BorderStyle.solid, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
