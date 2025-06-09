import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:intl/intl.dart';

class RecordingControllerBox extends ConsumerStatefulWidget {
  @override
  _RecordingControllerBoxState createState() => _RecordingControllerBoxState();
}

class _RecordingControllerBoxState extends ConsumerState<RecordingControllerBox> {
  bool _isMenuVisible = false;
  String _selectedLanguage = '한국어';

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          borderRadius: BorderRadius.circular(8.0),
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
                border: Border.all(
                  color: Colors.grey[400]!,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                          onPressed: () {
                            setState(() {
                              _isMenuVisible = !_isMenuVisible;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isMenuVisible)
          Positioned(
            right: 0,
            bottom: 62,
            child: Material(
              borderRadius: BorderRadius.circular(8.0),
              elevation: 2.0,
              child: Container(
                width: 160,
                padding: EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 1.0,
                  ),
                ),
                child: Column(
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
                              items: ['한국어', '영어']
                                  .map((language) => DropdownMenuItem(
                                value: language,
                                child: Text(
                                  language,
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                  _isMenuVisible = false;
                                });
                              },
                              underline: SizedBox(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recordingState.recordings.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // TODO: Implement convert to text
                          setState(() {
                            _isMenuVisible = false;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.text_snippet, size: 16.0),
                              SizedBox(width: 8.0),
                              Text(
                                '텍스트로 변환',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (recordingState.recordings.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          recordingViewModel.downloadRecording(recordingState.recordings.last.path);
                          setState(() {
                            _isMenuVisible = false;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 16.0),
                              SizedBox(width: 8.0),
                              Text(
                                '다운로드',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (recordingState.recordings.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // TODO: Implement recording history
                          setState(() {
                            _isMenuVisible = false;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 16.0),
                              SizedBox(width: 8.0),
                              Text(
                                '녹음기록',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (recordingState.recordings.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          recordingViewModel.deleteRecording(recordingState.recordings.last.path);
                          if (ref.read(recordingViewModelProvider).recordings.isEmpty) {
                            ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                          }
                          setState(() {
                            _isMenuVisible = false;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16.0),
                              SizedBox(width: 8.0),
                              Text(
                                '삭제',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                        setState(() {
                          _isMenuVisible = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.close, size: 16.0),
                            SizedBox(width: 8.0),
                            Text(
                              '닫기',
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}