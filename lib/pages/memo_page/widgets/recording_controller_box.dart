import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nota_note/pages/record_page/record_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecordingControllerBox extends ConsumerStatefulWidget {
  final QuillController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onTranscribeTapped; // 콜백 추가

  const RecordingControllerBox({
    this.controller,
    this.focusNode,
    this.onTranscribeTapped,
    super.key,
  });

  @override
  _RecordingControllerBoxState createState() => _RecordingControllerBoxState();
}

class _RecordingControllerBoxState extends ConsumerState<RecordingControllerBox> {
  bool _isMenuVisible = false;
  OverlayEntry? _menuOverlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _toggleMenu(BuildContext context) {
    if (_isMenuVisible) {
      _menuOverlayEntry?.remove();
      _menuOverlayEntry = null;
      _isMenuVisible = false;
    } else {
      _menuOverlayEntry = _createMenuOverlayEntry(context);
      Overlay.of(context).insert(_menuOverlayEntry!);
      _isMenuVisible = true;
    }
    setState(() {});
    if (widget.focusNode != null && widget.focusNode!.canRequestFocus) {
      widget.focusNode!.requestFocus();
    }
  }

  OverlayEntry _createMenuOverlayEntry(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final RenderBox? buttonBox = context.findRenderObject() as RenderBox?;
    final buttonPosition = buttonBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final buttonSize = buttonBox?.size ?? Size.zero;

    double menuWidth = 200.0;
    double menuHeight = 220.0; // 메뉴 높이 220.0 적용
    double left = buttonPosition.dx + buttonSize.width - menuWidth;
    double top = buttonPosition.dy - menuHeight - 10;

    if (left + menuWidth > screenWidth) {
      left = screenWidth - menuWidth - 8;
    }
    if (left < 8) {
      left = 8;
    }
    if (top < 8) {
      top = 8;
    }

    return OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: menuWidth,
        height: menuHeight,
        child: Material(
          borderRadius: BorderRadius.circular(12.0),
          elevation: 2.0,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey[400]!, width: 1.0),
            ),
            child: _buildMenuItems(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recordingState.recordings.isNotEmpty) ...[
          _buildMenuItem(
            context,
            svgPath: 'assets/icons/Edit.svg',
            label: '텍스트로 변환',
            onTap: () {
              _toggleMenu(context);
              if (widget.controller != null &&
                  recordingState.recordings.isNotEmpty) {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                if (widget.focusNode != null &&
                    widget.focusNode!.hasFocus) {
                  widget.focusNode!.unfocus();
                }
                widget.onTranscribeTapped?.call(); // 콜백 호출
              }
              setState(() {});
            },
          ),
          Container(
            width: 166,
            height: 1,
            decoration: BoxDecoration(color: Color(0xFFCCCCCC)),
          ),
          _buildMenuItem(
            context,
            svgPath: 'assets/icons/DownloadSimple.svg',
            label: '다운로드',
            onTap: () {
              if (recordingState.recordings.isNotEmpty) {
                Future.microtask(() => recordingViewModel
                    .downloadRecording(recordingState.recordings.first.path));
              }
              _toggleMenu(context);
              setState(() {});
            },
          ),
          _buildMenuItem(
            context,
            svgPath: 'assets/icons/WaveForm.svg',
            label: '녹음기록',
            onTap: () {
              _toggleMenu(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecordPage()),
              );
            },
          ),
          _buildMenuItem(
            context,
            svgPath: 'assets/icons/Delete.svg',
            label: '삭제',
            onTap: () {
              if (recordingState.recordings.isNotEmpty) {
                recordingViewModel
                    .deleteRecording(recordingState.recordings.first.path);
                if (ref.read(recordingViewModelProvider).recordings.isEmpty) {
                  ref.read(recordingBoxVisibilityProvider.notifier).state =
                  false;
                }
              }
              _toggleMenu(context);
              setState(() {});
            },
            textColor: Color(0xFFFF2F2F),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required String svgPath,
        required String label,
        required VoidCallback onTap,
        Color textColor = const Color(0xFF4C4C4C),
      }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onTap();
        if (widget.focusNode != null && widget.focusNode!.canRequestFocus) {
          widget.focusNode!.requestFocus();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              child: SvgPicture.asset(
                svgPath,
                width: 20,
                height: 20,
                color: textColor,
              ),
            ),
            SizedBox(width: 8.0),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _menuOverlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    print(
        'Rendering recordings: ${recordingState.recordings.map((r) => "${r.path}: ${r.createdAt.toIso8601String()}").toList()}');
    if (recordingState.recordings.isNotEmpty) {
      print(
          'Selected recording: ${recordingState.recordings.first.path}, CreatedAt: ${recordingState.recordings.first.createdAt.toIso8601String()}');
    }

    return Material(
      borderRadius: BorderRadius.circular(8.0),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.9,
            maxHeight: 60,
          ),
          child: Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[400]!, width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: recordingState.recordings.isNotEmpty
                      ? LayoutBuilder(
                    builder: (context, constraints) {
                      final recording = recordingState.recordings.first;
                      print(
                          'Displaying recording: ${recording.path}, Duration: ${recording.duration}, CreatedAt: ${recording.createdAt.toIso8601String()}');
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final state =
                            ref.watch(recordingViewModelProvider);
                            final isPlaying = recordingViewModel
                                .isPlaying(recording.path);
                            final currentPosition = state.currentPosition;
                            final displayDuration = isPlaying
                                ? currentPosition
                                : (state.isCompleted &&
                                state.currentlyPlayingPath ==
                                    recording.path)
                                ? recording.duration
                                : recording.duration;
                            print(
                                'isPlaying: $isPlaying, currentPosition: $currentPosition, displayDuration: $displayDuration');
                            return Row(
                              children: [
                                IconButton(
                                  icon: isPlaying
                                      ? SvgPicture.asset(
                                    'assets/icons/Pause.svg',
                                    width: 24,
                                    height: 24,
                                  )
                                      : SvgPicture.asset(
                                    'assets/icons/Play.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  onPressed: () {
                                    if (isPlaying) {
                                      recordingViewModel.pausePlayback();
                                    } else {
                                      recordingViewModel
                                          .playRecording(recording.path);
                                    }
                                    if (widget.focusNode != null &&
                                        widget
                                            .focusNode!.canRequestFocus) {
                                      widget.focusNode!.requestFocus();
                                    }
                                    setState(() {});
                                  },
                                ),
                                Text(
                                  '${displayDuration.inMinutes.toString().padLeft(2, '0')}:${(displayDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: isPlaying
                                        ? Color(0xFF61CFB2)
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  )
                      : Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '녹음된 파일이 없습니다.',
                          style: TextStyle(
                              fontSize: 12.0, color: Colors.grey),
                        ),
                        SizedBox(width: 8.0),
                        TextButton(
                          onPressed: () {
                            recordingViewModel.startRecording();
                            setState(() {});
                          },
                          child: Text('녹음 시작'),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, size: 20.0),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () {
                    _toggleMenu(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}