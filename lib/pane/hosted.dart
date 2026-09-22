import 'dart:async';
import 'dart:io';
import 'dart:ui' show FlutterView;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../pit/cloak.dart';
import '../pit/glare.dart';
import '../pit/horn.dart';
import '../pit/link_probe.dart';
import '../pit/stash.dart';
import '../skin.dart';
import 'dark_line.dart';
import 'page_hooks.dart';

class HostedPane extends StatefulWidget {
  const HostedPane({
    super.key,
    required this.target,
    required this.stash,
    required this.horn,
    required this.probe,
  });

  final String target;
  final Stash stash;
  final Horn horn;
  final LinkProbe probe;

  @override
  State<HostedPane> createState() => _HostedPaneState();
}

class _HostedPaneState extends State<HostedPane> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _spinning = true;
  bool _left = false;
  String? _lastUrl;
  int _loops = 0;
  Timer? _dropTimer;
  StreamSubscription<List<ConnectivityResult>>? _shifts;

  Size? _lastSize;
  bool _mask = false;
  Timer? _maskTimer;

  bool _offerSeen = false;
  bool _pageFault = false;

  static final RegExp _purseRx = RegExp(
    r'(пополн|депозит|касс|оплат|внести|платеж|checkout|cashier|deposit|top.?up|replenish|payment|wallet)',
    caseSensitive: false,
  );
  static final RegExp _joinRx = RegExp(
    r'(регистрац|зарегистр|create.?account|sign.?up|regist|onboarding)',
    caseSensitive: false,
  );
  static final RegExp _enterRx = RegExp(
    r'(войти|вход|авториз|log.?on|log.?in|sign.?in|/auth\b|authoriz)',
    caseSensitive: false,
  );

  static const MethodChannel _picker = MethodChannel('beastpit/pick');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Glare.screen('hosted');
    Glare.event('hosted_open');
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _immersive();
    _wire();
    widget.horn.onWarmLink = (String url) {
      if (mounted) _controller.loadRequest(Uri.parse(url));
    };
    _shifts = widget.probe.shifts.listen((List<ConnectivityResult> rows) {
      final bool dead = rows.isNotEmpty &&
          rows.every((ConnectivityResult item) => item == ConnectivityResult.none);
      if (!dead) {
        _dropTimer?.cancel();
        return;
      }
      _dropTimer?.cancel();
      _dropTimer = Timer(const Duration(milliseconds: 840), _goOffline);
    });
  }

  void _immersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _immersive();
      Glare.event('hosted_foreground');
    } else if (state == AppLifecycleState.paused) {
      Glare.event('hosted_background');
    }
  }

  @override
  void didChangeMetrics() {
    final FlutterView? view =
        WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
            ? WidgetsBinding.instance.platformDispatcher.views.first
            : null;
    if (view == null) return;
    final Size current = view.physicalSize;
    final Size? previous = _lastSize;
    _lastSize = current;
    if (previous == null) return;
    final bool wasWide = previous.width > previous.height;
    final bool nowWide = current.width > current.height;
    if (wasWide == nowWide) return;
    if (!mounted) return;
    setState(() => _mask = true);
    _maskTimer?.cancel();
    _maskTimer = Timer(const Duration(milliseconds: 410), () {
      if (!mounted) return;
      _immersive();
      setState(() => _mask = false);
    });
  }

  void _wire() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(cloak.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _pageFault = false;
            if (mounted) setState(() => _spinning = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _spinning = false);
            _loops = 0;
            _controller.runJavaScript(rimScript());
            _controller.runJavaScript(fieldHoldScript());
            _controller.runJavaScript(wireScript());
            _notePage(url);
          },
          onWebResourceError: (WebResourceError err) {
            if (err.isForMainFrame != true) return;
            _pageFault = true;
            final String why = _why(err);
            final String failed = _lastUrl ?? widget.target;
            final String host = Uri.tryParse(failed)?.host ?? '';
            Glare.event('hosted_fault');
            Glare.tag('fault_why', why);
            Glare.tag('last_fault', '${err.errorCode}:${err.description}');
            if (host.isNotEmpty) Glare.tag('fault_host', host);
            if (!_offerSeen) {
              Glare.event('offer_missed');
              Glare.tag('offer_ok', 'false');
              Glare.tag('miss_why', why);
            } else {
              Glare.event('fault_after');
            }
            final String desc = err.description.toLowerCase();
            final bool loop = desc.contains('too_many_redirects') ||
                desc.contains('too many redirects') ||
                err.errorCode == -1007 ||
                err.errorCode == -9;
            if (loop && _lastUrl != null && _loops < 3) {
              _loops++;
              _controller.loadRequest(Uri.parse(_lastUrl!));
              return;
            }
            if (mounted) setState(() => _spinning = true);
            final bool drop = desc.contains('name_not_resolved') ||
                desc.contains('err_name_not_resolved') ||
                desc.contains('internet_disconnected') ||
                desc.contains('network_changed') ||
                err.errorCode == -105 ||
                err.errorCode == -106 ||
                err.errorCode == -21;
            if (drop) {
              _goOffline();
            } else {
              _goOfflineIfDown();
            }
          },
          onNavigationRequest: (NavigationRequest req) {
            final Uri? uri = Uri.tryParse(req.url);
            if (uri == null) return NavigationDecision.prevent;
            const Set<String> inline = <String>{'http', 'https', 'about', 'data', 'blob'};
            if (inline.contains(uri.scheme)) {
              if (req.isMainFrame) _lastUrl = req.url;
              return NavigationDecision.navigate;
            }
            Glare.event('hosted_outside');
            Glare.tag('outside_scheme', uri.scheme);
            _openOut(uri);
            return NavigationDecision.prevent;
          },
        ),
      );
    _tune();
    _controller.addJavaScriptChannel(
      kWireName,
      onMessageReceived: (JavaScriptMessage message) => _onWire(message.message),
    );
    _controller.loadRequest(Uri.parse(widget.target));
  }

  void _tune() {
    if (!Platform.isAndroid) return;
    if (_controller.platform is! AndroidWebViewController) return;
    final AndroidWebViewController android =
        _controller.platform as AndroidWebViewController;
    android.setMediaPlaybackRequiresUserGesture(false);
    android.setOnPlatformPermissionRequest(
      (PlatformWebViewPermissionRequest req) => req.grant(),
    );
    android.setOnShowFileSelector(_pick);
    final AndroidWebViewCookieManager cookies = AndroidWebViewCookieManager(
      AndroidWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
        const PlatformWebViewCookieManagerCreationParams(),
      ),
    );
    cookies.setAcceptThirdPartyCookies(android, true);
  }

  Future<List<String>> _pick(FileSelectorParams params) async {
    try {
      final List<Object?>? picked = await _picker.invokeMethod<List<Object?>>(
        'grab',
        <String, Object>{
          'multi': params.mode == FileSelectorMode.openMultiple,
          'kinds': params.acceptTypes.where((String item) => item.trim().isNotEmpty).toList(),
        },
      );
      if (picked == null) return const <String>[];
      return picked.whereType<String>().toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _openOut(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _goOfflineIfDown() async {
    if (_left) return;
    if (await widget.probe.online()) return;
    _goOffline();
  }

  void _goOffline() {
    if (_left || !mounted) return;
    _left = true;
    final String next = _lastUrl ?? widget.target;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DarkLine(
          retryBuilder: (_) => HostedPane(
            target: next,
            stash: widget.stash,
            horn: widget.horn,
            probe: widget.probe,
          ),
        ),
      ),
    );
  }

  void _notePage(String url) {
    final Uri? uri = Uri.tryParse(url);
    Glare.screenName('hosted:${uri == null ? url : '${uri.host}${uri.path}'}');
    Glare.event('hosted_page');
    Glare.tag('last_url', url);
    if (!_offerSeen && !_pageFault) {
      _offerSeen = true;
      Glare.event('offer_seen');
      Glare.tag('offer_ok', 'true');
      if (uri?.host != null) Glare.tag('offer_host', uri!.host);
    }
    if (_purseRx.hasMatch(url)) {
      Glare.event('purse_view');
      Glare.tag('purse_seen', 'true');
    }
    _noteAuth(url);
  }

  void _noteAuth(String url) {
    if (_joinRx.hasMatch(url)) {
      Glare.event('join_view');
      Glare.tag('join_seen', 'true');
    } else if (_enterRx.hasMatch(url)) {
      Glare.event('enter_view');
      Glare.tag('enter_seen', 'true');
    }
  }

  static String _why(WebResourceError err) {
    final String text = err.description.toLowerCase();
    final int code = err.errorCode;
    if (text.contains('connection_refused') || text.contains('connection refused')) {
      return 'refused';
    }
    if (text.contains('too_many_redirects') || text.contains('too many redirects')) {
      return 'loop';
    }
    if (text.contains('name_not_resolved') ||
        text.contains('address_unreachable') ||
        text.contains('unknownhost') ||
        code == -2) {
      return 'lookup';
    }
    if (text.contains('timed out') || text.contains('timeout') || code == -8) {
      return 'stalled';
    }
    if (text.contains('internet_disconnected') || text.contains('network_changed') || code == -6) {
      return 'offline';
    }
    if (text.contains('connection_reset')) return 'reset';
    if (text.contains('connection_closed') || text.contains('empty_response')) return 'closed';
    if (text.contains('ssl') || text.contains('cert') || code == -11) return 'tls';
    if (text.contains('blocked')) return 'held';
    return 'misc';
  }

  void _onWire(String raw) {
    final int cut = raw.indexOf(':');
    final String kind = cut < 0 ? raw : raw.substring(0, cut);
    final String data = cut < 0 ? '' : raw.substring(cut + 1);
    switch (kind) {
      case 'hop':
        Glare.event('hosted_spa');
        Glare.tag('last_path', data);
        if (_purseRx.hasMatch(data)) {
          Glare.event('purse_view');
          Glare.tag('purse_seen', 'true');
        }
        _noteAuth(data);
      case 'purse':
        Glare.event('purse_tap');
        Glare.tag('purse_want', 'true');
        if (data.isNotEmpty) Glare.tag('purse_label', data);
      case 'join_tap':
        Glare.event('join_tap');
        Glare.tag('join_want', 'true');
      case 'enter_tap':
        Glare.event('enter_tap');
        Glare.tag('enter_want', 'true');
      case 'auth_post':
        if (data == 'join') {
          Glare.event('join_send');
          Glare.tag('join_try', 'true');
        } else {
          Glare.event('enter_send');
          Glare.tag('enter_try', 'true');
        }
      case 'form_post':
        Glare.event('form_send');
    }
  }

  Future<void> _back() async {
    if (await _controller.canGoBack()) await _controller.goBack();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropTimer?.cancel();
    _maskTimer?.cancel();
    _shifts?.cancel();
    widget.horn.onWarmLink = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.orientationOf(context) == Orientation.landscape;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (!didPop) await _back();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            SafeArea(
              bottom: false,
              child: WebViewWidget(controller: _controller),
            ),
            if (_spinning && !wide)
              const ColoredBox(
                color: Color(0x80000000),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Skin.cyan,
                  ),
                ),
              ),
            if (_mask) const Positioned.fill(child: ColoredBox(color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
