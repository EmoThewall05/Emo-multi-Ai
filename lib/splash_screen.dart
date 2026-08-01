import 'package:flutter/material.dart';
import 'widgets/scratch_reveal_butterfly.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Center(
        child: ScratchRevealButterfly(
          assetPath: 'assets/images/emomulti_butterfly.png',
          height: 140,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.auto_awesome, size: 100, color: Colors.purpleAccent),
        ),
      ),
    );
  }
}
