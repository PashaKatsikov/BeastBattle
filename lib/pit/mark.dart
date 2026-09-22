import '../skin.dart';
import 'packed.dart';

// Identity for the hosted branch.
// GAME THEME CATEGORY: slot
// Identity suffix is omitted until a partner asks for it on the user-agent.

class Mark {
  Mark._();

  /// Play application id. Must match `applicationId` and, once it arrives,
  /// `package_name` inside google-services.json.
  static const String bundleId = 'com.beastbattle.game';
  static const String storeId = 'com.beastbattle.game';
  static const String displayName = 'Beast Battle';
  static const String iosStoreNumericId = '';

  static String get gateEndpoint => openGate();
  static String get attributionDevKey => openDevKey();
  static String get messagingProjectId => openFirebaseProject();

  static const String privacyUrl = Pics.privacy;
  static const String supportUrl = Pics.support;

  static const int promoCooldownSeconds = 3 * 24 * 60 * 60;
  static const int organicRecheckSeconds = 6;
}
