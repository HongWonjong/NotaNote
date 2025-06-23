import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'widgets/playback_controls.dart';
import 'widgets/bottom_sheet_menu.dart';
import 'widgets/setting_menu.dart';

class RecordPage extends ConsumerStatefulWidget {
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  int? selectedIndex;
  bool _showSettings = false;
  GlobalKey _settingsIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    print('RecordPage initState: Starting sync');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('RecordPage: Triggering syncRecordingsWithLoading');
      ref.read(recordingViewModelProvider.notifier).syncRecordingsWithLoading();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('RecordPage: Building UI');
    final state = ref.watch(recordingViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('녹음 기록'),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Arrow.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            key: _settingsIconKey,
            icon: SvgPicture.asset(
              'assets/icons/DotCircle.svg',
              color: Colors.black,
              width: 24,
              height: 24,
            ),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
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
                      return _RecordingItem(
                        recording: recording,
                        index: index,
                        isSelected: selectedIndex == index,
                        onTap: () => _togglePlaybackControls(index, recording),
                        onMenuTap: () {
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showSettings)
            SettingsMenu(
              onClose: () {
                setState(() {
                  _showSettings = false;
                });
              },
              iconKey: _settingsIconKey,
            ),
          if (state.isSyncing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      state.syncMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _togglePlaybackControls(int index, RecordingInfo recording) async {
    final viewModel = ref.read(recordingViewModelProvider.notifier);
    final currentState = ref.read(recordingViewModelProvider);

    if (selectedIndex == index) {
      setState(() {
        selectedIndex = null;
      });
      if (currentState.isPlaying && currentState.currentlyPlayingPath == recording.path) {
        viewModel.stopPlayback();
      }
    } else {
      setState(() {
        selectedIndex = index;
      });
      if (currentState.currentlyPlayingPath != recording.path || !currentState.isPlaying) {
        viewModel.playRecording(recording.path);
      }
    }
  }
}

class _RecordingItem extends StatefulWidget {
  final RecordingInfo recording;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _RecordingItem({
    required this.recording,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  __RecordingItemState createState() => __RecordingItemState();
}

class __RecordingItemState extends State<_RecordingItem> with SingleTickerProviderStateMixin {
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
    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(_RecordingItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
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
    final duration = widget.recording.duration;
    final timeString = duration.inMinutes < 60
        ? '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(recordingViewModelProvider);
        return GestureDetector(
          onTap: widget.onTap,
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
                          widget.recording.path.split('/').last.replaceAll('.m4a', ''),
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
                          '${widget.recording.createdAt.year}. ${widget.recording.createdAt.month}. ${widget.recording.createdAt.day}.',
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
                      onPressed: widget.onMenuTap,
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: _heightAnimation,
                  builder: (context, child) {
                    return Container(
                      height: _heightAnimation.value,
                      child: OverflowBox(
                        minHeight: 0,
                        maxHeight: 90,
                        child: widget.isSelected
                            ? PlaybackControls(
                          recording: widget.recording,
                          position: state.currentPosition,
                          duration: widget.recording.duration,
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
    );
  }
}