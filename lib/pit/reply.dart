class PitReply {
  const PitReply({
    required this.admitted,
    this.target,
    this.note,
    this.expiresAt,
  });

  final bool admitted;
  final String? target;
  final String? note;
  final int? expiresAt;

  bool get hasTarget => target != null && target!.isNotEmpty;

  factory PitReply.parse(Map<String, dynamic> map) {
    return PitReply(
      admitted: map['ok'] as bool? ?? false,
      target: map['url'] as String?,
      note: map['message'] as String?,
      expiresAt: map['expires'] as int?,
    );
  }

  factory PitReply.fault(String reason) =>
      PitReply(admitted: false, note: reason);
}
