import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nota_note/pages/record_page/record_page.dart';
import 'package:nota_note/providers/language_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecordingControllerBox extends ConsumerStatefulWidget {
  final QuillController? controller;
  final FocusNode? focusNode;

  const RecordingControllerBox({this.controller, this.focusNode, super.key});

  @override
  _RecordingControllerBoxState createState() => _RecordingControllerBoxState();
}

class _RecordingControllerBoxState extends ConsumerState<RecordingControllerBox> {
  bool _isMenuVisible = false;
  bool _isLanguageMenuVisible = false;
  OverlayEntry? _menuOverlayEntry;
  OverlayEntry? _languageMenuOverlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _languageButtonKey = GlobalKey();

  String _mapLanguageToCode(String language) {
    switch (language) {
      case '한국어':
        return 'ko';
      case '영어':
        return 'en';
      default:
        return 'ko';
    }
  }

  String _mapCodeToLanguage(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return '영어';
      default:
        return '한국어';
    }
  }

  void _toggleMenu(BuildContext context) {
    if (_isMenuVisible) {
      _languageMenuOverlayEntry?.remove();
      _languageMenuOverlayEntry = null;
      _isLanguageMenuVisible = false;
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

  void _toggleLanguageMenu(BuildContext context) {
    if (_isLanguageMenuVisible) {
      _languageMenuOverlayEntry?.remove();
      _languageMenuOverlayEntry = null;
      _isLanguageMenuVisible = false;
    } else {
      _languageMenuOverlayEntry = _createLanguageMenuOverlayEntry(context);
      Overlay.of(context).insert(_languageMenuOverlayEntry!);
      _isLanguageMenuVisible = true;
    }
    setState(() {});
  }

  OverlayEntry _createMenuOverlayEntry(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final RenderBox? buttonBox = context.findRenderObject() as RenderBox?;
    final buttonPosition = buttonBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final buttonSize = buttonBox?.size ?? Size.zero;

    double menuWidth = 200.0;
    double menuHeight = 270.0;
    double left = buttonPosition.dx + buttonSize.width - menuWidth + 20;
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

  OverlayEntry _createLanguageMenuOverlayEntry(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final RenderBox? buttonBox = _languageButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final buttonPosition = buttonBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final buttonSize = buttonBox?.size ?? Size.zero;

    double menuWidth = buttonSize.width; // 버튼 너비에 맞춤
    double maxMenuHeight = 120.0; // 높이 증가
    double left = buttonPosition.dx;
    double top = buttonPosition.dy + buttonSize.height + 4;

    // 화면 하단 오버플로우 방지: 하단 공간 부족 시 위로 표시
    if (top + maxMenuHeight > screenHeight - 8) {
      top = buttonPosition.dy - maxMenuHeight - 4;
      if (top < 8) {
        top = 8; // 상단 경계 유지
      }
    }

    if (left + menuWidth > screenWidth) {
      left = screenWidth - menuWidth - 8;
    }
    if (left < 8) {
      left = 8;
    }

    return OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: menuWidth,
        child: Material(
          borderRadius: BorderRadius.circular(8.0),
          elevation: 2.0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxMenuHeight,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[400]!, width: 1.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageItem(context, '한국어', 'ko'),
                  _buildLanguageItem(context, '영어', 'en'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, String display, String code) {
    return GestureDetector(
      onTap: () {
        ref.read(languageProvider.notifier).state = code;
        _toggleLanguageMenu(context);
        if (widget.focusNode != null && widget.focusNode!.canRequestFocus) {
          widget.focusNode!.requestFocus();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Text(
          display,
          style: TextStyle(
            color: Color(0xFF191919),
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);
    final selectedLanguageCode = ref.watch(languageProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: _languageButtonKey,
          onTap: () {
            _toggleLanguageMenu(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/Globe.svg',
                  width: 20,
                  height: 20,
                ),
                SizedBox(width: 8.0),
                Text(
                  '언어',
                  style: TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    height: 0.11,
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Container(
                    height: 32,
                    padding: EdgeInsets.only(top: 4, left: 12, right: 8, bottom: 4),
                    decoration: ShapeDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _mapCodeToLanguage(selectedLanguageCode),
                          style: TextStyle(
                            color: Color(0xFF191919),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            height: 0.11,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/DropDownArrow.svg',
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (recordingState.recordings.isNotEmpty) ...[
          _buildMenuItem(
            context,
            svgPath: 'assets/icons/Edit.svg',
            label: '텍스트로 변환',
            onTap: () async {
              _toggleMenu(context);
              if (widget.controller != null) {
                final recording = recordingState.recordings.last;
                await recordingViewModel.transcribeRecording(
                  recording.path,
                  selectedLanguageCode,
                  widget.controller!,
                );
              }
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
              Future.microtask(() => recordingViewModel.downloadRecording(recordingState.recordings.last.path));
              _toggleMenu(context);
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
              recordingViewModel.deleteRecording(recordingState.recordings.last.path);
              if (ref.read(recordingViewModelProvider).recordings.isEmpty) {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
              }
              _toggleMenu(context);
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
                height: 0.09,
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
    _languageMenuOverlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

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
                      final recording = recordingState.recordings.last;
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final state = ref.watch(recordingViewModelProvider);
                            final isPlaying = recordingViewModel.isPlaying(recording.path);
                            final currentPosition = state.currentPosition;
                            final displayDuration = isPlaying
                                ? currentPosition
                                : (state.isCompleted && state.currentlyPlayingPath == recording.path)
                                ? Duration.zero
                                : recording.duration;
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
                                      recordingViewModel.playRecording(recording.path);
                                    }
                                    if (widget.focusNode != null && widget.focusNode!.canRequestFocus) {
                                      widget.focusNode!.requestFocus();
                                    }
                                  },
                                ),
                                Text(
                                  '${displayDuration.inMinutes.toString().padLeft(2, '0')}:${(displayDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: isPlaying ? Color(0xFF61CFB2) : Colors.black,
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
                    child: Text(
                      '녹음된 파일이 없습니다.',
                      style: TextStyle(fontSize: 12.0, color: Colors.grey),
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