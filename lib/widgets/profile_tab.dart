import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String _workerBaseUrl = 'https://emomulti-guardian-ai.meradivin.workers.dev';
const String _razorpayKeyId = 'rzp_live_T7hoFzwN2P77Mf';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Razorpay _razorpay;
  String? _pendingTier;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  final Map<String, double> _tierPrices = {
    'text_pro': 4.99,
    'image_pro': 3.99,
    'video_pro': 6.99,
    'flat_all': 9.99,
  };

  Future<void> _startUpgrade(String tierKey, String tierLabel) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final amount = _tierPrices[tierKey];
    if (amount == null) return;

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$_workerBaseUrl/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'tier': tierKey,
          'user_id': user.id,
        }),
      );

      final data = jsonDecode(res.body);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Order creation failed');
      }

      final order = data['order'];
      _pendingTier = tierKey;

      final options = {
        'key': _razorpayKeyId,
        'amount': order['amount'],
        'currency': 'INR',
        'name': 'EmoMulti AI Studio',
        'description': '$tierLabel Subscription',
        'order_id': order['id'],
        'prefill': {'email': user.email ?? ''},
        'theme': {'color': '#8B5CF6'},
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _pendingTier == null) return;

    try {
      final res = await http.post(
        Uri.parse('$_workerBaseUrl/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'user_id': user.id,
          'tier': _pendingTier,
        }),
      );

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription activated! 🎉')),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${data['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Guest';
    final joined = user?.createdAt != null
        ? DateTime.parse(user!.createdAt).toLocal().toString().split(' ')[0]
        : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 12),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined: $joined',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'SUBSCRIPTION PLANS',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),

          _TierCard(
            name: 'Free',
            price: '\$0/mo',
            desc: 'Gemini, Groq, Mistral — limited daily use, no key needed',
            color: Colors.white24,
            current: true,
          ),
          _TierCard(
            name: 'Free (BYOK)',
            price: '\$0/mo',
            desc: 'Unlimited use with your own API key, any provider',
            color: Colors.tealAccent,
          ),
          _TierCard(
            name: 'Text Pro',
            price: '\$4.99/mo',
            desc: 'Managed access to select text models',
            color: Colors.blueAccent,
            onUpgrade: _loading ? null : () => _startUpgrade('text_pro', 'Text Pro'),
          ),
          _TierCard(
            name: 'Image Pro',
            price: '\$3.99/mo',
            desc: 'Managed access to select image models',
            color: Colors.orangeAccent,
            onUpgrade: _loading ? null : () => _startUpgrade('image_pro', 'Image Pro'),
          ),
          _TierCard(
            name: 'Video Pro',
            price: '\$6.99/mo',
            desc: 'Managed access to select video models',
            color: Colors.pinkAccent,
            onUpgrade: _loading ? null : () => _startUpgrade('video_pro', 'Video Pro'),
          ),
          _TierCard(
            name: 'Flat (All)',
            price: '\$9.99/mo',
            desc: 'All three categories combined',
            color: Colors.purpleAccent,
            highlight: true,
            onUpgrade: _loading ? null : () => _startUpgrade('flat_all', 'Flat (All)'),
          ),

          const SizedBox(height: 32),
          const Text(
            'ACCOUNT',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Sign out', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String name;
  final String price;
  final String desc;
  final Color color;
  final bool current;
  final bool highlight;
  final VoidCallback? onUpgrade;

  const _TierCard({
    required this.name,
    required this.price,
    required this.desc,
    required this.color,
    this.current = false,
    this.highlight = false,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? Colors.purpleAccent : color.withOpacity(0.4),
          width: highlight ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: highlight ? Colors.purpleAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              if (!current)
                GestureDetector(
                  onTap: onUpgrade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
