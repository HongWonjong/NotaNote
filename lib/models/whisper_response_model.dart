/// whisper api로부터의 응답을 저장하는 모델입니다. json 형태를 받아서 그 중 text 필드를 추출하여
/// transcription 필드에 저장합니다.
import 'dart:convert';

class WhisperResponse {
  final String transcription;

  WhisperResponse({required this.transcription});

  factory WhisperResponse.fromJson(String json) {
    final map = jsonDecode(json);
    return WhisperResponse(transcription: map['text'] ?? '');
  }
}