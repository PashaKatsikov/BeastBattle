import 'package:flutter/material.dart';

import 'shell_art.dart';
import 'slab.dart';

class DarkLine extends StatefulWidget {
  const DarkLine({super.key, required this.retryBuilder});

  final WidgetBuilder retryBuilder;

  @override
  State<DarkLine> createState() => _DarkLineState();
}

class _DarkLineState extends State<DarkLine> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.retryBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width > size.height;
    final String art = wide ? ShellArt.offlineWide : ShellArt.offlineTall;
    final double width = wide ? size.width * 0.32 : (size.width * 0.7).clamp(240, 360);
    final double bottom = size.height * (wide ? 0.09 : 0.075);
    final Widget button = NeonSlab(
      label: 'Try Again',
      icon: Icons.refresh_rounded,
      width: width,
      tight: wide,
      busy: _busy,
      onPressed: _retry,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070218),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(art, fit: BoxFit.cover, width: size.width, height: size.height),
          if (wide)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom,
              child: Center(child: button),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: button,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
