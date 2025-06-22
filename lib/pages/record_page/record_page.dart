import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/bottom_sheet_menu.dart';
import 'widgets/playback_controls.dart';

class RecordPage extends ConsumerStatefulWidget {
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> with SingleTickerProviderStateMixin {
  int? selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(begin: 0, end: 90).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _togglePlaybackControls(int index, RecordingInfo recording) async {
    final viewModel = ref.read(recordingViewModelProvider.notifier);
    final currentState = ref.read(recordingViewModelProvider);

    if (selectedIndex == index) {
      // 동일 항목 탭: 닫기
      setState(() {
        selectedIndex = null;
      });
      await _animationController.reverse();
      if (currentState.isPlaying && currentState.currentlyPlayingPath == recording.path) {
        viewModel.stopPlayback();
      }
    } else {
      // 다른 항목 탭: 기존 닫고 새로 열기
      if (selectedIndex != null) {
        setState(() {
          selectedIndex = null;
        });
        await _animationController.reverse();
      }
      setState(() {
        selectedIndex = index;
      });
      await _animationController.forward();
      if (currentState.currentlyPlayingPath != recording.path || !currentState.isPlaying) {
        viewModel.playRecording(recording.path);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('녹음 기록'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/DotCircle.svg',
              color: Colors.black,
              width: 24,
              height: 24,
            ),
            onPressed: () {
              print('설정 버튼 클릭');
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '총 ${state.recordings.length}개',
                style: TextStyle(
                  color: Color(0xFF191919),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.recordings.length,
                itemBuilder: (context, index) {
                  final recording = state.recordings[index];
                  final duration = recording.duration;
                  final timeString = duration.inMinutes < 60
                      ? '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                      : '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

                  return GestureDetector(
                    onTap: () => _togglePlaybackControls(index, recording),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
                          bottom: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recording.path.split('/').last.replaceAll('.m4a', ''),
                                    style: TextStyle(
                                      color: Color(0xFF191919),
                                      fontSize: 16,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    timeString,
                                    style: TextStyle(
                                      color: Color(0xFFB3B3B3),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                  Text(
                                    '${recording.createdAt.year}. ${recording.createdAt.month}. ${recording.createdAt.day}.',
                                    style: TextStyle(
                                      color: Color(0xFFB3B3B3),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icons/DotsThree.svg',
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                      ),
                                    ),
                                    builder: (context) => BottomSheetMenu(recording: recording),
                                  );
                                },
                              ),
                            ],
                          ),
                          AnimatedBuilder(
                            animation: _heightAnimation,
                            builder: (context, child) {
                              return Container(
                                height: selectedIndex == index ? _heightAnimation.value : 0,
                                child: OverflowBox(
                                  minHeight: 0,
                                  maxHeight: 90,
                                  child: selectedIndex == index
                                      ? PlaybackControls(
                                    recording: recording,
                                    position: state.currentPosition,
                                    duration: recording.duration,
                                  )
                                      : SizedBox.shrink(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}