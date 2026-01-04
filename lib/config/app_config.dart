import 'package:flutter_dotenv/flutter_dotenv.dart';

enum RtcProvider { agora, livekit }

class AppConfig {
  static String get agoraAppId => _readEnv('AGORA_APP_ID');
  static String get agoraToken => _readEnv('AGORA_TOKEN');
  static String get agoraChannel => _readEnv('AGORA_CHANNEL').trim().isNotEmpty
      ? _readEnv('AGORA_CHANNEL').trim()
      : 'classroom';
  static int get agoraUid {
    final raw = _readEnv('AGORA_UID').trim();
    if (raw.isEmpty) {
      return 0;
    }
    return int.tryParse(raw) ?? 0;
  }

  static String get livekitUrl => _readEnv('LIVEKIT_URL');
  static String get livekitToken => _readEnv('LIVEKIT_TOKEN');
  static String get livekitRoomLabel =>
      _readEnv('LIVEKIT_ROOM').trim().isNotEmpty
          ? _readEnv('LIVEKIT_ROOM').trim()
          : 'classroom';

  static RtcProvider get rtcProvider {
    final provider = _readEnv('RTC_PROVIDER').toLowerCase();
    if (provider == 'livekit') {
      return RtcProvider.livekit;
    }
    return RtcProvider.agora;
  }

  static bool get demoMode => _readEnv('DEMO_MODE').toLowerCase() == 'true';

  static bool get hasAgoraConfig => agoraAppId.isNotEmpty;
  static bool get hasLivekitConfig =>
      livekitUrl.isNotEmpty && livekitToken.isNotEmpty;

  static String _readEnv(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env[key] ?? '';
  }
}
