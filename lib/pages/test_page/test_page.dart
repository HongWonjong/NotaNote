import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/pages/test_page/widgets/transcription_widget.dart';
import 'package:nota_note/providers/language_provider.dart';
import 'dart:io';

class TestPage extends ConsumerWidget {
  const TestPage({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)}MB';
    } else {
      return '${(bytes / kb).toStringAsFixed(2)}KB';
    }
  }

  String _getFileFormat(String path) {
    if (path.endsWith('.m4a')) return 'M4A';
    if (path.endsWith('.mp3')) return 'MP3';
    if (path.endsWith('.aac')) return 'AAC';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final selectedLanguage = ref.watch(languageProvider);
    final isRecording = recordingState.isRecording;

    return Scaffold(
      appBar: AppBar(
        title: const Text('테스트 페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '전사 언어: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: 'ko', child: Text('한글')),
                    DropdownMenuItem(value: 'en', child: Text('영어')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(languageProvider.notifier).state = value;
                    }
                  },
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  underline: Container(height: 2, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (isRecording) {
                  ref.read(recordingViewModelProvider.notifier).stopRecording();
                } else {
                  ref.read(recordingViewModelProvider.notifier).startRecording();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: isRecording ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Icon(
                isRecording ? Icons.stop : Icons.mic,
                size: 40,
              ),
            ),
            const SizedBox(height: 10),
            if (recordingState.isRecording)
              Text(
                '녹음 시간: ${_formatDuration(recordingState.recordingDuration)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            const Text(
              '녹음된 파일 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: recordingState.recordings.isEmpty
                  ? const Center(child: Text('녹음된 파일이 없습니다.'))
                  : ListView.builder(
                itemCount: recordingState.recordings.length,
                itemBuilder: (context, index) {
                  final recording = recordingState.recordings[index];
                  final file = File(recording.path);
                  return ListTile(
                    title: Text('녹음 파일 ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<int>(
                          future: file.length(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text('로딩 중...');
                            }
                            return Text(
                              '시간: ${_formatDuration(recording.duration)} | 크기: ${_formatFileSize(snapshot.data!)} | 형식: ${_getFileFormat(recording.path)}',
                            );
                          },
                        ),
                        TranscriptionWidget(
                          transcription: recordingState.transcriptions[recording.path],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final isPlaying = ref
                                .watch(recordingViewModelProvider.notifier)
                                .isPlaying(recording.path);
                            return IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: isPlaying ? Colors.blue : Colors.grey,
                              ),
                              onPressed: () {
                                ref
                                    .read(recordingViewModelProvider.notifier)
                                    .playRecording(recording.path);
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.grey),
                          onPressed: () {
                            ref
                                .read(recordingViewModelProvider.notifier)
                                .downloadRecording(recording.path);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.grey),
                          onPressed: () {
                            ref
                                .read(recordingViewModelProvider.notifier)
                                .transcribeRecording(recording.path);
                          },
                        ),
                      ],
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