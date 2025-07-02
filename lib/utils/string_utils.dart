import 'dart:convert';

String extractPlainTextWithMaxLines(String content, int maxLines) {
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map && decoded.containsKey('ops')) {
      final buffer = StringBuffer();
      int lineCount = 0;

      for (final op in decoded['ops']) {
        final insert = op['insert'];
        if (insert is String) {
          for (final char in insert.runes) {
            final character = String.fromCharCode(char);
            buffer.write(character);
            if (character == '\n') {
              lineCount++;
              if (lineCount >= maxLines) {
                return buffer.toString().trimRight();
              }
            }
          }
        }
      }

      return buffer.toString().trimRight();
    }
  } catch (e) {
    // JSON 파싱 실패시 그냥 일반 텍스트 기준으로 줄 자르기
    return content.split('\n').take(maxLines).join('\n').trimRight();
  }

  return content;
}
