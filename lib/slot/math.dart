import 'dart:math';

import 'glyphs.dart';

const nReels = 5;
const nRows = 3;
const nLines = 9;

// 9 classic video-slot lines, row indices top→bottom.
const List<List<int>> paylines = [
  [1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0],
  [2, 2, 2, 2, 2],
  [0, 1, 2, 1, 0],
  [2, 1, 0, 1, 2],
  [0, 0, 1, 2, 2],
  [2, 2, 1, 0, 0],
  [1, 0, 1, 0, 1],
  [1, 2, 1, 2, 1],
];

// Multipliers of line bet for 0..5 of a kind.
const Map<Sym, List<int>> _pays = {
  Sym.cherry: [0, 0, 0, 4, 12, 40],
  Sym.lemon: [0, 0, 0, 4, 12, 40],
  Sym.grape: [0, 0, 0, 5, 15, 50],
  Sym.bell: [0, 0, 0, 8, 25, 70],
  Sym.bar: [0, 0, 0, 10, 30, 90],
  Sym.coins: [0, 0, 0, 12, 40, 120],
  Sym.diamond: [0, 0, 0, 18, 60, 200],
  Sym.seven: [0, 0, 0, 30, 120, 400],
  Sym.wild: [0, 0, 0, 40, 150, 600],
};

// Scatter pays in multiples of TOTAL bet, anywhere on the board.
const scatterMult = [0, 0, 0, 2, 8, 25];
const scatterFree = [0, 0, 0, 8, 12, 20];

int lineMult(Sym s, int count) {
  if (count < 3) return 0;
  return _pays[s]![count.clamp(0, 5)];
}

class LineHit {
  LineHit({
    required this.line,
    required this.sym,
    required this.count,
    required this.pay,
    required this.cells,
  });

  final int line;
  final Sym sym;
  final int count;
  final int pay;
  final List<(int reel, int row)> cells;
}

class SpinResult {
  SpinResult({
    required this.grid,
    required this.hits,
    required this.scatterN,
    required this.scatterPay,
    required this.freeAwarded,
  });

  final List<List<Sym>> grid;
  final List<LineHit> hits;
  final int scatterN;
  final int scatterPay;
  final int freeAwarded;

  int get total => scatterPay + hits.fold<int>(0, (a, h) => a + h.pay);

  Set<int> get glowKeys {
    final s = <int>{};
    for (final h in hits) {
      for (final (r, row) in h.cells) {
        s.add(r * nRows + row);
      }
    }
    if (scatterN >= 3) {
      for (var r = 0; r < nReels; r++) {
        for (var row = 0; row < nRows; row++) {
          if (grid[r][row] == Sym.scatter) s.add(r * nRows + row);
        }
      }
    }
    return s;
  }

  bool get beastJackpot {
    if (hits.isEmpty) return false;
    return hits.any((h) => h.count == 5 && (h.sym == Sym.seven || h.sym == Sym.wild));
  }
}

SpinResult evaluate(List<List<Sym>> grid, int totalBet) {
  final lineBet = totalBet ~/ nLines;
  final hits = <LineHit>[];

  for (var i = 0; i < paylines.length; i++) {
    final rows = paylines[i];
    final cells = <Sym>[
      for (var r = 0; r < nReels; r++) grid[r][rows[r]],
    ];
    final hit = _walkLine(i, cells, rows, lineBet);
    if (hit != null) hits.add(hit);
  }

  var scat = 0;
  for (final reel in grid) {
    for (final s in reel) {
      if (s == Sym.scatter) scat++;
    }
  }
  if (scat > 5) scat = 5;
  final sPay = scat >= 3 ? scatterMult[scat] * totalBet : 0;
  final fs = scat >= 3 ? scatterFree[scat] : 0;

  return SpinResult(
    grid: grid,
    hits: hits,
    scatterN: scat,
    scatterPay: sPay,
    freeAwarded: fs,
  );
}

LineHit? _walkLine(int line, List<Sym> cells, List<int> rows, int lineBet) {
  if (cells[0] == Sym.scatter) return null;

  Sym? base;
  var count = 0;
  for (final s in cells) {
    if (s == Sym.scatter) break;
    if (s == Sym.wild) {
      count++;
      continue;
    }
    if (base == null) {
      base = s;
      count++;
      continue;
    }
    if (s == base) {
      count++;
      continue;
    }
    break;
  }
  if (count < 3) return null;
  final key = base ?? Sym.wild;
  final pay = lineMult(key, count) * lineBet;
  if (pay <= 0) return null;
  return LineHit(
    line: line,
    sym: key,
    count: count,
    pay: pay,
    cells: [for (var r = 0; r < count; r++) (r, rows[r])],
  );
}

class Machine {
  Machine([Random? rng]) : _rng = rng ?? Random();

  final Random _rng;
  late final List<List<Sym>> strips = List.generate(nReels, _buildStrip);

  List<List<Sym>> spin() {
    return List.generate(nReels, (r) {
      final strip = strips[r];
      final stop = _rng.nextInt(strip.length);
      return List.generate(nRows, (row) => strip[(stop + row) % strip.length]);
    });
  }

  List<Sym> _buildStrip(int reel) {
    // Slight per-reel bias so the five columns don't feel cloned.
    final bag = <Sym>[
      ...List.filled(8 - (reel % 2), Sym.cherry),
      ...List.filled(7, Sym.lemon),
      ...List.filled(7, Sym.grape),
      ...List.filled(6, Sym.bell),
      ...List.filled(5, Sym.bar),
      ...List.filled(5, Sym.coins),
      ...List.filled(4, Sym.diamond),
      ...List.filled(3, Sym.seven),
      ...List.filled(reel == 2 ? 4 : 3, Sym.wild),
      ...List.filled(2, Sym.scatter),
    ];
    bag.shuffle(_rng);
    return bag;
  }
}

List<List<Sym>> gridOf(Sym s) =>
    List.generate(nReels, (_) => List.filled(nRows, s));

List<List<Sym>> _blank() => [
      [Sym.cherry, Sym.lemon, Sym.grape],
      [Sym.bell, Sym.bar, Sym.coins],
      [Sym.diamond, Sym.seven, Sym.lemon],
      [Sym.grape, Sym.bell, Sym.cherry],
      [Sym.bar, Sym.coins, Sym.diamond],
    ];

List<List<Sym>> scatterBoard(int n) {
  final g = _blank();
  var left = n;
  for (var r = 0; r < nReels && left > 0; r++) {
    g[r][1] = Sym.scatter;
    left--;
  }
  return g;
}

List<List<Sym>> lineBoard(Sym s, int count) {
  final g = _blank();
  for (var r = 0; r < nReels; r++) {
    g[r][1] = r < count ? s : (r == 3 ? Sym.lemon : Sym.bar);
  }
  return g;
}
