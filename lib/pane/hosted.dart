import 'dart:async';
import 'dart:io';
import 'dart:ui' show FlutterView, ViewPadding;

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
  Timer? _retryTimer;
  StreamSubscription<List<ConnectivityResult>>? _shifts;

  Size? _lastSize;
  double _keyLogical = 0;
  double _share = 0;

  static const int _maxLoops = 5;
  static const int _hardCap = 10;
  static const MethodChannel _picker = MethodChannel('beastpit/pick');

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
            final int code = err.errorCode;
            // A hard, unambiguous "no internet" from the stack.
            final bool disconnected =
                desc.contains('internet_disconnected') || code == -106;
            if (disconnected) {
              if (mounted) setState(() => _spinning = true);
              _goOfflineIfDown();
              return;
            }
            // Everything else — redirect loops, DNS blips, and especially
            // ERR_NETWORK_CHANGED raised when a VPN tunnel comes up or down —
            // is transient. Reload the last URL a few times before deciding
            // we are actually offline, mirroring Chrome's own retry.
            if (_loops < _maxLoops) {
              _loops++;
              if (mounted) setState(() => _spinning = true);
              _scheduleReload(const Duration(milliseconds: 600));
              return;
            }
            if (mounted) setState(() => _spinning = true);
            _goOfflineIfDown();
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

  void _scheduleReload(Duration delay) {
    _retryTimer?.cancel();
    final String url = _lastUrl ?? widget.target;
    _retryTimer = Timer(delay, () {
      if (mounted && !_left) _controller.loadRequest(Uri.parse(url));
    });
  }

  Future<void> _goOfflineIfDown() async {
    if (_left) return;
    final bool up = await widget.probe.online();
    if (!mounted || _left) return;
    // A live link (commonly a VPN transport) is present but the page hit a
    // transient error — keep retrying instead of dropping to the offline
    // screen, up to a bound so we never spin forever.
    if (up && _loops < _hardCap) {
      _loops++;
      _scheduleReload(const Duration(seconds: 2));
      return;
    }
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
    final ViewPadding pad = view.viewPadding;
    final double span = view.physicalSize.height - pad.top - pad.bottom;
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
    _retryTimer?.cancel();
    _shifts?.cancel();
    widget.horn.onWarmLink = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool wide = media.orientation == Orientation.landscape;
    // Synchronous, per-frame safe-area from Flutter itself. It updates in the
    // same frame as a rotation, so the WebView is padded correctly at once
    // instead of jumping a frame later like the old async native read did.
    final EdgeInsets notch = media.viewPadding;
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
