import 'package:flutter/material.dart';

class NeonSlab extends StatefulWidget {
  const NeonSlab({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.tight = false,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double? width;
  final bool tight;
  final IconData? icon;
  final bool busy;

  @override
  State<NeonSlab> createState() => _NeonSlabState();
}

class _NeonSlabState extends State<NeonSlab> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.busy ? null : (_) => setState(() => _scale = 0.92),
      onTapCancel: widget.busy ? null : () => setState(() => _scale = 1),
      onTapUp: widget.busy
          ? null
          : (_) {
              setState(() => _scale = 1);
              widget.onPressed();
            },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.width,
          height: widget.tight ? 46 : 54,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF00D4FF), Color(0xFF4B7CFF), Color(0xFFFF2BD6)],
            ),
            border: Border.all(color: const Color(0xB3FFFFFF), width: 1.4),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x8800D4FF), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (widget.icon != null) ...<Widget>[
                      Icon(widget.icon, color: Colors.white, size: widget.tight ? 18 : 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.tight ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class GhostSlab extends StatefulWidget {
  const GhostSlab({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.tight = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double? width;
  final bool tight;

  @override
  State<GhostSlab> createState() => _GhostSlabState();
}

class _GhostSlabState extends State<GhostSlab> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.width,
          height: widget.tight ? 46 : 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0x2EFFFFFF),
            border: Border.all(color: const Color(0x99FFFFFF), width: 1.3),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.tight ? 14 : 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
