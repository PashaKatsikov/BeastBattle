import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../session_scope.dart';
import '../skin.dart';
import '../slot/session.dart';
import '../widgets/bits.dart';
import '../widgets/reels.dart';
import 'pay_sheet.dart';
import 'knobs.dart';

class Floor extends StatefulWidget {
  const Floor({super.key});

  @override
  State<Floor> createState() => _FloorState();
}

class _FloorState extends State<Floor> with WidgetsBindingObserver {
  var _waitingAuto = false;
  _Banner? _banner;
  var _shownSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      SessionScope.read(context).stopAuto();
    }
  }

  void _spin() {
    if (_banner != null) return;
    final r = SessionScope.read(context).pull();
    if (r == null) return;
    HapticFeedback.selectionClick();
  }

  void _onLanded() {
    if (!mounted) return;
    final s = SessionScope.read(context);
    final wasInFree = s.inFree;
    s.land();
    final r = s.last;
    if (r == null) return;
    if (r.total > 0) HapticFeedback.mediumImpact();
    if (r.beastJackpot) {
      HapticFeedback.heavyImpact();
      _flash(_Banner.jackpot);
    } else if (r.freeAwarded > 0) {
      _flash(_Banner.free);
    } else if (wasInFree && !s.inFree && s.freeBank > 0) {
      _flash(_Banner.freeDone);
    } else if (r.total >= s.wallet.bet * 8 && r.total > 0) {
      _flash(_Banner.big);
    }
    _queueAuto();
  }

  void _flash(_Banner b) {
    setState(() {
      _banner = b;
      _shownSeq++;
    });
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _banner == b) setState(() => _banner = null);
    });
  }

  Future<void> _queueAuto() async {
    final s = SessionScope.read(context);
    if (!s.auto || _waitingAuto) return;
    _waitingAuto = true;
    final wait = _banner != null ? 2300 : (s.lastWin > 0 ? 720 : 260);
    await Future<void>.delayed(Duration(milliseconds: wait));
    _waitingAuto = false;
    if (!mounted) return;
    final now = SessionScope.read(context);
    if (now.auto && now.canSpin && !now.busy) _spin();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.read(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final s = session;
        return _buildFloor(context, s);
      },
    );
  }

  Widget _buildFloor(BuildContext context, SlotSession s) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) s.stopAuto();
      },
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Pics.bgPortrait, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66070218), Color(0x22070218), Color(0x99070218)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Row(
                    children: [
                      IconOrb(
                        icon: Icons.arrow_back,
                        onTap: () {
                          s.stopAuto();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      CreditChip(
                        credits: s.wallet.credits,
                        onTap: s.wallet.credits < s.wallet.bet ? () => s.topUp() : null,
                      ),
                      const SizedBox(width: 8),
                      IconOrb(
                        icon: Icons.menu_book_outlined,
                        color: Skin.gold,
                        onTap: () => showPayTable(context),
                      ),
                      const SizedBox(width: 8),
                      IconOrb(
                        icon: Icons.settings,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const KnobsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.inFree)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xE6140830),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Skin.gold.withValues(alpha: 0.85)),
                        boxShadow: Skin.neon(Skin.gold, blur: 10),
                      ),
                      child: Text(
                        s.freeLeft <= 1
                            ? 'LAST FREE SPIN'
                            : 'FREE SPINS  ${s.freeLeft}'
                                '${s.freeBank > 0 ? '  •  WIN ${fmtCredits(s.freeBank)}' : ''}',
                        style: Skin.glow(Skin.gold, size: 13),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ReelBank(
                          spinSeq: s.spinSeq,
                          from: s.grid,
                          landing: s.pending?.grid ?? s.grid,
                          glow: s.pending == null ? (s.last?.glowKeys ?? const {}) : const {},
                          skip: s.qa.skipReels,
                          spinning: s.pending != null,
                          onSettled: _onLanded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: TweenAnimationBuilder<int>(
                                key: ValueKey('${s.spinSeq}-${s.lastWin}'),
                                tween: IntTween(begin: 0, end: s.lastWin),
                                duration: Duration(milliseconds: s.lastWin > 0 ? 550 : 0),
                                builder: (context, v, _) => LedReadout(
                                  caption: 'WIN',
                                  value: fmtCredits(v),
                                  accent: s.lastWin > 0 ? Skin.gold : Skin.led,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: LedReadout(
                                caption: 'BET  •  9 LINES',
                                value: fmtCredits(s.wallet.bet),
                                accent: Skin.cyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _BetRow(
                        enabled: !s.busy && !s.inFree,
                        bet: s.wallet.bet,
                        onDown: () => s.bumpBet(-1),
                        onUp: () => s.bumpBet(1),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          NeonTap(
                            enabled: !s.busy && _banner == null,
                            onTap: () {
                              s.toggleAuto();
                              if (s.auto && s.canSpin) _spin();
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(Pics.auto, height: 74),
                                if (s.auto)
                                  Positioned(
                                    bottom: 0,
                                    child: Text('ON', style: Skin.glow(Skin.gold, size: 11)),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          NeonTap(
                            enabled: (s.canSpin && _banner == null) || (s.auto && s.busy),
                            onTap: () {
                              if (s.auto && s.busy) {
                                s.stopAuto();
                                return;
                              }
                              if (!s.canAfford) {
                                s.topUp();
                                return;
                              }
                              _spin();
                            },
                            child: IdlePulse(
                              active: !s.busy && _banner == null,
                              child: Image.asset(Pics.spin, height: 104),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!s.inFree && s.wallet.credits < Wallet.bets.first && !s.busy)
            _Broke(onFill: () => s.topUp()),
          if (_banner != null)
            Positioned.fill(
              child: _WinSplash(
                key: ValueKey(_shownSeq),
                kind: _banner!,
                amount: switch (_banner!) {
                  _Banner.free => s.last?.freeAwarded ?? 0,
                  _Banner.freeDone => s.freeBank,
                  _Banner.jackpot || _Banner.big => s.lastWin,
                },
              ),
            ),
        ],
      ),
      ),
    );
  }
}

enum _Banner { big, jackpot, free, freeDone }

class _BetRow extends StatelessWidget {
  const _BetRow({
    required this.enabled,
    required this.bet,
    required this.onDown,
    required this.onUp,
  });

  final bool enabled;
  final int bet;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Step(label: '−', onTap: enabled ? onDown : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text('BET', style: Skin.glow(Skin.pink, size: 11)),
                Text(fmtCredits(bet), style: Skin.glow(Skin.gold, size: 16)),
              ],
            ),
          ),
          _Step(label: '+', onTap: enabled ? onUp : null),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeonTap(
      onTap: onTap,
      enabled: onTap != null,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Skin.pink, width: 1.4),
          color: const Color(0xCC12062E),
          boxShadow: Skin.neon(Skin.pink, blur: 8),
        ),
        child: Text(label, style: Skin.glow(Skin.pink, size: 22)),
      ),
    );
  }
}

