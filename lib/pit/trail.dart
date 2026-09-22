import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import 'cloak.dart';
import 'mark.dart';
import 'packed.dart';

class Trail {
  AppsflyerSdk? _sdk;

  Map<String, dynamic>? _install;
  Map<String, dynamic>? _deep;
  Map<String, dynamic>? _open;

  final Completer<Map<String, dynamic>> _installReady =
      Completer<Map<String, dynamic>>();
  final Completer<void> _deepReady = Completer<void>();

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final String devKey = Mark.attributionDevKey;
    if (devKey.isEmpty) {
      _finishInstall(<String, dynamic>{});
      _finishDeep();
      return;
    }

    final AppsFlyerOptions cfg = AppsFlyerOptions(
      afDevKey: devKey,
      appId: Mark.iosStoreNumericId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 10,
    );
    final AppsflyerSdk sdk = AppsflyerSdk(cfg);
    _sdk = sdk;

    sdk.onInstallConversionData((dynamic raw) async {
      final Map<String, dynamic> parsed = _flatten(raw);
      final String? status = parsed['af_status']?.toString();
      if (status == 'Organic') {
        await Future<void>.delayed(
          Duration(seconds: Mark.organicRecheckSeconds),
        );
        final Map<String, dynamic>? real = await _refetch();
        _install = real ?? parsed;
      } else {
        _install = parsed;
      }
      _finishInstall(_install ?? <String, dynamic>{});
    });

    sdk.onAppOpenAttribution((dynamic raw) {
      _open = _flatten(raw);
    });

    sdk.onDeepLinking((DeepLinkResult result) {
      final Map<String, dynamic>? click = result.deepLink?.clickEvent;
      if (click != null) {
        _deep = Map<String, dynamic>.from(click);
      }
      _finishDeep();
    });

    try {
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (_) {
      _finishInstall(<String, dynamic>{});
      _finishDeep();
    }
  }

  Future<Map<String, dynamic>> waitInstall({int seconds = 30}) {
    return _installReady.future.timeout(
      Duration(seconds: seconds),
      onTimeout: () => <String, dynamic>{},
    );
  }

  Future<void> waitDeep() {
    return _deepReady.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  Future<String?> uid() async {
    if (_sdk == null) return null;
    try {
      return await _sdk!.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> compose({
    required String locale,
    String? pushToken,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (_install != null) body.addAll(_install!);
    _deep?.forEach((String key, dynamic value) {
      body.putIfAbsent(key, () => value);
    });
    _open?.forEach((String key, dynamic value) {
      body.putIfAbsent(key, () => value);
    });

    body['af_id'] = await uid() ?? '';
    body['bundle_id'] = Mark.bundleId;
    body['os'] = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id'] = Mark.storeId;
    body['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    final String project = Mark.messagingProjectId;
    if (project.isNotEmpty) {
      body['firebase_project_id'] = project;
    }

    if (kDebugMode) {
      debugPrint('[Trail] body ${jsonEncode(body)}');
    }
    return body;
  }

  Future<Map<String, dynamic>?> _refetch() async {
    try {
      final String? deviceId = await uid();
      if (deviceId == null) return null;
      final String appId =
          Platform.isIOS ? Mark.iosStoreNumericId : Mark.bundleId;
      final String url = gcdQuery(appId, deviceId);
      if (url.isEmpty) return null;
      final response = await cloak
          .get(
            Uri.parse(url),
            headers: <String, String>{
              'authorization': 'Bearer ${Mark.attributionDevKey}',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  void _finishInstall(Map<String, dynamic> data) {
    if (!_installReady.isCompleted) _installReady.complete(data);
  }

  void _finishDeep() {
    if (!_deepReady.isCompleted) _deepReady.complete();
  }

  static Map<String, dynamic> _flatten(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final dynamic core = raw['payload'] ?? raw['data'] ?? raw;
    if (core is Map) {
      return core.map<String, dynamic>(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }
}
