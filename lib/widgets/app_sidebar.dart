import 'package:flutter/material.dart';
import '../supabase_config.dart';

class AppSidebar extends StatefulWidget {
  final void Function(String category)? onCategoryTap;
  const AppSidebar({super.key, this.onCategoryTap});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int _balance = 0;
  bool _loadingBalance = true;
  String? _email;

  static const _categories = [
    {'label': 'All', 'icon': Icons.grid_view_rounded, 'id': 'text'},
    {'label': 'Text', 'icon': Icons.chat_bubble_outline, 'id': 'text'},
    {'label': 'Image', 'icon': Icons.image_outlined, 'id': 'image'},
    {'label': 'Video', 'icon': Icons.videocam_outlined, 'id': 'video'},
  ];

  @override
  void initState() {
    super.initState();
    _email = supabase.auth.currentUser?.email;
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
      width: 240,
      color: const Color(0xFF0D0D18),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogoHeader(),
            const SizedBox(height: 20),
            _buildUserSection(),
            const SizedBox(height: 20),
            _sectionTitle('CATEGORIES'),
            ..._categories.map(_buildCategoryTile),
            const SizedBox(height: 20),
            _sectionTitle('PAYMENT'),
            _buildPaymentCard(),
            const SizedBox(height: 20),
            _sectionTitle('SYSTEM STATUS'),
            _buildStatusTile('AI Engines', true),
            _buildStatusTile('Database', true),
            _buildStatusTile('Sync', true),
            const SizedBox(height: 20),
            _sectionTitle('QUICK ACTIONS'),
            _buildActionTile(Icons.chat_bubble_outline, 'New Chat'),
            _buildActionTile(Icons.code, 'Code Assist'),
            _buildActionTile(Icons.search, 'Web Search'),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/emomulti_butterfly.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 28),
          ),
          const SizedBox(width: 10),
          const Text(
            'EmoMulti',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.purpleAccent,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _email ?? 'Guest',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic> cat) {
    return ListTile(
      dense: true,
      leading: Icon(cat['icon'] as IconData, color: Colors.white70, size: 20),
      title: Text(cat['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: () => widget.onCategoryTap?.call(cat['id'] as String),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 6),
              _loadingBalance
                  ? const SizedBox(
                      height: 12, width: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                    )
                  : Text(
                      '$_balance coins',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: Colors.amberAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cash Out', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(String label, bool online) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: online ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.purpleAccent, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: () {},
    );
  }
}
