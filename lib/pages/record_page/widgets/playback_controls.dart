import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlaybackControls extends ConsumerStatefulWidget {
  final RecordingInfo recording;
  final Duration position;
  final Duration duration;

  PlaybackControls({required this.recording, required this.position, required this.duration});

  @override
  _PlaybackControlsState createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends ConsumerState<PlaybackControls> {
  @override
  void initState() {
    super.initState();
    final viewModel = ref.read(recordingViewModelProvider.notifier);
    final state = ref.read(recordingViewModelProvider);
    if (state.currentlyPlayingPath == widget.recording.path && !state.isPaused && !state.isCompleted) {
      viewModel.playRecording(widget.recording.path, resumeIfPaused: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(recordingViewModelProvider.notifier);
    final state = ref.watch(recordingViewModelProvider);
    final remaining = widget.duration - widget.position;
    final isPlaying = state.isPlaying && state.currentlyPlayingPath == widget.recording.path;
    final showPlayIcon = !isPlaying || state.isCompleted;

    print('PlaybackControls build: path=${widget.recording.path}, isPlaying=$isPlaying, '
        'showPlayIcon=$showPlayIcon, position=${widget.position}, duration=${widget.duration}, '
        'remaining=$remaining, isCompleted=${state.isCompleted}');

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.position.inMinutes.toString().padLeft(2, '0')}:${(widget.position.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Color(0xFF4C4C4C),
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 4,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: Color(0xFF4C4C4C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: widget.duration.inSeconds > 0
                              ? MediaQuery.of(context).size.width * (widget.position.inSeconds / widget.duration.inSeconds)
                              : 0,
                          height: 4,
                          decoration: ShapeDecoration(
                            color: Color(0xFF60CFB1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(2),
                                bottomLeft: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '-${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Color(0xFF4C4C4C),
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                icon: SvgPicture.asset(
                  'assets/icons/Rewind.svg',
                  color: Color(0xFF4C4C4C),
                  width: 18,
                  height: 18,
                ),
                onPressed: () {
                  final newPosition = widget.position - const Duration(seconds: 10);
                  viewModel.seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
                },
              ),
              const SizedBox(width: 48),
              IconButton(
                padding: EdgeInsets.zero,
                icon: SvgPicture.asset(
                  showPlayIcon ? 'assets/icons/RecordPlay.svg' : 'assets/icons/Pause.svg',
                  color: Color(0xFF4C4C4C),
                  width: 18,
                  height: 18,
                ),
                onPressed: () {
                  print('Play/Pause button pressed: path=${widget.recording.path}, isPlaying=$isPlaying, '
                      'showPlayIcon=$showPlayIcon, isCompleted=${state.isCompleted}');
                  if (isPlaying) {
                    viewModel.pausePlayback();
                  } else {
                    viewModel.playRecording(widget.recording.path, resumeIfPaused: true);
                  }
                },
              ),
              const SizedBox(width: 48),
              IconButton(
                padding: EdgeInsets.zero,
                icon: SvgPicture.asset(
                  'assets/icons/FastForward.svg',
                  color: Color(0xFF4C4C4C),
                  width: 18,
                  height: 18,
                ),
                onPressed: () {
                  final newPosition = widget.position + const Duration(seconds: 10);
                  viewModel.seekTo(newPosition < widget.duration ? newPosition : widget.duration);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}