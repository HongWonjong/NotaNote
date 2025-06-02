/// whisper api와 통신 하는 서비스 입니다.
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/whisper_response_model.dart';


class WhisperService {
  Future<WhisperResponse?> sendToWhisperAI(String path, String language) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print('파일이 존재하지 않습니다: $path');
        return null;
      }

      final fileSize = await file.length();
      print('Whisper AI로 전송할 파일 크기: $fileSize bytes');
      if (fileSize < 5000) {
        print('경고: 파일 크기가 너무 작습니다(${fileSize} bytes). Whisper AI로 전송하지 않습니다.');
        return null;
      }

      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        print('에러: OPENAI_API_KEY가 .env 파일에 설정되지 않았습니다.');
        return null;
      }

      const url = 'https://api.openai.com/v1/audio/transcriptions';

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = 'whisper-1'
        ..fields['language'] = language
        ..fields['response_format'] = 'json'
        ..files.add(await http.MultipartFile.fromPath('file', path, filename: 'audio.m4a'));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Whisper AI 응답: $responseBody');
        return WhisperResponse.fromJson(responseBody);
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Whisper AI 전송 실패: ${response.statusCode}');
        print('에러 메시지: $errorBody');
        return null;
      }
    } catch (e) {
      print('Whisper AI 전송 중 예외 발생: $e');
      return null;
    }
  }
}

final whisperServiceProvider = Provider<WhisperService>((ref) => WhisperService());