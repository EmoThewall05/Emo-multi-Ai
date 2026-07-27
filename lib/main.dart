import 'widgets/profile_tab.dart';
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
  int _selectedIndex = 0;

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

  Widget _buildHomeTab() {
    return Row(
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
    );
  }

  Widget _buildEmoCoinTab() {
    return const _PlaceholderTab(
      icon: Icons.currency_exchange,
      title: 'Emo Coin',
      subtitle: 'Convert via TheWall Web3 — coming soon',
    );
  }

  Widget _buildCreateTab() {
    return const _PlaceholderTab(
      icon: Icons.auto_awesome,
      title: 'Create',
      subtitle: 'Templates — coming soon',
    );
  }

  Widget _buildProfileTab() {
    return const _PlaceholderTab(
      icon: Icons.person_outline,
      title: 'Profile',
      subtitle: 'Email, phone, user data — coming soon',
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return _buildEmoCoinTab();
      case 2:
        return _buildCreateTab();
      case 3:
        return _buildProfileTab();
      case 0:
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF12121F),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Emo Coin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.purpleAccent),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
