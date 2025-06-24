import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';

//플랫폼 별로 다른 api호출
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

Future<pw.Font> loadKoreanFont() async {
  final fontData = await rootBundle.load('assets/fonts/NotoSansKR-Regular.otf');
  return pw.Font.ttf(fontData);
}

// Text > Image > PDF(캡처를 통한 PDF 변환)
Future<void> saveNoteAsImagePdf({
  required BuildContext context,
  required GlobalKey repaintKey,
  required String fileName,
}) async {
  try {
    // 캡처 타이밍 확보
    await Future.delayed(const Duration(milliseconds: 100));

    final boundaryContext = repaintKey.currentContext;
    if (boundaryContext == null)
      throw Exception('화면 캡처에 실패했습니다. 잠시 후 다시 시도해 주세요.');

    // 1. 이미지 캡처
    RenderRepaintBoundary boundary =
        boundaryContext.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) throw Exception('이미지 변환 실패');
    Uint8List pngBytes = byteData.buffer.asUint8List();

    // 2. PDF에 이미지 삽입
    final pdf = pw.Document();
    final imageProvider = pw.MemoryImage(pngBytes);
    pdf.addPage(
      pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(imageProvider));
      }),
    );

    // 3. 저장
    // final dir = await getExternalStorageDirectory(); << 안드로이드 전용 API이므로 ios에선 오류남.
    final dir = await _getSaveDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF로 저장되었습니다.')),
      );
      print('PDF 저장 경로: ${file.path}');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 저장 실패: $e')),
      );
    }
  }
}

// Text > PDF(텍스트 위젯을 바로 PDF 변환)
Future<void> saveTextAsPdf({
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
            child: pw.Text(text, style: pw.TextStyle(font: ttf, fontSize: 18)),
          );
        },
      ),
    );

    // final dir = await getExternalStorageDirectory();
    final dir = await _getSaveDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF로 저장되었습니다.')),
      );
      print('PDF 저장 경로: ${file.path}');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 저장 실패: $e')),
      );
    }
  }
}
