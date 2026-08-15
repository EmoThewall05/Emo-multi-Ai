import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_provider.dart';
import 'key_encryptor.dart';

/// Simple chat message model shared with the UI layer.
class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  ChatMessage({required this.role, required this.text});
}

class AiChatService {
  static final SupabaseClient _supa = Supabase.instance.client;

  // ---------------------------------------------------------------------
  // API KEY STORAGE (Supabase table: user_api_keys)
  // columns: user_id (uuid), provider_id (text), encrypted_key (text), updated_at (timestamptz)
  // ---------------------------------------------------------------------

  static Future<String?> fetchApiKey(String providerId) async {
    final user = _supa.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await _supa
          .from('user_api_keys')
          .select('encrypted_key')
          .eq('user_id', user.id)
          .eq('provider_id', providerId)
          .maybeSingle();

      if (row == null || row['encrypted_key'] == null) return null;

      return KeyEncryptor.decrypt(row['encrypted_key'] as String, user.id);
    } catch (e) {
      // ignore: avoid_print
      print('fetchApiKey failed for $providerId: $e');
      return null;
    }
  }

  static Future<void> saveApiKey(String providerId, String plainKey) async {
    final user = _supa.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final encrypted = KeyEncryptor.encrypt(plainKey, user.id);

    await _supa.from('user_api_keys').upsert({
      'user_id': user.id,
      'provider_id': providerId,
      'encrypted_key': encrypted,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,provider_id');
  }

  static Future<void> removeApiKey(String providerId) async {
    final user = _supa.auth.currentUser;
    if (user == null) return;
    await _supa
        .from('user_api_keys')
        .delete()
        .eq('user_id', user.id)
        .eq('provider_id', providerId);
  }

  // ---------------------------------------------------------------------
  // SEND MESSAGE — routes to the correct provider's REST API
  // ---------------------------------------------------------------------

  static Future<String> sendMessage({
    required AiProvider provider,
    required String apiKey,
    required List<ChatMessage> history,
    required String message,
  }) async {
    final messages = [
      ...history.map((m) => {'role': m.role, 'content': m.text}),
      {'role': 'user', 'content': message},
    ];

    switch (provider.id) {
      case 'gemini':
        return _callGemini(apiKey, messages);
      case 'anthropic':
        return _callAnthropic(apiKey, messages);
      case 'openai':
      case 'grok':
      case 'deepseek':
      case 'mistral':
      case 'qwen':
      case 'kimi':
      case 'copilot':
      case 'llama':
        return _callOpenAiCompatible(provider.id, apiKey, messages);
      case 'perplexity':
        return _callPerplexity(apiKey, messages);
      default:
        throw Exception('${provider.name} chat is not supported yet.');
    }
  }

  // ---------------------------------------------------------------------
  // PROVIDER IMPLEMENTATIONS
  // ---------------------------------------------------------------------

  /// Google Gemini — generateContent REST endpoint.
  static Future<String> _callGemini(
      String apiKey, List<Map<String, String>> messages) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    final contents = messages
        .map((m) => {
              'role': m['role'] == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m['content']}
              ],
            })
        .toList();

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    );

    _checkOk(res, 'Gemini');
    final data = jsonDecode(res.body);
    return data['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString() ??
        '(empty response)';
  }

  /// Anthropic Claude — Messages API.
  static Future<String> _callAnthropic(
      String apiKey, List<Map<String, String>> messages) async {
    final uri = Uri.parse('https://api.anthropic.com/v1/messages');

    final res = await http.post(
      uri,
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

    _checkOk(res, 'Anthropic');
    final data = jsonDecode(res.body);
    final blocks = data['content'] as List?;
    if (blocks == null || blocks.isEmpty) return '(empty response)';
    return blocks
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n');
  }

  /// Perplexity — OpenAI-compatible chat completions.
  static Future<String> _callPerplexity(
      String apiKey, List<Map<String, String>> messages) async {
    return _postOpenAiStyle(
      uri: Uri.parse('https://api.perplexity.ai/chat/completions'),
      apiKey: apiKey,
      model: 'sonar',
      messages: messages,
      label: 'Perplexity',
    );
  }

  /// OpenAI and every OpenAI-compatible provider (Grok, DeepSeek, Mistral,
  /// Qwen, Kimi, Copilot, Llama endpoints all speak this same schema).
  static Future<String> _callOpenAiCompatible(String providerId,
      String apiKey, List<Map<String, String>> messages) async {
    final config = _openAiCompatibleConfig[providerId]!;
    return _postOpenAiStyle(
      uri: Uri.parse(config.endpoint),
      apiKey: apiKey,
      model: config.model,
      messages: messages,
      label: config.label,
    );
  }

  static Future<String> _postOpenAiStyle({
    required Uri uri,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    required String label,
  }) async {
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'model': model, 'messages': messages}),
    );

    _checkOk(res, label);
    final data = jsonDecode(res.body);
    return data['choices']?[0]?['message']?['content']?.toString() ??
        '(empty response)';
  }

  static void _checkOk(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$label error ${res.statusCode}: ${res.body}');
    }
  }
}

/// Endpoint + default model for each OpenAI-schema-compatible provider.
class _OpenAiCompatConfig {
  final String endpoint;
  final String model;
  final String label;
  const _OpenAiCompatConfig(this.endpoint, this.model, this.label);
}

const Map<String, _OpenAiCompatConfig> _openAiCompatibleConfig = {
  'openai': _OpenAiCompatConfig(
      'https://api.openai.com/v1/chat/completions', 'gpt-4o', 'OpenAI'),
  'grok': _OpenAiCompatConfig(
      'https://api.x.ai/v1/chat/completions', 'grok-4', 'Grok'),
  'deepseek': _OpenAiCompatConfig(
      'https://api.deepseek.com/chat/completions', 'deepseek-chat', 'DeepSeek'),
  'mistral': _OpenAiCompatConfig(
      'https://api.mistral.ai/v1/chat/completions', 'mistral-large-latest', 'Mistral'),
  'qwen': _OpenAiCompatConfig(
      'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      'qwen-plus',
      'Qwen'),
  'kimi': _OpenAiCompatConfig(
      'https://api.moonshot.cn/v1/chat/completions', 'moonshot-v1-8k', 'Kimi'),
  'copilot': _OpenAiCompatConfig(
      'https://api.githubcopilot.com/chat/completions', 'gpt-4o', 'GitHub Copilot'),
  'llama': _OpenAiCompatConfig(
      'https://api.llama.com/v1/chat/completions', 'llama-4', 'Meta Llama'),
};
