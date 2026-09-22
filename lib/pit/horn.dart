import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'cloak.dart';
import 'stash.dart';

const String kHornChannelId = 'bb_arena_pulse';
const String kHornChannelName = 'Arena bonuses';
const String _hornIcon = '@drawable/ic_note_mark';

@pragma('vm:entry-point')
Future<void> _pitBgHandler(RemoteMessage _) async {}

class Horn {
  Horn(this._stash);

  final Stash _stash;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _fm;
  String? _token;
  bool _ready = false;

  void Function(String url)? onWarmLink;
  void Function(String token)? onToken;

  String? get token => _token;

  Future<void> warm() async {
    if (_ready) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _fm = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_pitBgHandler);
      await _localSetup();
      _token = await _fm!.getToken();
      _fm!.onTokenRefresh.listen((String next) {
        _token = next;
        onToken?.call(next);
      });
      FirebaseMessaging.onMessage.listen(_foreground);
      FirebaseMessaging.onMessageOpenedApp.listen(_warmTap);
      final RemoteMessage? initial = await _fm!.getInitialMessage();
      if (initial != null) _coldTap(initial);
      _ready = true;
    } catch (_) {}
  }

  Future<void> _localSetup() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings(_hornIcon);
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? raw = response.payload;
        if (raw == null || raw.isEmpty) return;
        try {
          final Map<String, dynamic> data =
              jsonDecode(raw) as Map<String, dynamic>;
          final String? url = data['url'] as String?;
          if (url != null && url.isNotEmpty) onWarmLink?.call(_https(url));
        } catch (_) {}
      },
    );
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? impl = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          kHornChannelId,
          kHornChannelName,
          description: 'Bonus and promo alerts',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<bool> askPermission() async {
    if (_fm == null) return false;
    final NotificationSettings settings = await _fm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final bool granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    await _stash.markPromoAllowed(granted);
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      await _stash.markPromoHalted();
    }
    return granted;
  }

  Future<void> _foreground(RemoteMessage message) async {
    final RemoteNotification? note = message.notification;
    if (note == null || !Platform.isAndroid) return;

    AndroidNotificationDetails? details;
    final String? imageUrl = note.android?.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final Uint8List? bytes = await _fetch(imageUrl);
      if (bytes != null) {
        details = AndroidNotificationDetails(
          kHornChannelId,
          kHornChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: _hornIcon,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }
    details ??= const AndroidNotificationDetails(
      kHornChannelId,
      kHornChannelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: _hornIcon,
    );
    await _local.show(
      note.hashCode,
      note.title,
      note.body,
      NotificationDetails(android: details),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  void _coldTap(RemoteMessage message) {
    final String? url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      _stash.queueTarget(_https(url));
    }
  }

  void _warmTap(RemoteMessage message) {
    final String? url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) onWarmLink?.call(_https(url));
  }

  static String _https(String url) {
    return url.startsWith('http://') ? 'https://${url.substring(7)}' : url;
  }

  Future<Uint8List?> _fetch(String url) async {
    try {
      final res = await cloak.get(Uri.parse(url)).timeout(const Duration(seconds: 9));
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}
    return null;
  }
}
