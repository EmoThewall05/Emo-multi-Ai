import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'login_screen.dart';
import 'widgets/vault_card_grid.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/add_key_dialog.dart';
import 'models/ai_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
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
      home: const AuthGate(),
    );
  }
}

/// Decides whether to show the login screen or the vault home,
/// based on current Supabase auth session (including guest/anonymous).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session != null) {
          return const VaultHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  void _onKeyTap(BuildContext context, AiProvider provider) {
    showAddKeyDialog(context, provider);
  }

  void _scrollToCategory(String category) {
    final key = categorySectionKeys[category];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSidebar(onCategoryTap: _scrollToCategory),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0A0A14),
              pinned: true,
              expandedHeight: 90,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    await supabase.auth.signOut();
                  },
                ),
              ],
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
          ],
        ),
      ),
    );
  }
}
