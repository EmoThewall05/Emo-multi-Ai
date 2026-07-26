import 'package:flutter/material.dart';
import 'widgets/vault_card_grid.dart';
import 'models/ai_provider.dart';

void main() {
  runApp(const EmoMultiApp());
}

class EmoMultiApp extends StatelessWidget {
  const EmoMultiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmoMulti AI Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Colors.purpleAccent,
          surface: Color(0xFF0A0A14),
        ),
      ),
      home: const VaultHomeScreen(),
    );
  }
}

class VaultHomeScreen extends StatelessWidget {
  const VaultHomeScreen({super.key});

  void _onKeyTap(BuildContext context, AiProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121F),
        title: Text(provider.name, style: const TextStyle(color: Colors.white)),
        content: const Text(
          'API key add cheyyan idam (next step-il form add cheyyum)',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.purpleAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0A0A14),
              pinned: true,
              expandedHeight: 90,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                title: const Text(
                  'EmoMulti AI Studio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A0B2E), Color(0xFF0A0A14)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: const [
                    Icon(Icons.lock_outline, color: Colors.purpleAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'SOVEREIGN AI VAULT',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: VaultCardGrid(
                onAddKey: (provider) => _onKeyTap(context, provider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
