import 'package:flutter/material.dart';

import '../skin.dart';

class NeonTap extends StatefulWidget {
  const NeonTap({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<NeonTap> createState() => _NeonTapState();
}

class _NeonTapState extends State<NeonTap> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 80),
        child: Opacity(opacity: widget.enabled ? 1 : 0.45, child: widget.child),
      ),
    );
  }
}

class PillBtn extends StatelessWidget {
  const PillBtn({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
    this.wide = false,
    this.size = 16,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool wide;
  final double size;

  @override
  Widget build(BuildContext context) {
    return NeonTap(
      onTap: onTap,
      enabled: onTap != null,
      child: Container(
        constraints: BoxConstraints(minWidth: wide ? 180 : 120, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.white, 0.25)!,
              color,
              Color.lerp(color, Colors.black, 0.25)!,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.4),
          boxShadow: Skin.neon(color),
        ),
        child: Center(
          child: Text(
            label,
            style: Skin.glow(color, size: size),
          ),
        ),
      ),
    );
  }
}

class LedReadout extends StatelessWidget {
  const LedReadout({
    super.key,
    required this.caption,
    required this.value,
    this.accent = Skin.led,
  });

  final String caption;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE6080418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            style: TextStyle(
              color: accent.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Skin.glow(accent, size: 18),
          ),
        ],
      ),
    );
  }
}

class CreditChip extends StatelessWidget {
  const CreditChip({super.key, required this.credits, this.onTap});

  final int credits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeonTap(
      onTap: onTap,
      enabled: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC160830),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Skin.gold.withValues(alpha: 0.7)),
          boxShadow: Skin.neon(Skin.gold, blur: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/game/symbols/coins.webp', width: 22, height: 22),
            const SizedBox(width: 6),
            Text(_fmt(credits), style: Skin.glow(Skin.gold, size: 16)),
          ],
        ),
      ),
    );
  }
}

class IconOrb extends StatelessWidget {
  const IconOrb({super.key, required this.icon, required this.onTap, this.color = Skin.cyan});

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeonTap(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC12062E),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 1.3),
          boxShadow: Skin.neon(color, blur: 10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

String _fmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String fmtCredits(int n) => _fmt(n);

class BeastMark extends StatelessWidget {
  const BeastMark({super.key, this.size = 140});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: Skin.cyan.withValues(alpha: 0.85), width: 2),
        boxShadow: Skin.neon(Skin.cyan, blur: 18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22 - 2),
        child: Image.asset(Pics.beast, fit: BoxFit.cover),
      ),
    );
  }
}

class IdlePulse extends StatefulWidget {
  const IdlePulse({super.key, required this.child, this.active = true});
  final Widget child;
  final bool active;

  @override
  State<IdlePulse> createState() => _IdlePulseState();
}

class _IdlePulseState extends State<IdlePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant IdlePulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.07).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
