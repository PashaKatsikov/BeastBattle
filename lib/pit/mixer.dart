import 'dart:typed_data';

// Beast Battle string mixer.
// sdbm seed, splitmix32 keystream, low byte, position mask (i * 13 + 0x27).
// Salt and stride belong to this project only. Re-run tool/byte_pack.dart
// after either value changes.

const String _salt = 'Bb9*kR4w#mT7-Qx2';
const int _stride = 41;

Uint8List _keystream() {
  int hash = 0;
  for (final int unit in _salt.codeUnits) {
    hash = (unit + (hash << 6) + (hash << 16) - hash) & 0xFFFFFFFF;
  }
  int state = hash == 0 ? 0xA5A5A5A5 : hash;
  final Uint8List key = Uint8List(_stride);
  for (int i = 0; i < _stride; i++) {
    state = (state + 0x9E3779B9) & 0xFFFFFFFF;
    int z = state;
    z = (z ^ (z >> 16)) & 0xFFFFFFFF;
    z = (z * 0x85EBCA6B) & 0xFFFFFFFF;
    z = (z ^ (z >> 13)) & 0xFFFFFFFF;
    z = (z * 0xC2B2AE35) & 0xFFFFFFFF;
    z = (z ^ (z >> 16)) & 0xFFFFFFFF;
    key[i] = z & 0xFF;
  }
  return key;
}

final Uint8List _stream = _keystream();

String unveil(List<int> packed) {
  if (packed.isEmpty) return '';
  final Uint8List out = Uint8List(packed.length);
  for (int i = 0; i < packed.length; i++) {
    out[i] = (packed[i] ^ _stream[i % _stride] ^ ((i * 13 + 0x27) & 0xFF)) & 0xFF;
  }
  return String.fromCharCodes(out);
}
