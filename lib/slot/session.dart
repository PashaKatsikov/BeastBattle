import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'math.dart';
import 'symbols.dart';

class QaHooks {
  bool skipReels = false;
  List<List<Sym>>? forced;
}

class Wallet {
  static const bets = [9, 18, 45, 90, 180, 450, 900, 1800];

  int credits = 10000;
  int betIndex = 2;
  bool ageOk = false;

  int get bet => bets[betIndex];

  void betUp() {
    if (betIndex < bets.length - 1) betIndex++;
  }

  void betDown() {
    if (betIndex > 0) betIndex--;
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    credits = p.getInt('cr') ?? 10000;
    betIndex = (p.getInt('bi') ?? 2).clamp(0, bets.length - 1);
    ageOk = p.getBool('age') ?? false;
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('cr', credits);
    await p.setInt('bi', betIndex);
    await p.setBool('age', ageOk);
  }
}

class SlotSession extends ChangeNotifier {
  final wallet = Wallet();
  final machine = Machine();
  final qa = QaHooks();

  bool ageOk = false;
  bool busy = false;
  bool auto = false;
  bool lastUsedFree = false;
  int freeLeft = 0;
  int freeBank = 0;
  int lastWin = 0;
  int spinSeq = 0;
  SpinResult? last;
  SpinResult? pending;
  List<List<Sym>> grid = idleGrid();

  bool get inFree => freeLeft > 0;
  bool get canAfford => wallet.credits >= (inFree ? 0 : wallet.bet);
  bool get canSpin => !busy && canAfford;

  Future<void> boot() async {
    await wallet.load();
    ageOk = wallet.ageOk;
  }

  Future<void> acceptAge() async {
    ageOk = true;
    wallet.ageOk = true;
    await wallet.persist();
    notifyListeners();
  }

  void bumpBet(int dir) {
    if (busy || inFree) return;
    if (dir > 0) {
      wallet.betUp();
    } else {
      wallet.betDown();
    }
    wallet.persist();
    notifyListeners();
  }

  void setBetIndex(int i) {
    if (busy || inFree) return;
    wallet.betIndex = i.clamp(0, Wallet.bets.length - 1);
    wallet.persist();
    notifyListeners();
  }

  void toggleAuto() {
    auto = !auto;
    notifyListeners();
  }

  void stopAuto() {
    if (!auto) return;
    auto = false;
    notifyListeners();
  }

  void topUp([int amount = 5000]) {
    wallet.credits += amount;
    wallet.persist();
    notifyListeners();
  }

  void setCredits(int v) {
    wallet.credits = v;
    wallet.persist();
    notifyListeners();
  }

  SpinResult? pull() {
    if (busy) return null;
    lastUsedFree = freeLeft > 0;
    final cost = lastUsedFree ? 0 : wallet.bet;
    if (wallet.credits < cost) {
      auto = false;
      notifyListeners();
      return null;
    }

    busy = true;
    lastWin = 0;
    if (!lastUsedFree) {
      wallet.credits -= cost;
    }

    final g = qa.forced ?? machine.spin();
    qa.forced = null;
    final result = evaluate(g, wallet.bet);
    pending = result;
    spinSeq++;
    notifyListeners();
    return result;
  }

  void land() {
    final r = pending;
    if (r == null) return;
    grid = r.grid;
    last = r;
    lastWin = r.total;
    wallet.credits += r.total;
    if (lastUsedFree) {
      if (freeLeft > 0) freeLeft--;
      freeBank += r.total;
    } else {
      freeBank = r.freeAwarded > 0 ? r.total : 0;
    }
    if (r.freeAwarded > 0) {
      freeLeft += r.freeAwarded;
    }
    pending = null;
    busy = false;
    wallet.persist();
    notifyListeners();
  }

  void skipToResult() {
    final r = pull();
    if (r == null) return;
    land();
  }

  void ping() => notifyListeners();
}
