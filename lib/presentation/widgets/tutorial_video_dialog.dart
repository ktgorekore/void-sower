// Copyright 2026 Void Sower Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal dialog providing in-engine playback of the narrated 60s Flight Academy video.
///
/// Features video playback controls, time scrubbing, audio session ducking/pausing,
/// and graceful fallbacks for headless testing environments.
class TutorialVideoDialog extends StatefulWidget {
  const TutorialVideoDialog({
    super.key,
    this.videoAsset = 'assets/video/how_to_play.mp4',
  });

  /// Asset path of the narrated gameplay tutorial video.
  final String videoAsset;

  @override
  State<TutorialVideoDialog> createState() => _TutorialVideoDialogState();
}

class _TutorialVideoDialogState extends State<TutorialVideoDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      AudioService.instance.pauseBgm();
      final controller = VideoPlayerController.asset(widget.videoAsset);
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      controller.addListener(_onControllerUpdate);
      await controller.setLooping(false);
      await controller.play();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('[TutorialVideoDialog] Video initialization fallback: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    AudioService.instance.resumeBgm();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    HapticService.instance.sowTick();
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _restart() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    HapticService.instance.injectionClick();
    controller.seekTo(Duration.zero);
    controller.play();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady =
        _isInitialized && controller != null && controller.value.isInitialized;
    final isPlaying = isReady && controller.value.isPlaying;
    final position = isReady ? controller.value.position : Duration.zero;
    final duration = isReady
        ? controller.value.duration
        : const Duration(seconds: 60);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440.0, maxHeight: 680.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: VoidTheme.solarGold, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: VoidTheme.solarGold.withValues(alpha: 0.35),
              blurRadius: 24.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar with Title and Close 'X'
            Row(
              children: [
                const Icon(
                  Icons.smart_display,
                  color: VoidTheme.solarGold,
                  size: 22.0,
                ),
                const SizedBox(width: 8.0),
                const Expanded(
                  child: Text(
                    'FLIGHT ACADEMY • VIDEO BRIEFING',
                    style: TextStyle(
                      color: VoidTheme.solarGold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: VoidTheme.textSecondary),
                  tooltip: 'Close Video',
                  padding: const EdgeInsets.all(8.0),
                  constraints: const BoxConstraints(
                    minWidth: 48.0,
                    minHeight: 48.0,
                  ),
                  onPressed: () {
                    HapticService.instance.sowTick();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const Divider(color: VoidTheme.cardSurface, height: 12.0),

            // Video Player Viewport
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isReady)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showControls = !_showControls;
                            });
                          },
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio > 0
                                  ? controller.value.aspectRatio
                                  : 9 / 20,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        )
                      else if (_hasError)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.ondemand_video,
                                  color: VoidTheme.crimsonFlare,
                                  size: 48.0,
                                ),
                                const SizedBox(height: 12.0),
                                const Text(
                                  'TACTICAL VIDEO BRIEFING',
                                  style: TextStyle(
                                    color: VoidTheme.solarGold,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                const Text(
                                  'Video briefing has been unbundled to reduce package size.\nConsult the Flight Academy and Bao Codex for combat rules.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: VoidTheme.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(
                            color: VoidTheme.solarGold,
                            strokeWidth: 2.5,
                          ),
                        ),

                      // Overlay Central Play/Pause Button
                      if (isReady && (_showControls || !isPlaying))
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 56.0,
                            height: 56.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: VoidTheme.obsidianBlack.withValues(
                                alpha: 0.65,
                              ),
                              border: Border.all(
                                color: VoidTheme.solarGold,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: VoidTheme.solarGold.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 14.0,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: VoidTheme.solarGold,
                              size: 34.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // Timeline Scrubber & Timestamp
            if (isReady) ...[
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(
                      color: VoidTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12.0,
                        ),
                        activeTrackColor: VoidTheme.solarGold,
                        inactiveTrackColor: VoidTheme.cardSurface,
                        thumbColor: VoidTheme.solarGold,
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble().clamp(
                          0.0,
                          duration.inMilliseconds.toDouble(),
                        ),
                        max: duration.inMilliseconds > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (val) {
                          controller.seekTo(
                            Duration(milliseconds: val.toInt()),
                          );
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: VoidTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            // Bottom Controls Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: VoidTheme.solarGold,
                        size: 32.0,
                      ),
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: isReady ? _togglePlayPause : null,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.replay,
                        color: VoidTheme.plasmaCyan,
                        size: 24.0,
                      ),
                      tooltip: 'Replay from Start',
                      onPressed: isReady ? _restart : null,
                    ),
                  ],
                ),
                TactileButton(
                  label: 'BACK TO ACADEMY',
                  icon: Icons.school,
                  isPrimary: false,
                  accentColor: VoidTheme.plasmaCyan,
                  height: 38.0,
                  minWidth: 150.0,
                  onPressed: () {
                    HapticService.instance.sowTick();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
