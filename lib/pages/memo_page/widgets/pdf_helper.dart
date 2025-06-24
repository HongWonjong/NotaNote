import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';

// Text > Image > PDF(캡처를 통한 PDF 변환)
Future<void> saveNoteAsImagePdf({
  required BuildContext context,
  required GlobalKey repaintKey,
  required String fileName,
}) async {
  try {
    // 1. 이미지 캡처
    RenderRepaintBoundary boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // 2. PDF에 이미지 삽입
    final pdf = pw.Document();
    final imageProvider = pw.MemoryImage(pngBytes);
    pdf.addPage(
      pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(imageProvider));
      }),
    );

    // 3. 저장
    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF로 저장되었습니다.')),
      );
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Text(text, style: pw.TextStyle(fontSize: 18)),
          );
        },
      ),
    );

    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF로 저장되었습니다.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 저장 실패: $e')),
      );
    }
  }
}
