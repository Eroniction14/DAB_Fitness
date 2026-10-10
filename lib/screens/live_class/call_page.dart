import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/agora_config.dart';
import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/widgets/info_chip.dart';

/// Opens [liveClass]: the trainer as host (broadcaster, needs camera and
/// microphone), everyone else as audience.
Future<void> openLiveClass(BuildContext context, LiveClass liveClass,
    {required bool asHost}) async {
  if (liveClass.channelName.isEmpty) return;
  if (asHost) {
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (!context.mounted) return;
    if (statuses.values.any((s) => !s.isGranted)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Camera and microphone access are needed to host.'),
      ));
      return;
    }
  }
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CallPage(
        liveClass: liveClass,
        role: asHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      ),
    ),
  );
}

class CallPage extends StatefulWidget {
  final LiveClass liveClass;
  final ClientRoleType role;

  const CallPage({super.key, required this.liveClass, required this.role});

  String get channelName => liveClass.channelName;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final RtcEngine _engine = createAgoraRtcEngine();
  final _remoteUids = <int>[];
  final _log = <String>[];
  bool _engineReady = false;
  bool _joined = false;
  bool _muted = false;
  String? _error;

  late final BookingModel _booking;

  /// The class, updated live, for the "N watching" count.
  late final Stream<LiveClass?> _classUpdates;

  bool get _isBroadcaster =>
      widget.role == ClientRoleType.clientRoleBroadcaster;

  @override
  void initState() {
    super.initState();
    // Read here, not lazily: dispose() needs it and can't use context.read.
    _booking = context.read<BookingModel>();
    _classUpdates = _booking.watchLiveClass(widget.liveClass);
    _start();
  }

  @override
  void dispose() {
    if (!_isBroadcaster) {
      // Safe even if the join never completed.
      unawaited(_booking
          .leaveLiveClass(widget.liveClass)
          .catchError((Object e) => debugPrint('Leaving class failed: $e')));
    }
    _leave();
    super.dispose();
  }

  /// Audience only: count me as watching (removed on leave or disconnect).
  void _markAttending() {
    if (_isBroadcaster) return;
    _booking
        .joinLiveClass(widget.liveClass)
        .catchError((Object e) => _addLog('Could not update attendance: $e'));
  }

  void _addLog(String message) {
    debugPrint('[Agora] $message');
    if (mounted) setState(() => _log.add(message));
  }

  Future<void> _start() async {
    if (agoraAppId.isEmpty) {
      setState(() => _error =
          'Agora App ID is missing. Add it to config/env.json and run with '
              '--dart-define-from-file=config/env.json.');
      return;
    }
    try {
      await _engine.initialize(const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onError: (ErrorCodeType err, String msg) => _addLog('Error: $err $msg'),
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _addLog('Joined ${connection.channelId} as ${connection.localUid}');
          if (mounted) setState(() => _joined = true);
          _markAttending();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _addLog('User joined: $remoteUid');
          if (mounted && !_remoteUids.contains(remoteUid)) {
            setState(() => _remoteUids.add(remoteUid));
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          _addLog('User left: $remoteUid ($reason)');
          if (mounted) setState(() => _remoteUids.remove(remoteUid));
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _addLog('Left channel');
          if (mounted) {
            setState(() {
              _joined = false;
              _remoteUids.clear();
            });
          }
        },
      ));

      await _engine.setClientRole(role: widget.role);
      await _engine.enableVideo();
      await _engine
          .setVideoEncoderConfiguration(const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 1280, height: 720),
        frameRate: 15,
      ));
      if (_isBroadcaster) await _engine.startPreview();

      if (mounted) setState(() => _engineReady = true);

      await _engine.joinChannel(
        token: '', // empty in Agora "testing mode" (App ID only)
        channelId: widget.channelName,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: widget.role,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
    } catch (e) {
      debugPrint('Agora start failed: $e');
      if (mounted) setState(() => _error = 'Could not start the call.\n$e');
    }
  }

  Future<void> _leave() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint('Agora release failed: $e');
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine.muteLocalAudioStream(_muted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.callBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _videoArea()),
            if (kDebugMode) _debugPanel(),
            Align(alignment: Alignment.topRight, child: _watchingBadge()),
            Align(alignment: Alignment.bottomCenter, child: _toolbar()),
          ],
        ),
      ),
    );
  }

  // ---------- Video ----------

  Widget _videoArea() {
    if (_error != null) {
      return _message(_error!, icon: Icons.error_outline);
    }
    if (!_engineReady) return _message('Connecting…');

    final views = <Widget>[
      if (_isBroadcaster)
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      for (final uid in _remoteUids)
        AgoraVideoView(
          key: ValueKey(uid),
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        ),
    ];

    if (views.isEmpty) {
      return _message(
        _joined ? 'Waiting for the trainer to start…' : 'Connecting…',
        icon: _joined ? Icons.hourglass_empty : null,
      );
    }
    if (views.length == 1) return views.first;
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 3 / 4,
      children: views,
    );
  }

  Widget _message(String text, {IconData? icon}) {
    final onCall = context.appColors.onCall;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, color: onCall, size: 48)
            else
              CircularProgressIndicator(color: onCall),
            const SizedBox(height: AppSpacing.lg),
            Text(text,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge?.copyWith(color: onCall)),
          ],
        ),
      ),
    );
  }

  Widget _watchingBadge() {
    return StreamBuilder<LiveClass?>(
      stream: _classUpdates,
      builder: (context, snapshot) {
        final count = snapshot.data?.participants;
        if (count == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InfoChip(
              icon: Icons.visibility_outlined,
              label: '$count watching',
              onPhoto: true),
        );
      },
    );
  }

  // ---------- Controls ----------

  Widget _toolbar() {
    final scheme = context.colors;
    final colors = context.appColors;
    // Secondary controls: light circles; hang up: large error-red circle.
    final secondary = IconButton.styleFrom(
      backgroundColor: colors.onCall,
      foregroundColor: colors.callBackground,
      minimumSize: const Size.square(56),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isBroadcaster) ...[
            IconButton.filled(
              tooltip: _muted ? 'Unmute' : 'Mute',
              style: _muted
                  ? IconButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      minimumSize: const Size.square(56))
                  : secondary,
              icon: Icon(_muted ? Icons.mic_off : Icons.mic),
              onPressed: _toggleMute,
            ),
            const SizedBox(width: AppSpacing.xl),
          ],
          IconButton.filled(
            tooltip: 'Leave call',
            style: IconButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size.square(72),
            ),
            iconSize: 32,
            icon: const Icon(Icons.call_end),
            onPressed: () => Navigator.pop(context),
          ),
          if (_isBroadcaster) ...[
            const SizedBox(width: AppSpacing.xl),
            IconButton.filled(
              tooltip: 'Switch camera',
              style: secondary,
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: () => _engine.switchCamera(),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Debug log (debug builds only) ----------

  Widget _debugPanel() {
    return Align(
      alignment: Alignment.topLeft,
      child: FractionallySizedBox(
        heightFactor: 0.35,
        widthFactor: 0.8,
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: _log.length,
          itemBuilder: (context, index) {
            final text = _log[_log.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs / 2, horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.tertiaryContainer,
                    borderRadius: AppRadius.inputAll,
                  ),
                  child: Text(text,
                      style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onTertiaryContainer)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
