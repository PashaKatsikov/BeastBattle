import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fork.dart';

class Stash {
  Stash({FlutterSecureStorage? secure})
      : _secure = secure ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              preferencesKeyPrefix: 'bbx.',
              storageNamespace: 'bb_vault_ns',
            ),
          );

  static const String _lane = 'bb_fork_tag';
  static const String _target = 'bb_url_vault';
  static const String _until = 'bb_url_until';
  static const String _snooze = 'bb_promo_hold';
  static const String _allowed = 'bb_promo_ok';
  static const String _halted = 'bb_promo_halt';
  static const String _queued = 'bb_url_queued';

  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  Future<void> hydrate() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Lane readLane() => Lane.read(_prefs.getString(_lane));

  Future<void> commitLane(Lane lane) => _prefs.setString(_lane, lane.write());

  Future<String?> readTarget() => _secure.read(key: _target);

  Future<void> writeTarget(String url) => _secure.write(key: _target, value: url);

  int? readUntil() => _prefs.getInt(_until);

  Future<void> writeUntil(int unixSeconds) => _prefs.setInt(_until, unixSeconds);

  bool isTargetStale() {
    final int? until = readUntil();
    if (until == null) return true;
    return _now() >= until;
  }

  bool isPromoAllowed() => _prefs.getBool(_allowed) ?? false;

  Future<void> markPromoAllowed(bool value) => _prefs.setBool(_allowed, value);

  bool isPromoHalted() => _prefs.getBool(_halted) ?? false;

  Future<void> markPromoHalted() => _prefs.setBool(_halted, true);

  int? readSnooze() => _prefs.getInt(_snooze);

  Future<void> writeSnooze(int unixSeconds) => _prefs.setInt(_snooze, unixSeconds);

  bool shouldOfferPromo() {
    if (isPromoAllowed()) return false;
    if (isPromoHalted()) return false;
    final int? until = readSnooze();
    if (until == null) return true;
    return _now() >= until;
  }

  Future<void> queueTarget(String? url) async {
    if (url == null) {
      await _secure.delete(key: _queued);
    } else {
      await _secure.write(key: _queued, value: url);
    }
  }

  Future<String?> takeQueuedTarget() async {
    final String? url = await _secure.read(key: _queued);
    if (url != null) await _secure.delete(key: _queued);
    return url;
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
