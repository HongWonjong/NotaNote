import 'dart:convert';

String extractPlainText(String content) {
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map && decoded.containsKey('ops')) {
      final buffer = StringBuffer();
      for (final op in decoded['ops']) {
        final insert = op['insert'];
        if (insert is String) {
          buffer.write(insert);
        }
      }
      return buffer.toString();
    }
  } catch (e) {
    // 파싱 실패하면 그냥 원문 반환
  }
  return content;
}

