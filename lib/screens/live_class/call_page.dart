import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dab_fitness/config/agora_config.dart';

class CallPage extends StatefulWidget {
  final String channelName;
  final ClientRoleType role;

  const CallPage({super.key, required this.channelName, required this.role});

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

  bool get _isBroadcaster =>
      widget.role == ClientRoleType.clientRoleBroadcaster;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }

  void _addLog(String message) {
    debugPrint('[Agora] $message');
    if (mounted) setState(() => _log.add(message));
  }

  Future<void> _start() async {
    if (agoraAppId.isEmpty) {
      setState(() => _error =
          'Agora App ID is missing. Add it in lib/utils/settings.dart.');
      return;
    }
    try {
      await _engine.initialize(const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onError: (ErrorCodeType err, String msg) =>
            _addLog('Error: $err $msg'),
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _addLog('Joined ${connection.channelId} as ${connection.localUid}');
          if (mounted) setState(() => _joined = true);
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
      await _engine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _videoArea()),
            if (kDebugMode) _debugPanel(),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, color: Colors.white70, size: 48)
            else
              const CircularProgressIndicator(color: Colors.white70),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // ---------- Controls ----------

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isBroadcaster)
            _roundButton(
              icon: _muted ? Icons.mic_off : Icons.mic,
              iconColor: _muted ? Colors.white : Colors.blueAccent,
              fill: _muted ? Colors.blueAccent : Colors.white,
              onPressed: _toggleMute,
            ),
          _roundButton(
            icon: Icons.call_end,
            iconColor: Colors.white,
            fill: Colors.redAccent,
            size: 35,
            padding: 15,
            onPressed: () => Navigator.pop(context),
          ),
          if (_isBroadcaster)
            _roundButton(
              icon: Icons.switch_camera,
              iconColor: Colors.blueAccent,
              fill: Colors.white,
              onPressed: () => _engine.switchCamera(),
            ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color iconColor,
    required Color fill,
    required VoidCallback onPressed,
    double size = 20,
    double padding = 12,
  }) {
    return RawMaterialButton(
      onPressed: onPressed,
      shape: const CircleBorder(),
      elevation: 2,
      fillColor: fill,
      padding: EdgeInsets.all(padding),
      child: Icon(icon, color: iconColor, size: size),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(text,
                      style:
                          const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}