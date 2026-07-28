import 'package:flutter/material.dart';

class CreateTemplate {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String provider;

  const CreateTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.provider,
  });
}

const List<CreateTemplate> _templates = [
  CreateTemplate(
    title: 'Students Support',
    subtitle: 'Homework help, study plans, exam prep',
    icon: Icons.school_outlined,
    color: Colors.blueAccent,
    provider: 'GPT-4o / Gemini',
  ),
  CreateTemplate(
    title: 'Stress Relief',
    subtitle: 'Calm conversations, mindfulness, venting',
    icon: Icons.self_improvement_outlined,
    color: Colors.tealAccent,
    provider: 'Claude',
  ),
  CreateTemplate(
    title: 'Develop Ideas',
    subtitle: 'Brainstorm and refine with Anthropic',
    icon: Icons.lightbulb_outline,
    color: Colors.purpleAccent,
    provider: 'Claude',
  ),
  CreateTemplate(
    title: 'Understand & Learn',
    subtitle: 'Explanations, research, deep dives',
    icon: Icons.menu_book_outlined,
    color: Colors.orangeAccent,
    provider: 'Gemini',
  ),
  CreateTemplate(
    title: 'Crypto Knowledge',
    subtitle: 'Market info, Web3 concepts, current data',
    icon: Icons.currency_bitcoin,
    color: Colors.amberAccent,
    provider: 'GPT-4o / Perplexity',
  ),
  CreateTemplate(
    title: 'Chef Mode',
    subtitle: 'Recipes, fridge photo, Kerala dishes & more',
    icon: Icons.restaurant_menu_outlined,
    color: Colors.pinkAccent,
    provider: 'Claude / GPT-4o / Gemini / Grok',
  ),
  CreateTemplate(
    title: 'Coding & Web Dev',
    subtitle: 'Build apps, debug, websites & scripts',
    icon: Icons.code_outlined,
    color: Colors.greenAccent,
    provider: 'Anthropic / Kimi / Meta / Grok / GPT-4o',
  ),
];

class CreateTab extends StatelessWidget {
  const CreateTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CREATE',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick a template to get started',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ..._templates.map((t) => _TemplateCard(
                template: t,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t.title} — chat coming soon')),
                  );
                },
              )),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final CreateTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12121F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: template.color.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: template.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(template.icon, color: template.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        template.subtitle,
                        style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: template.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          template.provider,
                          style: TextStyle(
                            color: template.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
