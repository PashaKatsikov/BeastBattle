import 'package:flutter/material.dart';

import '../session_scope.dart';
import '../skin.dart';
import '../slot/math.dart';
import '../slot/glyphs.dart';

Future<void> showPayTable(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const PaySheet(),
  );
}

class PaySheet extends StatelessWidget {
  const PaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bet = SessionScope.of(context).wallet.bet;
    final line = bet ~/ nLines;
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, sc) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xF50C0428),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: Skin.cyan.withValues(alpha: 0.6)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('PAYTABLE', textAlign: TextAlign.center, style: Skin.glow(Skin.cyan, size: 22)),
              const SizedBox(height: 4),
              Text(
                '9 LINES  •  BET $bet  •  LINE $line',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              const Text(
                'WILD substitutes for every symbol except SCATTER. Lines pay left to right. SCATTER pays anywhere and awards Free Spins.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, height: 1.35, fontSize: 12),
              ),
              const SizedBox(height: 10),
              for (final s in [
                Sym.wild,
                Sym.seven,
                Sym.diamond,
                Sym.coins,
                Sym.bar,
                Sym.bell,
                Sym.grape,
                Sym.lemon,
                Sym.cherry,
              ])
                _RowPay(sym: s, lineBet: line),
              const SizedBox(height: 10),
              _ScatterBlock(totalBet: bet),
              const SizedBox(height: 8),
            ],
            ),
          ),
        );
      },
    );
  }
}

class _RowPay extends StatelessWidget {
  const _RowPay({required this.sym, required this.lineBet});
  final Sym sym;
  final int lineBet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset(sym.art, width: 46, height: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final n in [3, 4, 5])
                  Text(
                    '$n = ${lineMult(sym, n) * lineBet}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScatterBlock extends StatelessWidget {
  const _ScatterBlock({required this.totalBet});
  final int totalBet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Skin.pink.withValues(alpha: 0.6)),
        color: const Color(0x6612062E),
      ),
      child: Row(
        children: [
          Image.asset(Sym.scatter.art, width: 64, height: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SCATTER', style: Skin.glow(Skin.pink, size: 16)),
                const SizedBox(height: 4),
                Text(
                  '3 = ${scatterMult[3] * totalBet} + ${scatterFree[3]} FS\n'
                  '4 = ${scatterMult[4] * totalBet} + ${scatterFree[4]} FS\n'
                  '5 = ${scatterMult[5] * totalBet} + ${scatterFree[5]} FS',
                  style: const TextStyle(color: Colors.white, height: 1.35, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
