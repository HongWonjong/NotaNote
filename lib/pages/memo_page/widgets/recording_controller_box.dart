import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:intl/intl.dart';

class RecordingControllerBox extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
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
                          final timestamp = DateFormat('HH:mm:ss').format(recording.createdAt);
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    recordingViewModel.isPlaying(recording.path)
                                        ? Icons.stop
                                        : Icons.play_arrow,
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
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('옵션'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (recordingState.recordings.isNotEmpty)
                                  ListTile(
                                    title: Text('다운로드'),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                    onTap: () {
                                      recordingViewModel.downloadRecording(recordingState.recordings.last.path);
                                      Navigator.pop(context);
                                    },
                                  ),
                                if (recordingState.recordings.isNotEmpty)
                                  ListTile(
                                    title: Text('삭제'),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                    onTap: () {
                                      recordingViewModel.deleteRecording(recordingState.recordings.last.path);
                                      Navigator.pop(context);
                                      if (ref.read(recordingViewModelProvider).recordings.isEmpty) {
                                        ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                                      }
                                    },
                                  ),
                                ListTile(
                                  title: Text('닫기'),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                  onTap: () {
                                    ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('취소'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}