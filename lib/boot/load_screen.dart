import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../session_scope.dart';
import '../skin.dart';
import '../screens/gate.dart';
import '../screens/lobby.dart';

class LoadScreen extends StatefulWidget {
  const LoadScreen({super.key, this.preview = false});

  final bool preview;

  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  var _p = 0.0;
  var _label = 'WARMING UP THE ARENA';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final minWait = Future<void>.delayed(const Duration(milliseconds: 2200));
    final pics = Pics.bootList;
    for (var i = 0; i < pics.length; i++) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(pics[i]), context);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _p = (i + 1) / pics.length;
        _label = i < pics.length / 2 ? 'LOADING BEASTS' : 'CHARGING REELS';
      });
    }
    await minWait;
    if (!mounted || widget.preview) return;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    if (!mounted) return;
    final session = SessionScope.read(context);
    final next = session.ageOk ? const Lobby() : const Gate();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => next,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, o) {
          final land = o == Orientation.landscape;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                land ? Pics.bgLandscapeLogo : Pics.bgPortraitLogo,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xAA070218)],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: land ? 48 : 28, vertical: 18),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: land ? _Land(p: _p, label: _label) : _Port(p: _p, label: _label),
                      ),
                      if (widget.preview)
                        IconButton(
                          onPressed: () async {
                            await SystemChrome.setPreferredOrientations(const [
                              DeviceOrientation.portraitUp,
                            ]);
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Port extends StatelessWidget {
  const _Port({required this.p, required this.label});
  final double p;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        _Bar(p: p, label: label),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _Land extends StatelessWidget {
  const _Land({required this.p, required this.label});
  final double p;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        _Bar(p: p, label: label),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.p, required this.label});
  final double p;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Skin.glow(Skin.cyan, size: 13)),
        const SizedBox(height: 10),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xAA070218),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Skin.pink.withValues(alpha: 0.8), width: 1.2),
          ),
          padding: const EdgeInsets.all(2),
          child: LayoutBuilder(
            builder: (context, box) {
              return Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: box.maxWidth * p.clamp(0.04, 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [Skin.cyan, Skin.electric, Skin.pink],
                    ),
                    boxShadow: Skin.neon(Skin.cyan, blur: 10),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('${(p * 100).clamp(0, 100).toInt()}%', style: Skin.glow(Skin.pink, size: 12)),
      ],
    );
  }
}
