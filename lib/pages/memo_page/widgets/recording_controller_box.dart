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
  OverlayEntry? _menuOverlayEntry;
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
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 200.0,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(190, -270.0),
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
        Container(
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
                child: GestureDetector(
                  key: _languageButtonKey,
                  onTap: () {
                    _toggleMenu(context);
                    _showLanguageMenu(context);
                  },
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
                        Icon(Icons.arrow_drop_down, size: 24, color: Color(0xFF191919)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
/*          _buildMenuItem( // 텍스트로 변환 클릭 시 요약을 선택할 수 있도록 UI 추후 개선
            context,
            svgPath: 'assets/icons/Edit.svg',
            label: 'AI 요약',
            onTap: () async {
              _toggleMenu(context);
              if (widget.controller != null) {
                final recording = recordingState.recordings.last;
                await recordingViewModel.summarizeRecording(
                  recording.path,
                  widget.controller!,
                );
              }
            },
          ),*/
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

  void _showLanguageMenu(BuildContext context) {
    final languages = [
      {'display': '한국어', 'code': 'ko'},
      {'display': '영어', 'code': 'en'},
    ];
    final RenderBox? buttonBox = _languageButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final buttonPosition = buttonBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final buttonSize = buttonBox?.size ?? Size.zero;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double topPosition = buttonPosition.dy - 120;
    if (topPosition < 0) {
      topPosition = buttonPosition.dy + buttonSize.height + 8;
    }

    double leftPosition = buttonPosition.dx;
    if (leftPosition + 200 > screenWidth) {
      leftPosition = screenWidth - 200 - 8;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, _, __) {
        return Stack(
          children: [
            Positioned(
              left: leftPosition,
              top: topPosition,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: languages.map((language) {
                      return GestureDetector(
                        onTap: () {
                          ref.read(languageProvider.notifier).state = language['code']!;
                          if (widget.focusNode != null && widget.focusNode!.canRequestFocus) {
                            widget.focusNode!.requestFocus();
                          }
                          Navigator.pop(context);
                          _toggleMenu(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Text(
                            language['display']!,
                            style: TextStyle(
                              color: Color(0xFF191919),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final state = ref.watch(recordingViewModelProvider);
                            final isPlaying = state.currentlyPlayingPath == recording.path;
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
                                    recordingViewModel.playRecording(recording.path);
                                    if (widget.focusNode != null && widget.focusNode!.canRequestFocus) {
                                      widget.focusNode!.requestFocus();
                                    }
                                  },
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  '${recording.duration.inMinutes.toString().padLeft(2, '0')}:${(recording.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 14.0),
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