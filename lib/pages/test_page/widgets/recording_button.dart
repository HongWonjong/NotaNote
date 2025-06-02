/// 간단한 녹음 기능과 버튼 클릭에 따른 상태 변화가 담긴 위젯입니다. 응용해서 사용해주세요.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';

class RecordingButton extends ConsumerWidget {
  const RecordingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final isRecording = recordingState.isRecording;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isRecording
            ? [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ]
            : [],
      ),
      child: ElevatedButton(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRecording ? Icons.stop : Icons.mic,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              isRecording ? '녹음 중지' : '녹음 시작',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}