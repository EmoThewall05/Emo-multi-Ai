import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import '../models/ai_provider.dart';
import '../supabase_config.dart';

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

Future<void> showAddKeyDialog(BuildContext context, AiProvider provider) async {
  final controller = TextEditingController();
  final userId = supabase.auth.currentUser?.id;
  bool obscure = true;
  bool saving = false;
  String? error;
  String? existingKeyPreview;

  if (userId == null) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('Sign in required', style: TextStyle(color: Colors.white)),
        content: const Text('Please sign in to add an API key.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    return;
  }

  // Check for an existing key so we can show it is already set.
  try {
    final row = await supabase
        .from('user_api_keys')
        .select('encrypted_key')
        .eq('user_id', userId)
        .eq('provider_id', provider.id)
        .maybeSingle();
    if (row != null) {
      final decrypted = KeyEncryptor.decrypt(row['encrypted_key'] as String, userId);
      existingKeyPreview = decrypted.length > 8
          ? '${decrypted.substring(0, 4)}••••${decrypted.substring(decrypted.length - 4)}'
          : '••••••••';
    }
  } catch (_) {
    // no existing key or decrypt failed silently — treat as none
  }

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12121F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: Color(provider.colorValue)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(provider.name, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existingKeyPreview != null) ...[
                Text('Current key: $existingKeyPreview',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: controller,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste your ${provider.name} API key',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38, size: 18),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 6),
              const Text(
                'Your key is encrypted before it leaves your device.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          actions: [
            if (existingKeyPreview != null)
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        try {
                          await supabase
                              .from('user_api_keys')
                              .delete()
                              .eq('user_id', userId)
                              .eq('provider_id', provider.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() {
                            error = 'Could not remove key.';
                            saving = false;
                          });
                        }
                      },
                child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final value = controller.text.trim();
                      if (value.isEmpty) {
                        setState(() => error = 'Please enter a key.');
                        return;
                      }
                      setState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final encrypted = KeyEncryptor.encrypt(value, userId);
                        await supabase.from('user_api_keys').upsert({
                          'user_id': userId,
                          'provider_id': provider.id,
                          'encrypted_key': encrypted,
                          'updated_at': DateTime.now().toIso8601String(),
                        }, onConflict: 'user_id,provider_id');
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setState(() {
                          error = 'Could not save key. Try again.';
                          saving = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              child: saving
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ),
  );
}