class _Broke extends StatelessWidget {
  const _Broke({required this.onFill});
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x88000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xF2140630),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Skin.gold),
            boxShadow: Skin.neon(Skin.gold),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OUT OF CREDITS', style: Skin.glow(Skin.gold, size: 18)),
              const SizedBox(height: 8),
              const Text(
                'House pack — +5,000 credits.\nNo purchase. Social play only.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 16),
              PillBtn(label: 'TAKE PACK', color: Skin.gold, onTap: onFill),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinSplash extends StatefulWidget {
  const _WinSplash({super.key, required this.kind, required this.amount});
  final _Banner kind;
  final int amount;

  @override
  State<_WinSplash> createState() => _WinSplashState();
}

class _WinSplashState extends State<_WinSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.kind) {
      _Banner.jackpot => 'BEAST JACKPOT',
      _Banner.big => 'BIG WIN',
      _Banner.free => '${widget.amount} FREE SPINS',
      _Banner.freeDone => 'FREE SPINS TOTAL',
    };
    final sub = widget.kind == _Banner.free ? 'SCATTER PAYS' : fmtCredits(widget.amount);
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: ScaleTransition(
          scale: Tween(begin: 0.86, end: 1.0).animate(
            CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              color: const Color(0xF2140630),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Skin.gold, width: 1.6),
              boxShadow: Skin.neon(Skin.gold, blur: 22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(Pics.logo, height: 48),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center, style: Skin.glow(Skin.gold, size: 26)),
                const SizedBox(height: 8),
                Text(sub, style: Skin.glow(Skin.cyan, size: 22)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
