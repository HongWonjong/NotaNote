import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

// 저장 경로 구하기
Future<Directory> _getSaveDirectory() async {
  if (Platform.isAndroid) {
    return await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
  } else if (Platform.isIOS) {
    return await getApplicationDocumentsDirectory();
  } else {
    throw Exception('지원하지 않는 플랫폼입니다.');
  }
}

// Pretendard 폰트 로딩
Future<pw.Font> loadKoreanFont() async {
  final fontData = await rootBundle.load('assets/fonts/Pretendard-Regular.ttf');
  return pw.Font.ttf(fontData);
}

// 텍스트 → PDF 저장 & 공유
Future<void> saveTextAsPdfAndShare({
  required String text,
  required String fileName,
  required BuildContext context,
}) async {
  try {
    final pdf = pw.Document();
    final ttf = await loadKoreanFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Text(
              text,
              style: pw.TextStyle(font: ttf, fontSize: 18),
            ),
          );
        },
      ),
    );

    final dir = await _getSaveDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF로 저장 및 공유 다이얼로그를 엽니다.')),
      );
      await Share.shareXFiles([XFile(file.path)], text: '메모 PDF를 공유합니다.');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 저장/공유 실패: $e')),
      );
    }
  }
}
