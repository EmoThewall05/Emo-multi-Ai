import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'thewall_webview_screen.dart';

class EmoCoinTab extends StatefulWidget {
  const EmoCoinTab({super.key});

  @override
  State<EmoCoinTab> createState() => _EmoCoinTabState();
}

class _EmoCoinTabState extends State<EmoCoinTab> {
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('emomulti_coin_balance')
          .select('balance')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _balance = res != null ? (res['balance'] as num).toDouble() : 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inrValue = _balance * 0.10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0B2E), Color(0xFF12121F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.currency_exchange, color: Colors.purpleAccent, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'EMO COIN BALANCE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _loading
                    ? const CircularProgressIndicator(color: Colors.purpleAccent)
                    : Text(
                        '${_balance.toStringAsFixed(0)} EMO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 6),
                Text(
                  '≈ ₹${inrValue.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1 EMO Coin = ₹0.10 · 10 EMO/day ≈ ₹1',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TheWallWebViewScreen()),
                );
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Convert via TheWall Web3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : _fetchBalance,
            child: const Text('Refresh balance', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
