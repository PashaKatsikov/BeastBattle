enum Lane {
  hosted,
  cabinet,
  fresh;

  static Lane read(String? raw) {
    switch (raw) {
      case 'hosted':
        return Lane.hosted;
      case 'cabinet':
        return Lane.cabinet;
      default:
        return Lane.fresh;
    }
  }

  String write() => name;
}
