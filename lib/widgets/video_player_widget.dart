import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:dab_fitness/config/theme.dart';

/// Plays a bundled workout video, looping. Tap to play / pause.
class VideoPlayerApp extends StatefulWidget {
  final String video;

  const VideoPlayerApp(this.video, {super.key});

  @override
  State<VideoPlayerApp> createState() => _VideoPlayerAppState();
}

class _VideoPlayerAppState extends State<VideoPlayerApp> {
  late final VideoPlayerController _controller =
      VideoPlayerController.asset(widget.video);
  late final Future<void> _initialized = _controller.initialize();

  @override
  void initState() {
    super.initState();
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      // Video stays on black in both themes, like the call screen.
      color: colors.callBackground,
      child: SizedBox(
        height: 222,
        child: FutureBuilder(
          future: _initialized,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                  child: CircularProgressIndicator(color: colors.onCall));
            }
            return Semantics(
              button: true,
              label: _controller.value.isPlaying ? 'Pause video' : 'Play video',
              child: GestureDetector(
                onTap: _toggle,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: 3 / 2,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    if (!_controller.value.isPlaying)
                      Center(
                        child: IconButton.filled(
                          tooltip: 'Play video',
                          iconSize: 40,
                          onPressed: _toggle,
                          icon: const Icon(Icons.play_arrow_rounded),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
