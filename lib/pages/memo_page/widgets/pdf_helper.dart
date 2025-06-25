import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

// 저장 경로
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

Future<void> captureMemoAsFullPdf({
  required BuildContext context,
  required GlobalKey repaintKey,
  required String fileName,
}) async {
  try {
    // 1. 현재 화면의 RepaintBoundary를 바로 찾는다
    RenderRepaintBoundary? boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      debugPrint("캡처할 RepaintBoundary를 찾을 수 없습니다.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("캡처할 영역을 찾을 수 없습니다.")),
      );
      return;
    }

    // 2. 이미지 캡처
    ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      debugPrint("이미지 캡처 실패");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지 캡처 실패")),
      );
      return;
    }

    // 3. PDF로 변환 (한 페이지로 충분)
    final pdf = pw.Document();
    final img = pw.MemoryImage(byteData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Center(
            child: pw.Image(img, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    // 4. 저장 및 공유 (PDF 1개만)
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: "전체 노트 PDF");
  } catch (e) {
    debugPrint("PDF 생성 실패: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF 저장/공유 실패: $e')),
    );
  }
}

Widget buildFullMemoEditor() {
  return Material(
    color: Colors.white,
    child: Container(
      padding: EdgeInsets.all(20),
      width: 1080, // 또는 null (auto)
      child: quill.QuillEditor(
        controller: quill.QuillController.basic(),
        focusNode: FocusNode(),
        scrollController: ScrollController(),
        config: quill.QuillEditorConfig(
          embedBuilders: FlutterQuillEmbeds.editorBuilders(),
          padding: EdgeInsets.zero,
          scrollable: false,
          autoFocus: false,
          expands: false,
          showCursor: false,
        ),
      ),
    ),
  );
}

// 이 밑으로는 일일이 파싱하다가 너무 달라서 포기

// Pretendard 폰트
Future<pw.Font> loadKoreanFont() async {
  final fontData = await rootBundle.load('assets/fonts/Pretendard-Regular.ttf');
  return pw.Font.ttf(fontData);
}

// 코드블럭용 고정폭 폰트
Future<pw.Font> loadMonoFont() async {
  final fontData = await rootBundle.load('assets/fonts/Pretendard-Regular.ttf');
  return pw.Font.ttf(fontData);
}

// Delta → PDF 위젯 변환 (폰트/간격/정렬/코드블럭 등 최대한 반영)
Future<List<pw.Widget>> deltaToPdfWidgets(
    quill.Delta delta, pw.Font font, pw.Font monoFont) async {
  List<pw.Widget> widgets = [];
  int orderedCount = 1; // 번호형 리스트 카운터

  for (final op in delta.toList()) {
    final data = op.data;
    final attr = op.attributes ?? {};

    // 정렬(기본: 왼쪽)
    pw.TextAlign align = pw.TextAlign.left;
    if (attr['align'] == 'center') align = pw.TextAlign.center;
    if (attr['align'] == 'right') align = pw.TextAlign.right;
    if (attr['align'] == 'justify') align = pw.TextAlign.justify;

    // 텍스트 스타일
    pw.TextStyle style = pw.TextStyle(
      font: font,
      fontSize: (attr['size'] == 'large')
          ? 32
          : (attr['size'] == 'small')
              ? 12
              : 18,
      fontWeight:
          attr['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle:
          attr['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
      decoration: pw.TextDecoration.combine([
        if (attr['underline'] == true) pw.TextDecoration.underline,
        if (attr['strike'] == true) pw.TextDecoration.lineThrough,
      ]),
      color: attr['color'] != null
          ? PdfColor.fromInt(int.parse(attr['color'].replaceFirst('#', '0xff')))
          : PdfColors.black,
      // lineSpacing은 pdf 패키지에서 스타일에 직접 없음 → 아래 SizedBox로 조절
    );

    // 코드블럭
    if (attr['code-block'] == true) {
      widgets.add(
        pw.Container(
          width: double.infinity,
          color: PdfColor.fromHex('#F5F5F5'),
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            data?.toString() ?? '',
            style: pw.TextStyle(
              font: monoFont,
              fontSize: 14,
              color: PdfColors.blueGrey800,
            ),
          ),
        ),
      );
      continue;
    }

    // 리스트(ordered/bullet)
    if (attr['list'] == 'ordered') {
      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('${orderedCount++}. ',
                style: style.copyWith(fontWeight: pw.FontWeight.bold)),
            pw.Expanded(
              child: pw.Text(data is String ? data.trim() : '',
                  style: style, textAlign: align),
            ),
          ],
        ),
      );
      widgets.add(pw.SizedBox(height: 8)); // 줄간격
      continue;
    }
    if (attr['list'] == 'bullet') {
      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  ', style: style),
            pw.Expanded(
              child: pw.Text(data is String ? data.trim() : '',
                  style: style, textAlign: align),
            ),
          ],
        ),
      );
      widgets.add(pw.SizedBox(height: 8));
      continue;
    }

    // 일반 텍스트
    if (data is String) {
      widgets.add(
        pw.Container(
          width: double.infinity,
          child: pw.Text(
            data,
            style: style,
            textAlign: align,
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 4)); // 줄간격 보정
    }

    // 이미지
    else if (data is Map && data['image'] != null) {
      String imageUrl = data['image'].toString();
      Uint8List? imageBytes;
      if (imageUrl.startsWith('http')) {
        final res = await http.get(Uri.parse(imageUrl));
        imageBytes = res.bodyBytes;
      } else if (imageUrl.startsWith('data:image')) {
        final uriData = Uri.parse(imageUrl);
        imageBytes = uriData.data!.contentAsBytes();
      } else {
        final file = File(imageUrl);
        imageBytes = await file.readAsBytes();
      }
      widgets.add(pw.SizedBox(height: 16));
      widgets.add(
        pw.Center(
          child: pw.Image(pw.MemoryImage(imageBytes), width: 320),
        ),
      );
      widgets.add(pw.SizedBox(height: 8));
    }

    // TODO: 표, 인라인 코드, 배경색, blockQuote 등도 확장 가능
  }

  return widgets;
}

// Delta → PDF 생성+공유
Future<void> exportDeltaToPdfAndShare({
  required quill.Delta delta,
  required String fileName,
  required BuildContext context,
}) async {
  try {
    final pdf = pw.Document();
    final ttf = await loadKoreanFont();
    final mono = await loadMonoFont();

    final widgets = await deltaToPdfWidgets(delta, ttf, mono);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => widgets,
      ),
    );

    final dir = await _getSaveDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 저장/공유 실패: $e')),
      );
    }
  }
}
