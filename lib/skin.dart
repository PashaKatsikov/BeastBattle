import 'package:flutter/material.dart';

abstract final class Pics {
  static const bgPortrait = 'assets/game/bg_portrait.webp';
  static const bgPortraitLogo = 'assets/game/bg_portrait_logo.webp';
  static const bgLandscapeLogo = 'assets/game/bg_landscape_logo.webp';
  static const bgArena = 'assets/game/bg_arena_wide.webp';
  static const logo = 'assets/game/logo.webp';
  static const frame = 'assets/game/frame.webp';
  static const spin = 'assets/game/spin.webp';
  static const auto = 'assets/game/auto.webp';
  static const beast = 'assets/game/beast.webp';

  static const privacy = 'https://beastbattle.site/privacy-policy.html';
  static const support = 'https://beastbattle.site/support.html';

  static List<String> get bootList => [
        bgPortrait,
        bgPortraitLogo,
        bgLandscapeLogo,
        bgArena,
        logo,
        frame,
        spin,
        auto,
        beast,
        ...[for (final s in _sym) 'assets/game/symbols/$s.webp'],
      ];

  static const _sym = [
    'cherry',
    'lemon',
    'grape',
    'bell',
    'bar',
    'coins',
    'diamond',
    'seven',
    'wild',
    'scatter',
  ];
}

abstract final class Skin {
  static const ink = Color(0xFF070218);
  static const well = Color(0xFF0B0524);
  static const panel = Color(0xCC12062E);
  static const cyan = Color(0xFF00D4FF);
  static const pink = Color(0xFFFF2BD6);
  static const magenta = Color(0xFFFF3FA8);
  static const gold = Color(0xFFFFD24A);
  static const electric = Color(0xFF4B7CFF);
  static const led = Color(0xFF7CFF6B);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: cyan,
          secondary: pink,
          surface: ink,
        ),
        fontFamily: 'sans-serif',
      );

  static TextStyle glow(Color c, {double size = 16, FontWeight w = FontWeight.w800}) {
    return TextStyle(
      fontSize: size,
      fontWeight: w,
      color: Colors.white,
      letterSpacing: 1.1,
      height: 1.05,
      shadows: [
        Shadow(color: c, blurRadius: 6),
        Shadow(color: c.withValues(alpha: 0.75), blurRadius: 14),
        Shadow(color: c.withValues(alpha: 0.4), blurRadius: 22),
      ],
    );
  }

  static List<BoxShadow> neon(Color c, {double blur = 16}) => [
        BoxShadow(color: c.withValues(alpha: 0.55), blurRadius: blur, spreadRadius: 1),
        BoxShadow(color: c.withValues(alpha: 0.25), blurRadius: blur * 1.8),
      ];
}
