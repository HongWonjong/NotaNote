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

    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 300,
        height: 300,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '녹음된 파일',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20.0),
                  onPressed: () {
                    ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                  },
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: recordingState.recordings.isNotEmpty
                  ? ListView.builder(
                itemCount: recordingState.recordings.length,
                itemBuilder: (context, index) {
                  final recording = recordingState.recordings[index];
                  final timestamp =
                  DateFormat('HH:mm:ss').format(recording.createdAt);
                  return ListTile(
                    title:
                    Text('$timestamp (${recording.duration.inSeconds}초)'),
                    subtitle: recordingState.transcriptions
                        .containsKey(recording.path)
                        ? Text(
                      '전사: ${recordingState.transcriptions[recording.path]}',
                      style: TextStyle(
                          fontSize: 12.0, color: Colors.grey[600]),
                    )
                        : null,
                    trailing: IconButton(
                      icon: Icon(Icons.close, size: 20.0),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('녹음 삭제'),
                            content: Text('정말 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  recordingViewModel
                                      .deleteRecording(recording.path);
                                  Navigator.pop(context);
                                },
                                child: Text('삭제'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            recordingViewModel.isPlaying(recording.path)
                                ? Icons.stop
                                : Icons.play_arrow,
                          ),
                          onPressed: () {
                            recordingViewModel.playRecording(recording.path);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.download),
                          onPressed: () {
                            recordingViewModel
                                .downloadRecording(recording.path);
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
                  : Center(
                child: Text(
                  '녹음된 파일이 없습니다.',
                  style: TextStyle(fontSize: 14.0, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
