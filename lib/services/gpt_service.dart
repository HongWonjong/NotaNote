import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GptService {
  static const String baseUrl = 'https://api.openai.com/v1';
  final String apiKey = dotenv.env['OPENAI_GPT_API_KEY'] ?? '';

  Future<String?> convertToMarkdown(String text) async {
    if (apiKey.isEmpty) {
      print('에러: OPENAI_GPT_API_KEY가 .env 파일에 설정되지 않았습니다.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert at formatting text. Take the following text and return it exactly as provided, without changing any words, punctuation, or content. Only add appropriate spacing and line breaks to make it more readable in Markdown format. Do not use headers, lists, or any other Markdown features unless they are explicitly present in the original text.'
            },
            {'role': 'user', 'content': text},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('GPT Markdown 변환 실패: ${response.statusCode}');
        print('에러 메시지: ${response.body}');
        return null;
      }
    } catch (e) {
      print('GPT Markdown 변환 중 예외 발생: $e');
      return null;
    }
  }

  Future<String?> summarizeToMarkdown(String text,
      {required String language}) async {
    if (apiKey.isEmpty) {
      print('에러: OPENAI_GPT_API_KEY가 .env 파일에 설정되지 않았습니다.');
      return null;
    }

    String languageInstruction = language == 'ko'
        ? 'Respond in Korean.'
        : language == 'en'
            ? 'Respond in English.'
            : 'Respond in the same language as the input text.';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert at summarizing text concisely. Summarize the following text into a brief, well-structured Markdown format, highlighting key points using headers, bullet points, or other Markdown elements. $languageInstruction'
            },
            {'role': 'user', 'content': text},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('GPT 요약 실패: ${response.statusCode}');
        print('에러 메시지: ${response.body}');
        return null;
      }
    } catch (e) {
      print('GPT 요약 중 예외 발생: $e');
      return null;
    }
  }
}

final gptServiceProvider = Provider<GptService>((ref) => GptService());
