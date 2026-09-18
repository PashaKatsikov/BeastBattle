import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'boot/load_screen.dart';
import 'session_scope.dart';
import 'skin.dart';
import 'slot/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final session = SlotSession();
  await session.boot();
  runApp(BeastBattle(session: session));
}

class BeastBattle extends StatelessWidget {
  const BeastBattle({super.key, required this.session});

  final SlotSession session;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: session,
      child: MaterialApp(
        title: 'Beast Battle',
        debugShowCheckedModeBanner: false,
        theme: Skin.theme,
        home: const LoadScreen(),
      ),
    );
  }
}
