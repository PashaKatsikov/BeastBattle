import 'package:flutter_test/flutter_test.dart';

import 'package:beast_battle/slot/math.dart';
import 'package:beast_battle/slot/glyphs.dart';

void main() {
  test('three cherries pay on the middle line', () {
    final grid = lineBoard(Sym.cherry, 3);
    final r = evaluate(grid, 90);
    expect(r.hits, isNotEmpty);
    expect(r.hits.first.sym, Sym.cherry);
    expect(r.hits.first.count, 3);
    expect(r.total, lineMult(Sym.cherry, 3) * 10);
  });

  test('three scatters award free spins', () {
    final r = evaluate(scatterBoard(3), 90);
    expect(r.scatterN, 3);
    expect(r.freeAwarded, scatterFree[3]);
    expect(r.scatterPay, scatterMult[3] * 90);
  });
}
