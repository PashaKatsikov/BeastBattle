import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../skin.dart';
import '../widgets/bits.dart';

class Leaflet extends StatefulWidget {
  const Leaflet({super.key, required this.title, required this.url, this.light = false});

  final String title;
  final String url;
  final bool light;

  @override
  State<Leaflet> createState() => _LeafletState();
}

class _LeafletState extends State<Leaflet> {
  late final WebViewController _c;
  var _busy = true;
  var _err = false;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.light ? Colors.white : Skin.ink)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _busy = true;
            _err = false;
          }),
          onPageFinished: (_) async {
            if (widget.light) {
              await _c.runJavaScript(
                "document.documentElement.style.backgroundColor='#ffffff';"
                "document.body.style.backgroundColor='#ffffff';"
                "document.body.style.color='#111111';",
              );
            }
            if (mounted) setState(() => _busy = false);
          },
          onWebResourceError: (_) => setState(() {
            _busy = false;
            _err = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _reload() {
    setState(() {
      _busy = true;
      _err = false;
    });
    return _c.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _back(BuildContext context) async {
    if (await _c.canGoBack()) {
      await _c.goBack();
      return;
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _back(context);
      },
      child: Scaffold(
        backgroundColor: Skin.ink,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    IconOrb(icon: Icons.arrow_back, onTap: () => _back(context)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.title, style: Skin.glow(Skin.cyan, size: 18))),
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: widget.light ? Colors.white : Skin.ink,
                  child: Stack(
                    children: [
                      if (!_err) WebViewWidget(controller: _c),
                      if (_err)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Could not load the page.\nCheck your connection and try again.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, height: 1.4),
                                ),
                                const SizedBox(height: 18),
                                PillBtn(label: 'RETRY', color: Skin.cyan, onTap: _reload),
                              ],
                            ),
                          ),
                        ),
                      if (_busy)
                        Center(
                          child: CircularProgressIndicator(
                            color: widget.light ? Skin.electric : Skin.cyan,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
