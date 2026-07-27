import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'generic_add_key_dialog.dart';

class AppSidebar extends StatefulWidget {
  final void Function(String category)? onCategoryTap;
  const AppSidebar({super.key, this.onCategoryTap});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int _balance = 0;
  bool _loadingBalance = true;

  static const _categories = [
    {'label': 'All', 'icon': Icons.grid_view_rounded, 'id': 'text'},
    {'label': 'Text', 'icon': Icons.chat_bubble_outline, 'id': 'text'},
    {'label': 'Image', 'icon': Icons.image_outlined, 'id': 'image'},
    {'label': 'Video', 'icon': Icons.videocam_outlined, 'id': 'video'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loadingBalance = false);
      return;
    }
    try {
      final row = await supabase
          .from('coin_wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();
      setState(() {
        _balance = (row?['balance'] as int?) ?? 0;
        _loadingBalance = false;
      });
    } catch (_) {
      setState(() => _loadingBalance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      color: const Color(0xFF0D0D18),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            _buildLogoHeader(),
            const SizedBox(height: 18),
            const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 10),
            ..._categories.map(_buildCategoryIcon),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 10),
            _buildBalancePill(),
            const SizedBox(height: 10),
            _buildIconAction(
              icon: Icons.vpn_key_outlined,
              label: 'Add Key',
              color: Colors.purpleAccent,
              onTap: () => showGenericAddKeyFlow(context),
            ),
            _buildIconAction(
              icon: Icons.currency_bitcoin,
              label: 'Cash Out',
              color: Colors.amberAccent,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 10),
            _buildStatusDot(),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 10),
            _buildIconAction(icon: Icons.chat_bubble_outline, label: 'New Chat', color: Colors.purpleAccent, onTap: () {}),
            _buildIconAction(icon: Icons.code, label: 'Code', color: Colors.purpleAccent, onTap: () {}),
            _buildIconAction(icon: Icons.search, label: 'Search', color: Colors.purpleAccent, onTap: () {}),
            _buildIconAction(icon: Icons.logout, label: 'Sign out', color: Colors.white38, onTap: () => supabase.auth.signOut()),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3EA5), Color(0xFF3EC6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/images/emomulti_butterfly.png',
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCategoryIcon(Map<String, dynamic> cat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: cat['label'] as String,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onCategoryTap?.call(cat['id'] as String),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(cat['icon'] as IconData, color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildBalancePill() {
    return Tooltip(
      message: '${_balance} coins',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.monetization_on_outlined, color: Colors.amberAccent, size: 16),
            const SizedBox(height: 2),
            _loadingBalance
                ? const SizedBox(
                    height: 10, width: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amberAccent),
                  )
                : Text('${_balance}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    return const Tooltip(
      message: 'All systems online',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Icon(Icons.circle, color: Colors.greenAccent, size: 10),
      ),
    );
  }
}
