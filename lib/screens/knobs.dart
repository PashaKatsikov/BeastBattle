import 'package:flutter/material.dart';

import '../skin.dart';
import '../widgets/bits.dart';
import 'leaflet.dart';

class KnobsScreen extends StatelessWidget {
  const KnobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Pics.bgPortrait, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x88070218)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconOrb(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      Text('SETTINGS', style: Skin.glow(Skin.cyan, size: 22)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _Tile(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const Leaflet(title: 'Privacy Policy', url: Pics.privacy, light: true),
                      ),
                    ),
                  ),
                  _Tile(
                    title: 'Support',
                    icon: Icons.support_agent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const Leaflet(title: 'Support', url: Pics.support),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'BEAST BATTLE  •  SOCIAL CASINO\nCredits have no cash value. 18+',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, height: 1.4, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  const Text('v1.0.0', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeonTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Skin.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Skin.cyan.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Skin.cyan),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Skin.glow(Skin.cyan, size: 16))),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
