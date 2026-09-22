import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pane/dark_line.dart';
import '../pane/hosted.dart';
import '../pane/promo_board.dart';
import '../screens/gate.dart';
import '../screens/lobby.dart';
import '../session_scope.dart';
import '../skin.dart';
import 'fork.dart';
import 'horn.dart';
import 'link_probe.dart';
import 'reply.dart';
import 'stash.dart';
import 'trail.dart';
import 'verdict_post.dart';

class PitRouter extends StatefulWidget {
  const PitRouter({
    super.key,
    required this.stash,
    required this.probe,
    required this.trail,
    required this.poster,
    required this.horn,
  });

  final Stash stash;
  final LinkProbe probe;
  final Trail trail;
  final VerdictPost poster;
  final Horn horn;

  @override
  State<PitRouter> createState() => _PitRouterState();
}

class _PitRouterState extends State<PitRouter> {
  double _progress = 0.07;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    widget.horn.onToken = _resend;
    _drive();
  }

  @override
  void dispose() {
    widget.horn.onToken = null;
    super.dispose();
  }

  void _lift(double value) {
    if (!mounted) return;
    setState(() => _progress = value.clamp(0.0, 1.0));
  }

  static const Duration _linkWait = Duration(seconds: 2);

  Future<bool> _up() => widget.probe.online(lookup: _linkWait);

  Future<void> _warmBriefly() async {
    try {
      await widget.horn.warm().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> _drive() async {
    final Lane lane = widget.stash.readLane();
    if (lane == Lane.cabinet) {
      unawaited(widget.horn.warm());
      _lift(0.24);
      await _toCabinet(0.51);
      return;
    }
    if (!await _up()) {
      _offline();
      return;
    }
    await _warmBriefly();
    if (!mounted || _gone) return;
    _lift(0.24);
    switch (lane) {
      case Lane.cabinet:
        await _toCabinet(0.51);
        return;
      case Lane.hosted:
        await _resume();
        return;
      case Lane.fresh:
        await _first();
        return;
    }
  }

  Future<void> _first() async {
    if (!await _up()) {
      _offline();
      return;
    }
    _lift(0.46);
    await widget.trail.start();
    await Future.wait<void>(<Future<void>>[
      widget.trail.waitInstall(),
      widget.trail.waitDeep(),
    ]);
    _lift(0.71);
    final PitReply reply = await _ask();
    if (reply.admitted && reply.hasTarget) {
      await widget.stash.commitLane(Lane.hosted);
      _lift(1);
      await _beat();
      _hosted(reply.target!);
    } else if (reply.broken) {
      _offline();
    } else {
      await widget.stash.commitLane(Lane.cabinet);
      await _toCabinet(0.86);
    }
  }

  Future<void> _resume() async {
    if (!await _up()) {
      _lift(1);
      _offline();
      return;
    }
    _lift(0.46);
    final String? queued = await widget.stash.takeQueuedTarget();
    if (queued != null) {
      _lift(1);
      await _beat();
      _hosted(queued);
      return;
    }
    final String? saved = await widget.stash.readTarget();
    await widget.trail.start();
    await Future.wait<void>(<Future<void>>[
      widget.trail.waitInstall(seconds: 12),
      widget.trail.waitDeep(),
    ]);
    _lift(0.71);
    final PitReply reply = await _ask();
    _lift(1);
    await _beat();
    if (reply.admitted && reply.hasTarget) {
      _hosted(reply.target!);
    } else if (reply.broken) {
      _offline();
    } else if (saved != null && saved.isNotEmpty) {
      _hosted(saved);
    } else {
      _offline();
    }
  }

  Future<PitReply> _ask() async {
    final String locale = Platform.localeName.replaceAll('-', '_');
    final Map<String, dynamic> body = await widget.trail.compose(
      locale: locale,
      pushToken: widget.horn.token,
    );
    return widget.poster.ask(body);
  }

  Future<void> _resend(String token) async {
    final String locale = Platform.localeName.replaceAll('-', '_');
    final Map<String, dynamic> body = await widget.trail.compose(
      locale: locale,
      pushToken: token,
    );
    unawaited(widget.poster.ask(body));
  }

  Future<void> _beat() => Future<void>.delayed(const Duration(milliseconds: 260));

  Future<void> _toCabinet(double from) async {
    _lift(from);
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await _warmArt();
    _lift(1);
    await _beat();
    if (_gone || !mounted) return;
    _gone = true;
    final bool aged = SessionScope.read(context).ageOk;
    final Widget next = aged ? const Lobby() : const Gate();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, Animation<double> anim, _) =>
            FadeTransition(opacity: anim, child: next),
      ),
    );
  }

  Future<void> _warmArt() async {
    for (final String path in Pics.bootList) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }
  }

  void _hosted(String target) {
    if (_gone || !mounted) return;
    _gone = true;
    if (widget.stash.shouldOfferPromo()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PromoBoard(
            stash: widget.stash,
            horn: widget.horn,
            probe: widget.probe,
            target: target,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HostedPane(
          target: target,
          stash: widget.stash,
          horn: widget.horn,
          probe: widget.probe,
        ),
      ),
    );
  }

  void _offline() {
    if (_gone || !mounted) return;
    _gone = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DarkLine(
          retryBuilder: (_) => PitRouter(
            stash: widget.stash,
            probe: widget.probe,
            trail: widget.trail,
            poster: widget.poster,
            horn: widget.horn,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      backgroundColor: Skin.ink,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            wide ? Pics.bgLandscapeLogo : Pics.bgPortraitLogo,
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x00000000), Color(0xAA070218)],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(wide ? 48 : 28, 0, wide ? 48 : 28, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${(_progress * 100).round()}%',
                      style: Skin.glow(Skin.cyan, size: 13),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xAA070218),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Skin.pink.withValues(alpha: 0.8), width: 1.2),
                      ),
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints box) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: box.maxWidth * _progress.clamp(0.04, 1),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: <Color>[Skin.cyan, Skin.electric, Skin.pink],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
