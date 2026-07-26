class AiProvider {
  final String id;
  final String name;
  final String category; // 'text', 'image', 'video'
  final int colorValue;
  final bool hasCustomIcon;
  final dynamic simpleIcon; // IconData from simple_icons package, or null

  const AiProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.colorValue,
    this.hasCustomIcon = true,
    this.simpleIcon,
  });
}
