import 'package:flutter/material.dart';

import '../pit/horn.dart';
import '../pit/link_probe.dart';
import '../pit/mark.dart';
import '../pit/stash.dart';
import 'hosted.dart';
import 'shell_art.dart';
import 'slab.dart';

class PromoBoard extends StatelessWidget {
  const PromoBoard({
    super.key,
    required this.stash,
    required this.horn,
    required this.probe,
    required this.target,
  });

  final Stash stash;
  final Horn horn;
  final LinkProbe probe;
  final String target;

  Future<void> _allow(BuildContext context) async {
    await horn.askPermission();
    await stash.markPromoHalted();
    if (context.mounted) _open(context);
  }

  Future<void> _later(BuildContext context) async {
    await stash.writeSnooze(_snooze());
    if (context.mounted) _open(context);
  }

  int _snooze() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + Mark.promoCooldownSeconds;

  void _open(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HostedPane(
          target: target,
          stash: stash,
          horn: horn,
          probe: probe,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width > size.height;
    final String art = wide ? ShellArt.promoWide : ShellArt.promoTall;
    final double primary = wide ? size.width * 0.32 : (size.width * 0.72).clamp(240, 380);
    final double bottom = size.height * (wide ? 0.07 : 0.08);

    final Widget stack = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        NeonSlab(
          label: 'Accept',
          icon: Icons.notifications_active_rounded,
          tight: wide,
          width: primary,
          onPressed: () => _allow(context),
        ),
        SizedBox(height: wide ? 8 : 12),
        GhostSlab(
          label: 'Skip',
          tight: wide,
          width: primary,
          onPressed: () => _later(context),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070218),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(art, fit: BoxFit.cover, width: size.width, height: size.height),
          if (wide)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom,
              child: Center(child: stack),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: stack,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
