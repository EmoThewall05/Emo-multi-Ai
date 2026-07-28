import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TheWallWebViewScreen extends StatefulWidget {
  const TheWallWebViewScreen({super.key});

  @override
  State<TheWallWebViewScreen> createState() => _TheWallWebViewScreenState();
}

class _TheWallWebViewScreenState extends State<TheWallWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse('https://thewall-web3.e-mobies.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('TheWall Web3', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ),
        ],
      ),
    );
  }
}
