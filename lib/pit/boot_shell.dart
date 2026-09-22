import 'package:flutter/material.dart';

import '../session_scope.dart';
import '../skin.dart';
import '../slot/session.dart';
import 'horn.dart';
import 'link_probe.dart';
import 'pit_router.dart';
import 'stash.dart';
import 'trail.dart';
import 'verdict_post.dart';

class BootShell extends StatelessWidget {
  const BootShell({
    super.key,
    required this.session,
    required this.stash,
    required this.probe,
    required this.trail,
    required this.poster,
    required this.horn,
  });

  final SlotSession session;
  final Stash stash;
  final LinkProbe probe;
  final Trail trail;
  final VerdictPost poster;
  final Horn horn;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: session,
      child: MaterialApp(
        title: 'Beast Battle',
        debugShowCheckedModeBanner: false,
        theme: Skin.theme,
        home: PitRouter(
          stash: stash,
          probe: probe,
          trail: trail,
          poster: poster,
          horn: horn,
        ),
      ),
    );
  }
}
