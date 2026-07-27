import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

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
          // Avatar + user info
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
          ),
          _TierCard(
            name: 'Image Pro',
            price: '\$3.99/mo',
            desc: 'Managed access to select image models',
            color: Colors.orangeAccent,
          ),
          _TierCard(
            name: 'Video Pro',
            price: '\$6.99/mo',
            desc: 'Managed access to select video models',
            color: Colors.pinkAccent,
          ),
          _TierCard(
            name: 'Flat (All)',
            price: '\$9.99/mo',
            desc: 'All three categories combined',
            color: Colors.purpleAccent,
            highlight: true,
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

  const _TierCard({
    required this.name,
    required this.price,
    required this.desc,
    required this.color,
    this.current = false,
    this.highlight = false,
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upgrade to $name — Razorpay checkout coming next')),
                    );
                  },
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
