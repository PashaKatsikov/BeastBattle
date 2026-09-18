import 'package:flutter/material.dart';

import 'slot/session.dart';

class SessionScope extends InheritedNotifier<SlotSession> {
  const SessionScope({
    super.key,
    required SlotSession session,
    required super.child,
  }) : super(notifier: session);

  static SlotSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope missing');
    return scope!.notifier!;
  }

  static SlotSession read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope missing');
    return scope!.notifier!;
  }
}
