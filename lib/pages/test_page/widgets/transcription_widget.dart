/// whisper api 로부터 텍스트 화 된 음성을 받아서 보여 주는 간단한 예시 위젯 입니다. 필요에 맞게 응용 해 주세요.
import 'package:flutter/material.dart';

class TranscriptionWidget extends StatelessWidget {
  final String? transcription;
  final String emptyMessage;

  const TranscriptionWidget({
    super.key,
    this.transcription,
    this.emptyMessage = '전사 결과 없음',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
            minHeight: 40,
          ),
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Text(
              transcription?.isNotEmpty == true
                  ? 'Whisper AI: $transcription'
                  : emptyMessage,
              style: TextStyle(
                fontSize: 15,
                color: transcription?.isNotEmpty == true
                    ? Colors.black87
                    : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}