import 'package:flutter/material.dart';

import '../session_scope.dart';
import '../skin.dart';
import '../widgets/bits.dart';
import 'floor.dart';
import 'pay_sheet.dart';
import 'settings.dart';

class Lobby extends StatelessWidget {
  const Lobby({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
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
                colors: [Color(0x33070218), Color(0x99070218)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CreditChip(credits: session.wallet.credits),
                      const Spacer(),
                      IconOrb(
                        icon: Icons.settings,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  const BeastMark(size: 150),
                  const SizedBox(height: 14),
                  Image.asset(Pics.logo, height: 72),
                  const SizedBox(height: 8),
                  Text('SOCIAL CASINO', style: Skin.glow(Skin.cyan, size: 14)),
                  const Spacer(),
                  PillBtn(
                    label: 'PLAY',
                    color: Skin.pink,
                    wide: true,
                    size: 22,
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        pageBuilder: (_, _, _) => const Floor(),
                        transitionsBuilder: (_, a, _, c) =>
                            FadeTransition(opacity: a, child: c),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PillBtn(
                    label: 'PAYTABLE',
                    color: Skin.electric,
                    wide: true,
                    onTap: () => showPayTable(context),
                  ),
                  const SizedBox(height: 14),
                  PillBtn(
                    label: 'SETTINGS',
                    color: Skin.cyan,
                    wide: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const Spacer(flex: 2),
                  const Text(
                    '18+  •  NO REAL MONEY  •  FOR ENTERTAINMENT',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
