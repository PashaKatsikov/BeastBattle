import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../skin.dart';
import '../slot/math.dart';
import '../slot/glyphs.dart';

/// Frame art is 550×351. Inner wells measured from the PNG.
const _frameW = 550.0;
const _frameH = 351.0;
const _wellTop = 86.0 / _frameH;
const _wellH = 240.0 / _frameH;
const _cols = [
  (24.0 / _frameW, 95.0 / _frameW),
  (125.0 / _frameW, 96.0 / _frameW),
  (227.0 / _frameW, 96.0 / _frameW),
  (329.0 / _frameW, 94.0 / _frameW),
  (429.0 / _frameW, 97.0 / _frameW),
];

class ReelBank extends StatefulWidget {
  const ReelBank({
    super.key,
    required this.spinSeq,
    required this.from,
    required this.landing,
    required this.glow,
    required this.skip,
    required this.spinning,
    required this.onSettled,
  });

  final int spinSeq;
  final List<List<Sym>> from;
  final List<List<Sym>> landing;
  final Set<int> glow;
  final bool skip;
  final bool spinning;
  final VoidCallback onSettled;

  @override
  State<ReelBank> createState() => _ReelBankState();
}

class _ReelBankState extends State<ReelBank> {
  var _done = 0;
  var _skipFired = -1;

  void _maybeSkip() {
    if (widget.spinning && widget.skip && _skipFired != widget.spinSeq) {
      _skipFired = widget.spinSeq;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSettled();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _maybeSkip();
  }

  @override
  void didUpdateWidget(covariant ReelBank old) {
    super.didUpdateWidget(old);
    if (old.spinSeq != widget.spinSeq) {
      _done = 0;
    }
    _maybeSkip();
  }

  void _reelStopped() {
    _done++;
    if (_done >= nReels) widget.onSettled();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _frameW / _frameH,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: w * _cols.first.$1,
                top: h * _wellTop,
                width: w * (_cols.last.$1 + _cols.last.$2 - _cols.first.$1),
                height: h * _wellH,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF08041C),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x8800D4FF),
                        blurRadius: 18,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < nReels; i++)
                Positioned(
                  left: w * _cols[i].$1,
                  top: h * _wellTop,
                  width: w * _cols[i].$2,
                  height: h * _wellH,
                  child: !widget.spinning || widget.skip
                      ? _StaticReel(
                          cells: widget.spinning ? widget.landing[i] : widget.from[i],
                          glow: widget.glow,
                          reel: i,
                        )
                      : _SpinReel(
                          key: ValueKey('reel-$i-${widget.spinSeq}'),
                          start: widget.from[i],
                          end: widget.landing[i],
                          delay: Duration(milliseconds: 70 * i),
                          duration: Duration(milliseconds: 980 + i * 260),
                          glow: widget.glow,
                          reel: i,
                          onStop: _reelStopped,
                        ),
                ),
              Image.asset(
                Pics.frame,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StaticReel extends StatelessWidget {
  const _StaticReel({
    required this.cells,
    required this.glow,
    required this.reel,
  });

  final List<Sym> cells;
  final Set<int> glow;
  final int reel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < nRows; row++)
          Expanded(
            child: SymbolCell(
              sym: cells[row],
              hot: glow.contains(reel * nRows + row),
            ),
          ),
      ],
    );
  }
}

class _SpinReel extends StatefulWidget {
  const _SpinReel({
    super.key,
    required this.start,
    required this.end,
    required this.delay,
    required this.duration,
    required this.glow,
    required this.reel,
    required this.onStop,
  });

  final List<Sym> start;
  final List<Sym> end;
  final Duration delay;
  final Duration duration;
  final Set<int> glow;
  final int reel;
  final VoidCallback onStop;

  @override
  State<_SpinReel> createState() => _SpinReelState();
}

class _SpinReelState extends State<_SpinReel> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<Sym> _band;
  var _fired = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.reel * 917 + widget.end.hashCode);
    final pad = 16 + widget.reel * 6;
    _band = [
      ...widget.start,
      for (var i = 0; i < pad; i++) Sym.values[rng.nextInt(Sym.values.length)],
      ...widget.end,
    ];
    _c = AnimationController(vsync: this, duration: widget.duration);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_fired) {
        _fired = true;
        HapticFeedback.lightImpact();
        widget.onStop();
      }
    });
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        final maxOff = (_band.length - nRows).toDouble();
        final off = t * maxOff;
        return _BandView(
          band: _band,
          offset: off,
          glow: widget.glow,
          reel: widget.reel,
          settled: _c.isCompleted,
        );
      },
    );
  }
}

class _BandView extends StatelessWidget {
  const _BandView({
    required this.band,
    required this.offset,
    required this.glow,
    required this.reel,
    required this.settled,
  });

  final List<Sym> band;
  final double offset;
  final Set<int> glow;
  final int reel;
  final bool settled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxHeight / nRows;
        final base = offset.floor();
        final frac = offset - base;
        return ClipRect(
          child: Stack(
            children: [
              for (var i = -1; i <= nRows; i++)
                Positioned(
                  top: (i - frac) * cell,
                  left: 0,
                  right: 0,
                  height: cell,
                  child: SymbolCell(
                    sym: band[(base + i).clamp(0, band.length - 1)],
                    hot: settled && glow.contains(reel * nRows + i),
                    blur: !settled && frac > 0.02,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SymbolCell extends StatefulWidget {
  const SymbolCell({
    super.key,
    required this.sym,
    this.hot = false,
    this.blur = false,
  });

  final Sym sym;
  final bool hot;
  final bool blur;

  @override
  State<SymbolCell> createState() => _SymbolCellState();
}

class _SymbolCellState extends State<SymbolCell> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  @override
  void initState() {
    super.initState();
    if (widget.hot) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SymbolCell old) {
    super.didUpdateWidget(old);
    if (widget.hot && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.hot && _c.isAnimating) {
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
    Widget img = Padding(
      padding: const EdgeInsets.all(2),
      child: Image.asset(
        widget.sym.art,
        fit: BoxFit.contain,
        filterQuality: widget.blur ? FilterQuality.low : FilterQuality.high,
      ),
    );
    if (widget.blur) {
      img = Opacity(opacity: 0.88, child: img);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = widget.hot ? _c.value : 0.0;
        return Transform.scale(
          scale: 1 + t * 0.05,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: widget.hot
                  ? Border.all(
                      color: Color.lerp(const Color(0xCCFFD24A), Colors.white, t * 0.55)!,
                      width: 2,
                    )
                  : null,
              color: widget.hot ? Skin.gold.withValues(alpha: 0.12 + t * 0.10) : null,
            ),
            child: child,
          ),
        );
      },
      child: img,
    );
  }
}
