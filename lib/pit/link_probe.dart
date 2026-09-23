import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class LinkProbe {
  LinkProbe({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static const Set<ConnectivityResult> _live = <ConnectivityResult>{
    ConnectivityResult.wifi,
    ConnectivityResult.mobile,
    ConnectivityResult.ethernet,
    ConnectivityResult.vpn,
    ConnectivityResult.bluetooth,
    ConnectivityResult.other,
  };

  static const List<String> _hosts = <String>[
    'dns.google',
    'gstatic.com',
  ];

  // IP literals so a live tunnel can be confirmed without any DNS, which some
  // VPNs route away or block. Reached over TCP/443.
  static const List<String> _ips = <String>[
    '1.1.1.1',
    '8.8.8.8',
  ];

  Future<bool> online({Duration lookup = const Duration(seconds: 8)}) async {
    final List<ConnectivityResult> states =
        await _connectivity.checkConnectivity();
    final bool any =
        states.any((ConnectivityResult item) => _live.contains(item));
    if (!any) return false;

    final Completer<bool> done = Completer<bool>();
    final List<Future<bool>> probes = <Future<bool>>[
      for (final String host in _hosts) _reach(host, lookup),
      for (final String ip in _ips) _reachSocket(ip, lookup),
    ];
    var left = probes.length;
    for (final Future<bool> probe in probes) {
      unawaited(probe.then((bool ok) {
        if (ok && !done.isCompleted) done.complete(true);
        left -= 1;
        if (left == 0 && !done.isCompleted) done.complete(false);
      }));
    }
    return done.future;
  }

  Future<bool> _reach(String host, Duration lookup) async {
    try {
      final List<InternetAddress> found =
          await InternetAddress.lookup(host).timeout(lookup);
      return found.isNotEmpty && found.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _reachSocket(String ip, Duration lookup) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, 443, timeout: lookup);
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
  }

  Stream<List<ConnectivityResult>> get shifts =>
      _connectivity.onConnectivityChanged;
}
