import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pit/boot_shell.dart';
import 'pit/cloak.dart';
import 'pit/glance_id.dart';
import 'pit/glare.dart';
import 'pit/horn.dart';
import 'pit/link_probe.dart';
import 'pit/stash.dart';
import 'pit/trail.dart';
import 'pit/verdict_post.dart';
import 'skin.dart';
import 'slot/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  } catch (_) {}

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Skin.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await cloak.ignite();

  final Stash stash = Stash();
  await stash.hydrate();

  final SlotSession session = SlotSession();
  await session.boot();

  final LinkProbe probe = LinkProbe();
  final Trail trail = Trail();
  final VerdictPost poster = VerdictPost(stash);
  final Horn horn = Horn(stash);

  final BootShell app = BootShell(
    session: session,
    stash: stash,
    probe: probe,
    trail: trail,
    poster: poster,
    horn: horn,
  );

  runApp(
    kGlanceProject.isEmpty
        ? app
        : ClarityWidget(clarityConfig: Glare.config, app: app),
  );
}
