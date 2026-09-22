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

  Future<bool> online() async {
    final List<ConnectivityResult> states =
        await _connectivity.checkConnectivity();
    final bool any =
        states.any((ConnectivityResult item) => _live.contains(item));
    if (!any) return false;

    for (final String host in _hosts) {
      try {
        final List<InternetAddress> found = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 8));
        if (found.isNotEmpty && found.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  Stream<List<ConnectivityResult>> get shifts =>
      _connectivity.onConnectivityChanged;
}
