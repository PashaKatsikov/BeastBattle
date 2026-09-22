import 'package:clarity_flutter/clarity_flutter.dart';

import 'glance_id.dart';

class Glare {
  const Glare._();

  static ClarityConfig get config => ClarityConfig(
        projectId: kGlanceProject,
        logLevel: LogLevel.None,
      );

  static void identify(String? aid, {Map<String, String> tags = const {}}) {
    if (aid != null && aid.isNotEmpty) {
      _guard(() => Clarity.setCustomUserId(_clip(aid, 255)));
      tag('aid', aid);
    }
    tags.forEach(tag);
  }

  static void screen(String name) {
    screenName(name);
    event('view_$name');
  }

  static void screenName(String name) => _guard(() {
        Clarity.setCurrentScreenName(_clip(name, 255));
        Clarity.setCustomTag('view_last', _clip(name, 255));
      });

  static void event(String name) =>
      _guard(() => Clarity.sendCustomEvent(_clip(name, 254)));

  static void tag(String key, String value) {
    if (value.isEmpty) return;
    _guard(() => Clarity.setCustomTag(key, _clip(value, 255)));
  }

  static String _clip(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  static void _guard(void Function() body) {
    try {
      body();
    } catch (_) {}
  }
}
