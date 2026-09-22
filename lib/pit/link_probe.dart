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

  Future<bool> online({Duration lookup = const Duration(seconds: 8)}) async {
    final List<ConnectivityResult> states =
        await _connectivity.checkConnectivity();
    final bool any =
        states.any((ConnectivityResult item) => _live.contains(item));
    if (!any) return false;

    final Completer<bool> done = Completer<bool>();
    var left = _hosts.length;
    for (final String host in _hosts) {
      unawaited(_reach(host, lookup).then((bool ok) {
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

  Stream<List<ConnectivityResult>> get shifts =>
      _connectivity.onConnectivityChanged;
}
