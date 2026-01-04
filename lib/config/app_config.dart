import 'package:flutter_dotenv/flutter_dotenv.dart';

enum RtcProvider { agora, livekit }

class AppConfig {
  static const String _agoraAppIdDefine =
      String.fromEnvironment('AGORA_APP_ID', defaultValue: '');
  static const String _agoraTokenDefine =
      String.fromEnvironment('AGORA_TOKEN', defaultValue: '');
  static const String _agoraChannelDefine =
      String.fromEnvironment('AGORA_CHANNEL', defaultValue: '');
  static const String _agoraUidDefine =
      String.fromEnvironment('AGORA_UID', defaultValue: '');
  static const String _livekitUrlDefine =
      String.fromEnvironment('LIVEKIT_URL', defaultValue: '');
  static const String _livekitTokenDefine =
      String.fromEnvironment('LIVEKIT_TOKEN', defaultValue: '');
  static const String _livekitRoomDefine =
      String.fromEnvironment('LIVEKIT_ROOM', defaultValue: '');
  static const String _rtcProviderDefine =
      String.fromEnvironment('RTC_PROVIDER', defaultValue: '');
  static const String _demoModeDefine =
      String.fromEnvironment('DEMO_MODE', defaultValue: '');

  static String get agoraAppId =>
      _readDefineOrEnv(_agoraAppIdDefine, 'AGORA_APP_ID');
  static String get agoraToken =>
      _readDefineOrEnv(_agoraTokenDefine, 'AGORA_TOKEN');
  static String get agoraChannel {
    final channel =
        _readDefineOrEnv(_agoraChannelDefine, 'AGORA_CHANNEL').trim();
    return channel.isNotEmpty ? channel : 'classroom-demo';
  }
  static int get agoraUid {
    final raw = _readDefineOrEnv(_agoraUidDefine, 'AGORA_UID').trim();
    if (raw.isEmpty) {
      return 0;
    }
    return int.tryParse(raw) ?? 0;
  }

  static String get livekitUrl =>
      _readDefineOrEnv(_livekitUrlDefine, 'LIVEKIT_URL');
  static String get livekitToken =>
      _readDefineOrEnv(_livekitTokenDefine, 'LIVEKIT_TOKEN');
  static String get livekitRoomLabel {
    final room = _readDefineOrEnv(_livekitRoomDefine, 'LIVEKIT_ROOM').trim();
    return room.isNotEmpty ? room : 'classroom-demo';
  }

  static RtcProvider get rtcProvider {
    final provider =
        _readDefineOrEnv(_rtcProviderDefine, 'RTC_PROVIDER').toLowerCase();
    if (provider == 'livekit') {
      return RtcProvider.livekit;
    }
    return RtcProvider.agora;
  }

  static bool get demoMode =>
      _readDefineOrEnv(_demoModeDefine, 'DEMO_MODE').toLowerCase() == 'true';

  static bool get hasAgoraConfig => agoraAppId.isNotEmpty;
  static bool get hasLivekitConfig =>
      livekitUrl.isNotEmpty && livekitToken.isNotEmpty;

  static String _readDefineOrEnv(String defineValue, String envKey) {
    if (defineValue.isNotEmpty) {
      return defineValue;
    }
    return _readEnv(envKey);
  }

  static String _readEnv(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env[key] ?? '';
  }
}
