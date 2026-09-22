import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../session_scope.dart';
import '../skin.dart';
import '../slot/session.dart';
import 'horn.dart';
import 'link_probe.dart';
import 'pit_router.dart';
import 'stash.dart';
import 'trail.dart';
import 'verdict_post.dart';

class BootShell extends StatefulWidget {
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
  State<BootShell> createState() => _BootShellState();
}

class _BootShellState extends State<BootShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: widget.session,
      child: MaterialApp(
        title: 'Beast Battle',
        debugShowCheckedModeBanner: false,
        theme: Skin.theme,
        home: PitRouter(
          stash: widget.stash,
          probe: widget.probe,
          trail: widget.trail,
          poster: widget.poster,
          horn: widget.horn,
        ),
      ),
    );
  }
}
