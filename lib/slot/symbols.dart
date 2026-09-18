enum Sym {
  cherry,
  lemon,
  grape,
  bell,
  bar,
  coins,
  diamond,
  seven,
  wild,
  scatter;

  String get art => 'assets/game/symbols/$name.webp';

  bool get isWild => this == Sym.wild;
  bool get isScatter => this == Sym.scatter;
}

List<List<Sym>> idleGrid() => [
      [Sym.cherry, Sym.seven, Sym.grape],
      [Sym.wild, Sym.diamond, Sym.lemon],
      [Sym.scatter, Sym.bell, Sym.coins],
      [Sym.seven, Sym.bar, Sym.grape],
      [Sym.cherry, Sym.wild, Sym.bell],
    ];
