import 'mixer.dart';

// Packed endpoints and user-agent fragments.
// Produced by tool/byte_pack.dart. Do not hand-edit the arrays.

const List<int> _gateBytes = <int>[101, 199, 154, 254, 67, 29, 137, 129, 215, 110, 75, 162, 43, 81, 239, 192, 68, 253, 168, 253, 248, 180, 36, 163, 76, 27, 177, 231, 49, 251, 9, 231, 173, 54];

const List<int> _gcdBytes = <int>[101, 199, 154, 254, 67, 29, 137, 129, 210, 104, 78, 162, 59, 88, 160, 213, 64, 225, 190, 181, 248, 164, 47, 186, 77, 29, 186, 237, 123, 189, 20, 237, 183, 52, 155, 172, 84, 224, 111, 33, 114, 57, 184, 205, 141, 43, 29];

const List<int> _chromeBytes = <int>[60, 134, 222, 160, 0, 9, 145, 152, 129, 51, 4, 230, 108];

const List<int> _webkitBytes = <int>[56, 128, 217, 160, 3, 17];

const List<int> _devKeyBytes = <int>[79, 138, 190, 253, 120, 95, 225, 253, 130, 65, 77, 156, 53, 113, 251, 193, 70, 197, 249, 155, 196, 235];

const List<int> _firebaseBytes = <int>[59, 139, 221, 191, 0, 19, 150, 157, 141, 50, 31, 228];

const List<int> _relaySecretBytes = <int>[88, 131, 161, 183, 123, 19, 139, 131, 140, 97, 114, 163, 21, 94, 187, 249, 65, 196, 190, 177, 199, 142, 62, 177, 18, 79, 151, 178, 51, 144, 43, 251, 129, 0, 150, 248, 82, 229, 88, 4, 123, 87, 169];

const List<int> _uaMozillaBytes = <int>[64, 220, 148, 231, 92, 75, 199, 129, 128, 37, 26];

const List<int> _uaLinuxBytes = <int>[45, 155, 162, 231, 94, 82, 222, 149, 149, 74, 68, 181, 45, 92, 231, 208, 16];

const List<int> _uaBuildBytes = <int>[45, 241, 155, 231, 92, 67, 137];

const List<int> _uaCloseBytes = <int>[36, 147];

const List<int> _uaWebKitBytes = <int>[76, 195, 158, 226, 85, 112, 195, 204, 254, 98, 94, 254];

const List<int> _uaGeckoBytes = <int>[45, 155, 165, 198, 100, 106, 234, 130, 149, 103, 67, 186, 58, 19, 201, 209, 83, 250, 162, 250, 180];

const List<int> _uaChromeBytes = <int>[78, 219, 156, 225, 93, 66, 137];

const List<int> _uaSafariBytes = <int>[45, 254, 129, 236, 89, 75, 195, 142, 230, 106, 76, 176, 45, 90, 161];

const List<int> _fallbackUaBytes = <int>[64, 220, 148, 231, 92, 75, 199, 129, 128, 37, 26, 241, 119, 127, 231, 218, 69, 233, 246, 243, 213, 179, 46, 186, 12, 23, 177, 160, 101, 224, 65, 190, 144, 24, 218, 147, 50, 182, 63, 23, 51, 84, 187, 144, 207, 127, 29, 12, 235, 175, 103, 19, 158, 119, 55, 145, 145, 254, 162, 202, 206, 200, 129, 117, 188, 56, 227, 78, 248, 56, 164, 119, 160, 177, 28, 207, 24, 211, 166, 31, 115, 78, 91, 241, 143, 240, 186, 144, 0, 172, 163, 61, 57, 236, 20, 57, 19, 47, 133, 208, 136, 172, 202, 196, 8, 148, 218, 233, 106, 153, 75, 139, 48, 238, 197, 81, 42, 0, 225, 134, 10, 12, 86, 108, 185, 64, 47, 152, 132, 2, 205, 167, 45, 13, 243, 236, 133, 96, 66, 194, 225, 162, 163, 227];

String openGate() => unveil(_gateBytes);

String openGcdBase() => unveil(_gcdBytes);

String openChrome() => unveil(_chromeBytes);

String openWebKit() => unveil(_webkitBytes);

String openDevKey() => unveil(_devKeyBytes);

String openFirebaseProject() => unveil(_firebaseBytes);

String openRelaySecret() => unveil(_relaySecretBytes);

String openUaMozilla() => unveil(_uaMozillaBytes);

String openUaLinux() => unveil(_uaLinuxBytes);

String openUaBuild() => unveil(_uaBuildBytes);

String openUaClose() => unveil(_uaCloseBytes);

String openUaWebKit() => unveil(_uaWebKitBytes);

String openUaGecko() => unveil(_uaGeckoBytes);

String openUaChrome() => unveil(_uaChromeBytes);

String openUaSafari() => unveil(_uaSafariBytes);

String openFallbackUa() => unveil(_fallbackUaBytes);

String gcdQuery(String appId, String deviceId) {
  final String base = openGcdBase();
  if (base.isEmpty) return '';
  final String key = openDevKey();
  return '$base$appId?devkey=$key&device_id=$deviceId';
}
