import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';

class RecordingControllerBox extends ConsumerStatefulWidget {
  final QuillController? controller;

  const RecordingControllerBox({this.controller, super.key});

  @override
  _RecordingControllerBoxState createState() => _RecordingControllerBoxState();
}

class _RecordingControllerBoxState extends ConsumerState<RecordingControllerBox> {
  bool _isMenuVisible = false;
  String _selectedLanguage = '한국어';
  OverlayEntry? _menuOverlayEntry;
  final LayerLink _layerLink = LayerLink();

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
  }

  OverlayEntry _createMenuOverlayEntry(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 160.0,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(227, -270.0),
          child: Material(
            borderRadius: BorderRadius.circular(8.0),
            elevation: 2.0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.language, size: 16.0),
              SizedBox(width: 8.0),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedLanguage,
                  items: ['한국어', '영어'].map((language) => DropdownMenuItem(
                    value: language,
                    child: Text(language, style: TextStyle(fontSize: 14.0)),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                      _toggleMenu(context);
                    });
                  },
                  underline: SizedBox(),
                ),
              ),
            ],
          ),
        ),
        if (recordingState.recordings.isNotEmpty) ...[
          _buildMenuItem(
            context,
            icon: Icons.text_snippet,
            label: '텍스트로 변환',
            onTap: () async {
              _toggleMenu(context);
              if (widget.controller != null) {
                final recording = recordingState.recordings.last;
                await recordingViewModel.transcribeRecording(
                  recording.path,
                  _mapLanguageToCode(_selectedLanguage),
                  widget.controller!,
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.summarize,
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
          ),
          _buildMenuItem(
            context,
            icon: Icons.download,
            label: '다운로드',
            onTap: () {
              Future.microtask(() => recordingViewModel.downloadRecording(recordingState.recordings.last.path));
              _toggleMenu(context);
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.history,
            label: '녹음기록',
            onTap: () {
              _toggleMenu(context);
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.delete,
            label: '삭제',
            onTap: () {
              recordingViewModel.deleteRecording(recordingState.recordings.last.path);
              if (ref.read(recordingViewModelProvider).recordings.isEmpty) {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
              }
              _toggleMenu(context);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 16.0),
            SizedBox(width: 8.0),
            Text(label, style: TextStyle(fontSize: 14.0)),
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
                                  icon: Icon(
                                    isPlaying ? Icons.stop : Icons.play_arrow,
                                    size: 20.0,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  onPressed: () {
                                    recordingViewModel.playRecording(recording.path);
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
                  onPressed: () => _toggleMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}