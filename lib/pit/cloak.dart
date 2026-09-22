import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import 'packed.dart';

// GAME THEME CATEGORY: slot
// Identity suffix is omitted until a partner asks for it on the user-agent.

class CloakClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  String _agent = openFallbackUa();

  String get userAgent => _agent;

  Future<void> ignite() async {
    final String chrome = openChrome();
    final String webkit = openWebKit();
    if (chrome.isEmpty || webkit.isEmpty) return;
    try {
      if (!Platform.isAndroid) return;
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      final String build = info.display.isNotEmpty
          ? info.display
          : (info.id.isNotEmpty ? info.id : 'UP1A');
      _agent = _assemble(
        release: info.version.release,
        brand: info.brand,
        model: info.model,
        buildTag: build,
        chrome: chrome,
        webkit: webkit,
      );
    } catch (_) {}
  }

  static String _assemble({
    required String release,
    required String brand,
    required String model,
    required String buildTag,
    required String chrome,
    required String webkit,
  }) {
    return '${openUaMozilla()}${openUaLinux()}$release; '
        '$brand $model${openUaBuild()}$buildTag${openUaClose()}'
        '${openUaWebKit()}$webkit${openUaGecko()}'
        '${openUaChrome()}$chrome${openUaSafari()}$webkit';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => _agent);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final CloakClient cloak = CloakClient();
