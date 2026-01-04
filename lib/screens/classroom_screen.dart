import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../widgets/background_art.dart';
import '../widgets/chat_panel.dart';
import '../widgets/classroom_panel.dart';
import '../widgets/livekit_video_grid.dart';
import '../widgets/resource_panel.dart';
import '../widgets/staggered_reveal.dart';
import '../widgets/video_grid.dart';
import '../widgets/whiteboard.dart';

class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({super.key, this.enableRtc = true});

  final bool enableRtc;

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  livekit.Room? _livekitRoom;
  RtcEngine? _engine;
  final List<int> _remoteUids = [];
  bool _joined = false;
  bool _micOn = true;
  bool _camOn = true;
  bool _initializing = true;
  String? _errorMessage;
  ConnectionStateType? _connectionState;
  livekit.ConnectionState? _livekitState;

  late final RtcProvider _provider;
  late final String _appId;
  late final String _token;
  late final String _channelId;
  late final int _agoraUid;
  late final String _livekitUrl;
  late final String _livekitToken;
  late final String _livekitRoomLabel;

  @override
  void initState() {
    super.initState();
    _provider = AppConfig.rtcProvider;
    _appId = AppConfig.agoraAppId;
    _token = AppConfig.agoraToken;
    _channelId = AppConfig.agoraChannel;
    _agoraUid = AppConfig.agoraUid;
    _livekitUrl = AppConfig.livekitUrl;
    _livekitToken = AppConfig.livekitToken;
    _livekitRoomLabel = AppConfig.livekitRoomLabel;
    if (widget.enableRtc) {
      if (_provider == RtcProvider.livekit) {
        _initLivekit();
      } else {
        _initAgora();
      }
    } else {
      _initializing = false;
    }
  }

  Future<void> _initAgora() async {
    if (_appId.isEmpty) {
      setState(() {
        _errorMessage =
            'Missing AGORA_APP_ID. Add it to .env to start the video session.';
        _initializing = false;
      });
      return;
    }
    try {
      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: _appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _safeSetState(() {
              _joined = true;
              _connectionState = ConnectionStateType.connectionStateConnected;
            });
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            _safeSetState(() {
              if (!_remoteUids.contains(remoteUid)) {
                _remoteUids.add(remoteUid);
              }
            });
          },
          onUserOffline: (connection, remoteUid, reason) {
            _safeSetState(() => _remoteUids.remove(remoteUid));
          },
          onLeaveChannel: (connection, stats) {
            _safeSetState(() {
              _joined = false;
              _remoteUids.clear();
            });
          },
          onConnectionStateChanged: (connection, state, reason) {
            _safeSetState(() => _connectionState = state);
          },
          onError: (err, msg) {
            _safeSetState(() {
              _errorMessage = 'Agora error: ${err.name}. $msg';
            });
          },
        ),
      );

      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.enableVideo();
      await engine.enableAudio();

      _safeSetState(() {
        _engine = engine;
        _initializing = false;
      });
    } catch (err) {
      _safeSetState(() {
        _errorMessage = 'Agora init failed: $err';
        _initializing = false;
      });
    }
  }

  Future<void> _initLivekit() async {
    if (!AppConfig.hasLivekitConfig) {
      setState(() {
        _errorMessage =
            'Missing LIVEKIT_URL or LIVEKIT_TOKEN. Add them to .env to start the video session.';
        _initializing = false;
      });
      return;
    }

    final room = livekit.Room();
    room.addListener(_handleLivekitUpdate);

    setState(() {
      _livekitRoom = room;
      _livekitState = room.connectionState;
      _initializing = false;
    });
  }

  void _handleLivekitUpdate() {
    if (!mounted) return;
    setState(() {
      _livekitState = _livekitRoom?.connectionState;
    });
  }

  Future<void> _joinChannel() async {
    if (_provider == RtcProvider.livekit) {
      await _joinLivekit();
      return;
    }
    if (_engine == null || _joined) return;
    if (_channelId.trim().isEmpty) {
      _safeSetState(() {
        _errorMessage = 'Missing AGORA_CHANNEL. Set it in .env and try again.';
      });
      return;
    }
    try {
      await _ensurePreview();
      await _engine!.joinChannel(
        token: _token,
        channelId: _channelId,
        uid: _agoraUid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishCameraTrack: _camOn,
          publishMicrophoneTrack: _micOn,
        ),
      );
    } catch (err) {
      _safeSetState(() {
        _errorMessage = 'Join failed: $err';
      });
    }
  }

  Future<void> _leaveChannel() async {
    if (_provider == RtcProvider.livekit) {
      await _leaveLivekit();
      return;
    }
    if (_engine == null || !_joined) return;
    await _engine!.leaveChannel();
    setState(() {
      _joined = false;
      _remoteUids.clear();
      _connectionState = ConnectionStateType.connectionStateDisconnected;
    });
  }

  Future<void> _joinLivekit() async {
    final room = _livekitRoom;
    if (room == null) return;
    if (room.connectionState == livekit.ConnectionState.connected ||
        room.connectionState == livekit.ConnectionState.connecting) {
      return;
    }
    try {
      await room.connect(_livekitUrl, _livekitToken);
      await room.localParticipant?.setMicrophoneEnabled(_micOn);
      await room.localParticipant?.setCameraEnabled(_camOn);
    } catch (err) {
      setState(() {
        _errorMessage = 'LiveKit connect failed: $err';
      });
    }
  }

  Future<void> _leaveLivekit() async {
    final room = _livekitRoom;
    if (room == null) return;
    try {
      await room.disconnect();
    } catch (err) {
      setState(() {
        _errorMessage = 'LiveKit disconnect failed: $err';
      });
    }
    setState(() {
      _livekitState = livekit.ConnectionState.disconnected;
    });
  }

  Future<void> _toggleMic() async {
    setState(() => _micOn = !_micOn);
    if (_provider == RtcProvider.livekit) {
      await _livekitRoom?.localParticipant?.setMicrophoneEnabled(_micOn);
      return;
    }
    if (_engine == null) return;
    await _engine!.muteLocalAudioStream(!_micOn);
  }

  Future<void> _toggleCam() async {
    setState(() => _camOn = !_camOn);
    if (_provider == RtcProvider.livekit) {
      await _livekitRoom?.localParticipant?.setCameraEnabled(_camOn);
      return;
    }
    if (_engine == null) return;
    if (_camOn) {
      await _engine!.enableVideo();
      await _engine!.muteLocalVideoStream(false);
      await _ensurePreview();
    } else {
      await _engine!.muteLocalVideoStream(true);
      await _engine!.stopPreview();
    }
  }

  Future<void> _ensurePreview() async {
    if (_engine == null || !_camOn) return;
    try {
      await _engine!.startPreview();
    } catch (err) {
      _safeSetState(() {
        _errorMessage = 'Preview failed: $err';
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    if (_livekitRoom != null) {
      _livekitRoom?.removeListener(_handleLivekitUpdate);
      unawaited(_livekitRoom?.disconnect());
      unawaited(_livekitRoom?.dispose());
    }
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final usingLivekit = _provider == RtcProvider.livekit;
    final joined = usingLivekit
        ? _livekitState == livekit.ConnectionState.connected
        : _joined;
    final participants = (joined ? 1 : 0) +
        (usingLivekit
            ? _livekitRoom?.remoteParticipants.length ?? 0
            : _remoteUids.length);
    final sessionLabel = usingLivekit ? _livekitRoomLabel : _channelId;
    final sessionType = usingLivekit ? 'Room' : 'Channel';
    final providerLabel = usingLivekit ? 'LiveKit' : 'Agora';
    final gridSubtitle = usingLivekit
        ? 'Custom LiveKit layout · Live instructor view'
        : 'Custom Agora layout · Live instructor view';
    final status = _resolveStatus();
    final videoGrid = usingLivekit
        ? LiveKitVideoGrid(
            room: _livekitRoom,
            joined: joined,
            micOn: _micOn,
            camOn: _camOn,
          )
        : VideoGrid(
            engine: _engine,
            channelId: _channelId,
            joined: joined,
            remoteUids: _remoteUids,
            micOn: _micOn,
            camOn: _camOn,
          );

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundArt(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _Header(
                    sessionLabel: sessionLabel,
                    sessionType: sessionType,
                    providerLabel: providerLabel,
                    participants: participants,
                    status: status,
                    initializing: _initializing,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: _errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: isCompact
                        ? _buildCompactLayout(gridSubtitle, joined, videoGrid)
                        : _buildWideLayout(gridSubtitle, joined, videoGrid),
                  ),
                  const SizedBox(height: 16),
                  _ControlBar(
                    joined: joined,
                    micOn: _micOn,
                    camOn: _camOn,
                    initializing: _initializing,
                    onJoin: _joinChannel,
                    onLeave: _leaveChannel,
                    onToggleMic: _toggleMic,
                    onToggleCam: _toggleCam,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    String gridSubtitle,
    bool joined,
    Widget videoGrid,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: StaggeredReveal(
            delay: const Duration(milliseconds: 120),
            child: ClassroomPanel(
              title: 'Studio Grid',
              subtitle: gridSubtitle,
              trailing: _StatusPill(
                label: joined ? 'Broadcasting' : 'Offline',
                color: joined ? AppPalette.accent : AppPalette.accentWarm,
              ),
              child: videoGrid,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: StaggeredReveal(
            delay: const Duration(milliseconds: 220),
            child: ClassroomPanel(
              title: 'Whiteboard',
              subtitle: 'Freehand markers · Sync-ready surface',
              child: const Whiteboard(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: StaggeredReveal(
            delay: const Duration(milliseconds: 320),
            child: Column(
              children: [
                Expanded(
                  child: ClassroomPanel(
                    title: 'Resources',
                    subtitle: 'Lesson assets & quick links',
                    child: const ResourceList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ClassroomPanel(
                    title: 'Studio Chat',
                    subtitle: 'Low-latency classroom feed',
                    footer: const ChatComposer(),
                    child: const ChatMessages(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(
    String gridSubtitle,
    bool joined,
    Widget videoGrid,
  ) {
    return ListView(
      children: [
        StaggeredReveal(
          delay: const Duration(milliseconds: 120),
          child: SizedBox(
            height: 320,
            child: ClassroomPanel(
              title: 'Studio Grid',
              subtitle: gridSubtitle,
              trailing: _StatusPill(
                label: joined ? 'Broadcasting' : 'Offline',
                color: joined ? AppPalette.accent : AppPalette.accentWarm,
              ),
              child: videoGrid,
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          delay: const Duration(milliseconds: 220),
          child: SizedBox(
            height: 360,
            child: ClassroomPanel(
              title: 'Whiteboard',
              subtitle: 'Freehand markers · Sync-ready surface',
              child: const Whiteboard(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          delay: const Duration(milliseconds: 320),
          child: SizedBox(
            height: 280,
            child: ClassroomPanel(
              title: 'Resources',
              subtitle: 'Lesson assets & quick links',
              child: const ResourceList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          delay: const Duration(milliseconds: 420),
          child: SizedBox(
            height: 320,
            child: ClassroomPanel(
              title: 'Studio Chat',
              subtitle: 'Low-latency classroom feed',
              footer: const ChatComposer(),
              child: const ChatMessages(),
            ),
          ),
        ),
      ],
    );
  }

  _StatusInfo _resolveStatus() {
    if (_initializing) {
      return const _StatusInfo(label: 'Initializing', color: AppPalette.muted);
    }

    if (_provider == RtcProvider.livekit) {
      switch (_livekitState) {
        case livekit.ConnectionState.connected:
          return const _StatusInfo(label: 'Live', color: AppPalette.accent);
        case livekit.ConnectionState.connecting:
          return const _StatusInfo(
            label: 'Connecting',
            color: AppPalette.accent,
          );
        case livekit.ConnectionState.reconnecting:
          return const _StatusInfo(
            label: 'Reconnecting',
            color: AppPalette.accent,
          );
        case livekit.ConnectionState.disconnected:
        default:
          return const _StatusInfo(
            label: 'Offline',
            color: AppPalette.accentWarm,
          );
      }
    }

    switch (_connectionState) {
      case ConnectionStateType.connectionStateConnected:
        return const _StatusInfo(label: 'Live', color: AppPalette.accent);
      case ConnectionStateType.connectionStateConnecting:
        return const _StatusInfo(label: 'Connecting', color: AppPalette.accent);
      case ConnectionStateType.connectionStateReconnecting:
        return const _StatusInfo(
          label: 'Reconnecting',
          color: AppPalette.accent,
        );
      case ConnectionStateType.connectionStateFailed:
        return const _StatusInfo(label: 'Error', color: AppPalette.accentWarm);
      case ConnectionStateType.connectionStateDisconnected:
        return const _StatusInfo(
          label: 'Offline',
          color: AppPalette.accentWarm,
        );
      default:
        return const _StatusInfo(
          label: 'Offline',
          color: AppPalette.accentWarm,
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.sessionLabel,
    required this.sessionType,
    required this.providerLabel,
    required this.participants,
    required this.status,
    required this.initializing,
  });

  final String sessionLabel;
  final String sessionType;
  final String providerLabel;
  final int participants;
  final _StatusInfo status;
  final bool initializing;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 900;
    final titleStyle = Theme.of(
      context,
    ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Classroom Studio', style: titleStyle),
        const SizedBox(height: 4),
        Text('Algebra II · Quadratics Lab', style: subtitleStyle),
      ],
    );

    final meta = Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _StatusPill(label: status.label, color: status.color),
        _MetaChip(icon: Icons.hub_outlined, label: providerLabel),
        _MetaChip(
          icon: Icons.layers_outlined,
          label: '$sessionType $sessionLabel',
        ),
        _MetaChip(
          icon: Icons.people_alt_outlined,
          label: '$participants participants',
        ),
        _MetaChip(
          icon: Icons.timer_outlined,
          label: initializing ? 'Loading session' : '56 min scheduled',
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, const SizedBox(height: 12), meta],
      );
    }

    return Row(children: [header, const Spacer(), meta]);
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.joined,
    required this.micOn,
    required this.camOn,
    required this.initializing,
    required this.onJoin,
    required this.onLeave,
    required this.onToggleMic,
    required this.onToggleCam,
  });

  final bool joined;
  final bool micOn;
  final bool camOn;
  final bool initializing;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCam;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Wrap(
            spacing: 12,
            children: [
              _ActionButton(
                icon: micOn ? Icons.mic_none : Icons.mic_off,
                label: micOn ? 'Mic on' : 'Mic off',
                isActive: micOn,
                onTap: onToggleMic,
              ),
              _ActionButton(
                icon: camOn ? Icons.videocam_outlined : Icons.videocam_off,
                label: camOn ? 'Camera on' : 'Camera off',
                isActive: camOn,
                onTap: onToggleCam,
              ),
              _ActionButton(
                icon: Icons.screen_share_outlined,
                label: 'Share deck',
                isActive: false,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: initializing ? null : onLeave,
                icon: const Icon(Icons.logout),
                label: const Text('Leave'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.accentWarm,
                  side: BorderSide(
                    color: AppPalette.accentWarm.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: initializing ? null : onJoin,
                icon: Icon(joined ? Icons.check_circle : Icons.play_circle),
                label: Text(joined ? 'Live' : 'Go live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppPalette.accent.withValues(alpha: 0.12)
              : AppPalette.wash,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppPalette.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppPalette.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppPalette.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.accentWarm.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.accentWarm.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppPalette.accentWarm),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo({required this.label, required this.color});

  final String label;
  final Color color;
}
