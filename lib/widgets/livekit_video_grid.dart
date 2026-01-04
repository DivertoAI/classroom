import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../config/app_theme.dart';

class LiveKitVideoGrid extends StatelessWidget {
  const LiveKitVideoGrid({
    super.key,
    required this.room,
    required this.joined,
    required this.micOn,
    required this.camOn,
  });

  final Room? room;
  final bool joined;
  final bool micOn;
  final bool camOn;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    tiles.add(
      _VideoTile(
        label: 'You (Host)',
        subtitle: joined ? 'Live' : 'Preview',
        muted: !micOn,
        cameraOff: !camOn,
        child: _buildLocalView(context),
      ),
    );

    final participants = room?.remoteParticipants.values.toList() ?? [];

    if (participants.isEmpty) {
      tiles.add(
        const _VideoTile(
          label: 'Waiting for students',
          subtitle: 'Share the link to invite',
          isPlaceholder: true,
          child: _PlaceholderContent(icon: Icons.people_alt_outlined),
        ),
      );
    } else {
      for (var i = 0; i < participants.length; i++) {
        final participant = participants[i];
        tiles.add(
          _VideoTile(
            label: participant.name.isNotEmpty
                ? participant.name
                : 'Student ${i + 1}',
            subtitle: participant.isSpeaking ? 'Speaking' : 'Connected',
            child: _buildRemoteView(participant),
          ),
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = tiles.length;
        final width = constraints.maxWidth;
        final crossAxisCount = width < 520
            ? 1
            : count <= 2
                ? 2
                : 3;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 16 / 9,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) => tiles[index],
        );
      },
    );
  }

  Widget _buildLocalView(BuildContext context) {
    if (room == null || !camOn) {
      return const _PlaceholderContent(icon: Icons.videocam_off_outlined);
    }
    final track = _firstCameraTrack(room!.localParticipant?.videoTrackPublications ?? const []);
    if (track == null) {
      return const _PlaceholderContent(icon: Icons.videocam_off_outlined);
    }
    return VideoTrackRenderer(
      track,
      fit: VideoViewFit.cover,
    );
  }

  Widget _buildRemoteView(RemoteParticipant participant) {
    final track = _firstCameraTrack(participant.videoTrackPublications);
    if (track == null) {
      return const _PlaceholderContent(icon: Icons.videocam_off_outlined);
    }
    return VideoTrackRenderer(
      track,
      fit: VideoViewFit.cover,
    );
  }

  VideoTrack? _firstCameraTrack(Iterable<TrackPublication> publications) {
    for (final publication in publications) {
      if (publication.source == TrackSource.camera && publication.track is VideoTrack) {
        return publication.track as VideoTrack;
      }
    }
    return null;
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.label,
    required this.subtitle,
    required this.child,
    this.muted = false,
    this.cameraOff = false,
    this.isPlaceholder = false,
  });

  final String label;
  final String subtitle;
  final Widget child;
  final bool muted;
  final bool cameraOff;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppPalette.wash,
              gradient: isPlaceholder
                  ? const LinearGradient(
                      colors: [
                        AppPalette.wash,
                        AppPalette.surface,
                      ],
                    )
                  : null,
            ),
            child: child,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                ),
              ],
            ),
          ),
          if (muted || cameraOff)
            Positioned(
              right: 12,
              top: 12,
              child: Row(
                children: [
                  if (muted)
                    const _StatusIcon(
                      icon: Icons.mic_off_outlined,
                    ),
                  if (cameraOff)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: _StatusIcon(
                        icon: Icons.videocam_off_outlined,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        icon,
        color: AppPalette.muted,
        size: 48,
      ),
    );
  }
}
