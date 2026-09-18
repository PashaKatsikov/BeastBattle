import 'package:flutter/material.dart';

import '../session_scope.dart';
import '../skin.dart';
import '../widgets/bits.dart';
import 'lobby.dart';

class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Pics.bgPortrait, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66070218), Color(0xCC070218)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(),
                  const BeastMark(size: 148),
                  const SizedBox(height: 12),
                  Image.asset(Pics.logo, height: 58),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    decoration: BoxDecoration(
                      color: Skin.panel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Skin.pink.withValues(alpha: 0.7)),
                      boxShadow: Skin.neon(Skin.pink, blur: 12),
                    ),
                    child: Column(
                      children: [
                        Text('18+  SOCIAL CASINO', style: Skin.glow(Skin.gold, size: 15)),
                        const SizedBox(height: 10),
                        const Text(
                          'Beast Battle is a social casino. Credits have no cash value. No real-money gambling. Entertainment only.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, height: 1.35, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PillBtn(
                    label: 'I AM 18+',
                    color: Skin.pink,
                    wide: true,
                    onTap: () async {
                      await SessionScope.read(context).acceptAge();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder<void>(
                          pageBuilder: (_, _, _) => const Lobby(),
                          transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
