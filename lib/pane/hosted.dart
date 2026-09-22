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
  EdgeInsets _rim = EdgeInsets.zero;
  double _keyLogical = 0;
  double _share = 0;

  static const MethodChannel _picker = MethodChannel('beastpit/pick');
  static const MethodChannel _rimChannel = MethodChannel('beastpit/rim');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _immersive();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readCutout();
      WidgetsBinding.instance.addPostFrameCallback((_) => _readCutout());
    });
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
    }
  }

  @override
  void didChangeMetrics() {
    final FlutterView? view =
        WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
            ? WidgetsBinding.instance.platformDispatcher.views.first
            : null;
    _readCutout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _readCutout();
    });
    if (view == null) return;
    _noteKeys(view);
    final Size current = view.physicalSize;
    final Size? previous = _lastSize;
    _lastSize = current;
    if (previous == null) return;
    final bool wasWide = previous.width > previous.height;
    final bool nowWide = current.width > current.height;
    if (wasWide == nowWide) return;
    _immersive();
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
            if (mounted) setState(() => _spinning = true);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _spinning = false);
            _loops = 0;
            try {
              await _controller.runJavaScript(rimScript());
              await _controller.runJavaScript(fieldHoldScript());
            } catch (_) {}
            if (_share > 0) await _castShare(_share);
          },
          onWebResourceError: (WebResourceError err) {
            if (err.isForMainFrame != true) return;
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
            _openOut(uri);
            return NavigationDecision.prevent;
          },
        ),
      );
    _tune();
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

  Future<void> _back() async {
    if (await _controller.canGoBack()) await _controller.goBack();
  }

  void _noteKeys(FlutterView view) {
    final double ratio = view.devicePixelRatio;
    if (ratio <= 0) return;
    final double inset = view.viewInsets.bottom / ratio;
    if ((inset - _keyLogical).abs() < 1) return;
    _keyLogical = inset;
    final double span =
        view.physicalSize.height - (_rim.top + _rim.bottom) * ratio;
    if (span <= 0) return;
    _share = (inset * ratio / span).clamp(0.0, 1.0);
    _castShare(_share);
  }

  Future<void> _castShare(double share) async {
    try {
      await _controller.runJavaScript(
        'window.__bbShare&&window.__bbShare(${share.toStringAsFixed(5)});',
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropTimer?.cancel();
    _shifts?.cancel();
    widget.horn.onWarmLink = null;
    super.dispose();
  }

  Future<void> _readCutout() async {
    try {
      final Object? raw = await _rimChannel.invokeMethod<Object>('read');
      if (!mounted || raw is! Map) return;
      final double unit = View.of(context).devicePixelRatio;
      double edge(Object? value) {
        final double px = (value as num?)?.toDouble() ?? 0;
        if (px <= 0 || unit <= 0) return 0;
        return px / unit;
      }
      final EdgeInsets next = EdgeInsets.fromLTRB(
        edge(raw['left']),
        edge(raw['top']),
        edge(raw['right']),
        edge(raw['bottom']),
      );
      if (next != _rim) setState(() => _rim = next);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool wide = media.orientation == Orientation.landscape;
    final EdgeInsets notch = _rim;
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
            Padding(
              padding: notch,
              child: MediaQuery(
                data: media.removeViewInsets(removeBottom: true).copyWith(
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: WebViewWidget(controller: _controller),
              ),
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
          ],
        ),
      ),
    );
  }
}
