import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/ai_provider.dart';

final List<AiProvider> aiProviders = [
  AiProvider(id: 'gemini', name: 'Gemini', category: 'text', colorValue: 0xFF4285F4, simpleIcon: SimpleIcons.googlegemini),
  AiProvider(id: 'anthropic', name: 'Anthropic', category: 'text', colorValue: 0xFFD97757, simpleIcon: SimpleIcons.anthropic),
  AiProvider(id: 'openai', name: 'OpenAI', category: 'text', colorValue: 0xFF10A37F, hasCustomIcon: false),
  AiProvider(id: 'grok', name: 'Grok / xAI', category: 'text', colorValue: 0xFF000000, simpleIcon: SimpleIcons.x),
  AiProvider(id: 'perplexity', name: 'Perplexity', category: 'text', colorValue: 0xFF20808D, simpleIcon: SimpleIcons.perplexity),
  AiProvider(id: 'deepseek', name: 'DeepSeek', category: 'text', colorValue: 0xFF4D6BFE, simpleIcon: SimpleIcons.deepseek),
  AiProvider(id: 'mistral', name: 'Mistral', category: 'text', colorValue: 0xFFFF7000, simpleIcon: SimpleIcons.mistralai),
  AiProvider(id: 'qwen', name: 'Qwen', category: 'text', colorValue: 0xFF6236FF, simpleIcon: SimpleIcons.qwen),
  AiProvider(id: 'copilot', name: 'GitHub Copilot', category: 'text', colorValue: 0xFF8957E5, simpleIcon: SimpleIcons.githubcopilot),
  AiProvider(id: 'llama', name: 'Meta Llama', category: 'text', colorValue: 0xFF0668E1, simpleIcon: SimpleIcons.meta),
  AiProvider(id: 'kimi', name: 'Kimi', category: 'text', colorValue: 0xFF6B5CE7, hasCustomIcon: false),
  AiProvider(id: 'midjourney', name: 'Midjourney', category: 'image', colorValue: 0xFF000000, hasCustomIcon: false),
  AiProvider(id: 'ideogram', name: 'Ideogram', category: 'image', colorValue: 0xFF7C3AED, hasCustomIcon: false),
  AiProvider(id: 'flux', name: 'FLUX', category: 'image', colorValue: 0xFFE11D48, hasCustomIcon: false),
  AiProvider(id: 'recraft', name: 'Recraft', category: 'image', colorValue: 0xFF0EA5E9, hasCustomIcon: false),
  AiProvider(id: 'firefly', name: 'Adobe Firefly', category: 'image', colorValue: 0xFFFA0F00, hasCustomIcon: false),
  AiProvider(id: 'nanobanana', name: 'Nano Banana', category: 'image', colorValue: 0xFFFACC15, hasCustomIcon: false),
  AiProvider(id: 'veo', name: 'Veo', category: 'video', colorValue: 0xFF34A853, simpleIcon: SimpleIcons.googlegemini),
  AiProvider(id: 'kling', name: 'Kling', category: 'video', colorValue: 0xFF00C2A8, hasCustomIcon: false),
  AiProvider(id: 'runway', name: 'Runway', category: 'video', colorValue: 0xFF000000, hasCustomIcon: false),
  AiProvider(id: 'luma', name: 'Luma', category: 'video', colorValue: 0xFF6D28D9, hasCustomIcon: false),
  AiProvider(id: 'pixverse', name: 'PixVerse', category: 'video', colorValue: 0xFFEC4899, hasCustomIcon: false),
  AiProvider(id: 'pika', name: 'Pika', category: 'video', colorValue: 0xFF9333EA, hasCustomIcon: false),
  AiProvider(id: 'minimax', name: 'MiniMax', category: 'video', colorValue: 0xFFEF4444, hasCustomIcon: false),
  AiProvider(id: 'seedream', name: 'Seedream / Seedance', category: 'video', colorValue: 0xFF06B6D4, hasCustomIcon: false),
];

IconData getProviderIcon(AiProvider provider) {
  if (provider.simpleIcon != null) {
    return provider.simpleIcon as IconData;
  }
  switch (provider.category) {
    case 'image':
      return Icons.image_outlined;
    case 'video':
      return Icons.videocam_outlined;
    default:
      return Icons.auto_awesome;
  }
}
