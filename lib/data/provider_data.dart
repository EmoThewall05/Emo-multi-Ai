import 'package:flutter/material.dart';
import '../models/ai_provider.dart';

final List<AiProvider> aiProviders = [
  AiProvider(id: 'gemini', name: 'Gemini', category: 'text', colorValue: 0xFF4285F4),
  AiProvider(id: 'anthropic', name: 'Anthropic', category: 'text', colorValue: 0xFFD97757),
  AiProvider(id: 'openai', name: 'OpenAI', category: 'text', colorValue: 0xFF10A37F),
  AiProvider(id: 'grok', name: 'Grok / xAI', category: 'text', colorValue: 0xFF000000),
  AiProvider(id: 'perplexity', name: 'Perplexity', category: 'text', colorValue: 0xFF20808D),
  AiProvider(id: 'deepseek', name: 'DeepSeek', category: 'text', colorValue: 0xFF4D6BFE),
  AiProvider(id: 'mistral', name: 'Mistral', category: 'text', colorValue: 0xFFFF7000),
  AiProvider(id: 'qwen', name: 'Qwen', category: 'text', colorValue: 0xFF6236FF),
  AiProvider(id: 'copilot', name: 'GitHub Copilot', category: 'text', colorValue: 0xFF8957E5),
  AiProvider(id: 'llama', name: 'Meta Llama', category: 'text', colorValue: 0xFF0668E1),
  AiProvider(id: 'kimi', name: 'Kimi', category: 'text', colorValue: 0xFF6B5CE7),
  AiProvider(id: 'midjourney', name: 'Midjourney', category: 'image', colorValue: 0xFF000000),
  AiProvider(id: 'ideogram', name: 'Ideogram', category: 'image', colorValue: 0xFF7C3AED),
  AiProvider(id: 'flux', name: 'FLUX', category: 'image', colorValue: 0xFFE11D48),
  AiProvider(id: 'recraft', name: 'Recraft', category: 'image', colorValue: 0xFF0EA5E9),
  AiProvider(id: 'firefly', name: 'Adobe Firefly', category: 'image', colorValue: 0xFFFA0F00),
  AiProvider(id: 'nanobanana', name: 'Nano Banana', category: 'image', colorValue: 0xFFFACC15),
  AiProvider(id: 'veo', name: 'Veo', category: 'video', colorValue: 0xFF34A853, hasCustomIcon: false),
  AiProvider(id: 'kling', name: 'Kling', category: 'video', colorValue: 0xFF00C2A8),
  AiProvider(id: 'runway', name: 'Runway', category: 'video', colorValue: 0xFF000000),
  AiProvider(id: 'luma', name: 'Luma', category: 'video', colorValue: 0xFF6D28D9),
  AiProvider(id: 'pixverse', name: 'PixVerse', category: 'video', colorValue: 0xFFEC4899),
  AiProvider(id: 'pika', name: 'Pika', category: 'video', colorValue: 0xFF9333EA),
  AiProvider(id: 'minimax', name: 'MiniMax', category: 'video', colorValue: 0xFFEF4444),
  AiProvider(id: 'seedream', name: 'Seedream / Seedance', category: 'video', colorValue: 0xFF06B6D4, hasCustomIcon: false),
];

IconData getProviderIcon(AiProvider provider) {
  switch (provider.category) {
    case 'image':
      return Icons.image_outlined;
    case 'video':
      return Icons.videocam_outlined;
    default:
      return provider.hasCustomIcon ? Icons.auto_awesome : Icons.help_outline;
  }
}
