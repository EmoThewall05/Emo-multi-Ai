import '../models/ai_provider.dart';
import '../data/provider_data.dart';

/// Attempts to identify which AI provider an API key belongs to,
/// based on known key prefix patterns. Returns null if no match is found,
/// in which case the caller should fall back to manual provider selection.
class KeyDetector {
  static AiProvider? detect(String key) {
    final trimmed = key.trim();

    final patterns = <String, bool Function(String)>{
      'anthropic': (k) => k.startsWith('sk-ant-'),
      'openai': (k) => k.startsWith('sk-proj-') || (k.startsWith('sk-') && !k.startsWith('sk-ant-') && !k.startsWith('sk-or-')),
      'gemini': (k) => k.startsWith('AIza'),
      'grok': (k) => k.startsWith('xai-'),
      'mistral': (k) => k.length == 32 && RegExp(r'^[a-zA-Z0-9]+\$').hasMatch(k),
      'deepseek': (k) => k.startsWith('sk-') && k.length > 40 && k.contains('deepseek'),
      'qwen': (k) => k.startsWith('sk-') && k.contains('dashscope'),
      'copilot': (k) => k.startsWith('ghp_') || k.startsWith('gho_'),
      'perplexity': (k) => k.startsWith('pplx-'),
    };

    // OpenRouter and other aggregators use a recognizable prefix even
    // though they are not in the fixed provider list; treat them as
    // matching their closest underlying category via a generic fallback.
    if (trimmed.startsWith('sk-or-')) {
      // OpenRouter key — not a fixed single provider, but we still try
      // to find a reasonable existing entry so the UI has something to
      // show; otherwise return null and let the user pick manually.
      return null;
    }

    for (final entry in patterns.entries) {
      if (entry.value(trimmed)) {
        try {
          return aiProviders.firstWhere((p) => p.id == entry.key);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }
}
