import 'package:flutter/material.dart';
import '../models/ai_provider.dart';
import '../data/provider_data.dart';
import '../utils/key_detector.dart';
import 'add_key_dialog.dart';

/// Entry point for the sidebar's "Add New Key" quick action.
/// Lets the user paste a key first; tries to auto-detect the provider
/// from the key format, then opens the normal per-provider add-key flow
/// pre-filled and pre-selected. Falls back to manual provider selection
/// if detection fails.
Future<void> showGenericAddKeyFlow(BuildContext context) async {
  final controller = TextEditingController();
  AiProvider? detected;
  bool tried = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12121F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Key', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste any provider API key. We\'ll try to detect which one it belongs to.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste your API key',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() => tried = false),
              ),
              if (tried) ...[
                const SizedBox(height: 10),
                if (detected != null)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Text('Detected: ${detected!.name}',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                    ],
                  )
                else
                  const Text(
                    'Could not auto-detect. Please select the provider manually below.',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
              ],
              if (tried && detected == null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: aiProviders.length,
                    itemBuilder: (ctx, i) {
                      final p = aiProviders[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(getProviderIcon(p), color: Color(p.colorValue), size: 18),
                        title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        onTap: () {
                          Navigator.pop(ctx);
                          showAddKeyDialog(context, p);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                final result = KeyDetector.detect(controller.text);
                setState(() {
                  detected = result;
                  tried = true;
                });
                if (result != null) {
                  Navigator.pop(ctx);
                  showAddKeyDialog(context, result);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              child: const Text('Detect', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ),
  );
}
