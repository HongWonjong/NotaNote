import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PdfGenerator {
  // 폰트 캐싱을 위한 변수
  static pw.Font? _koreanFont;
  static pw.Font? _monoFont;

  // 폰트 로드 및 캐싱
  static Future<void> _loadFonts() async {
    if (_koreanFont == null) {
      final fontData =
          await rootBundle.load('assets/fonts/Pretendard-Regular.ttf');
      _koreanFont = pw.Font.ttf(fontData);
    }
    if (_monoFont == null) {
      final fontData =
          await rootBundle.load('assets/fonts/Pretendard-Regular.ttf');
      _monoFont = pw.Font.ttf(fontData);
    }
  }

  // 공개 메소드: Document를 받아 PDF 생성 및 공유를 시작
  static Future<void> exportToPdf(Document document) async {
    try {
      await _loadFonts();
      final pdf = pw.Document();
      final widgets = await _deltaToPdfWidgets(document.toDelta());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => widgets,
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName = "nota_note_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], subject: fileName);
    } catch (e) {
      print("PDF 생성 실패: $e");
    }
  }

  static Future<List<pw.Widget>> _deltaToPdfWidgets(Delta delta) async {
    final List<pw.Widget> widgets = [];
    final List<pw.InlineSpan> currentLineSpans = [];
    var listCounter = 1;

    for (final op in delta.toList()) {
      final data = op.data;
      final attributes = op.attributes ?? <String, dynamic>{};

      // 이미지 처리
      if (data is Map<String, dynamic> && data['image'] != null) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(_createLineWidget(currentLineSpans, {}));
          currentLineSpans.clear();
        }
        widgets.addAll(await _buildImage(data['image'] as String, attributes));
        continue;
      }

      if (data is String) {
        final lines = data.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.isNotEmpty) {
            currentLineSpans
                .add(pw.TextSpan(text: line, style: _getTextStyle(attributes)));
          }

          if (i < lines.length - 1) {
            final blockAttributes = op.attributes ?? {};
            if (blockAttributes['list'] == 'ordered') {
              widgets.add(_createLineWidget(currentLineSpans, blockAttributes,
                  counter: listCounter));
              listCounter++;
            } else {
              widgets.add(_createLineWidget(currentLineSpans, blockAttributes));
              listCounter = 1;
            }
            currentLineSpans.clear();
          }
        }
      }
    }
    if (currentLineSpans.isNotEmpty) {
      widgets.add(_createLineWidget(currentLineSpans, {}));
    }
    return widgets;
  }

  // 한 줄의 텍스트(spans)를 받아 적절한 블록 스타일 위젯으로 감싸는 함수
  static pw.Widget _createLineWidget(
      List<pw.InlineSpan> spans, Map<String, dynamic> attributes,
      {int? counter}) {
    final textAlign = _getTextAlign(attributes);
    final richText = pw.RichText(
        text: pw.TextSpan(children: List.of(spans)),
        softWrap: true,
        textAlign: textAlign);

    if (spans.isEmpty) {
      return pw.SizedBox(height: 14 * 0.7);
    }

    final alignment = _getAlignment(attributes);

    // 헤더
    if (attributes.containsKey('header')) {
      return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
        child: pw.DefaultTextStyle(
            style: _getHeadlineStyle(attributes['header']), child: richText),
      );
    }
    // 코드 블럭
    if (attributes.containsKey('code-block')) {
      return pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F5F5F5'),
            borderRadius: pw.BorderRadius.circular(4)),
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.DefaultTextStyle(
            style: pw.TextStyle(font: _monoFont, fontSize: 12),
            child: richText,
            textAlign: textAlign),
      );
    }
    // 인용문
    if (attributes.containsKey('blockquote')) {
      return pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
            border: pw.Border(
                left: pw.BorderSide(color: PdfColors.grey, width: 2))),
        padding: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
        margin: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.DefaultTextStyle(
            style: pw.TextStyle(color: PdfColors.grey700, font: _koreanFont),
            child: richText),
      );
    }
    // 리스트
    if (attributes.containsKey('list')) {
      String prefix = attributes['list'] == 'bullet' ? '•' : '${counter ?? 1}.';
      return pw.Container(
        padding: const pw.EdgeInsets.only(left: 16, top: 1.5, bottom: 1.5),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
              width: 20,
              alignment: pw.Alignment.topRight,
              child: pw.Text(prefix, style: pw.TextStyle(font: _koreanFont))),
          pw.SizedBox(width: 5),
          pw.Expanded(child: richText),
        ]),
      );
    }
    // 일반 텍스트
    return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: richText);
  }

  static pw.TextAlign? _getTextAlign(Map<String, dynamic> attributes) {
    switch (attributes['align'] as String?) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      case 'justify':
        return pw.TextAlign.justify;
      default:
        return null;
    }
  }

  static pw.Alignment _getAlignment(Map<String, dynamic> attributes) {
    switch (attributes['align'] as String?) {
      case 'center':
        return pw.Alignment.center;
      case 'right':
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  static pw.TextStyle _getHeadlineStyle(dynamic level) {
    double fontSize;
    switch (level) {
      case 1:
        fontSize = 22;
        break;
      case 2:
        fontSize = 20;
        break;
      case 3:
        fontSize = 18;
        break;
      default:
        fontSize = 14;
    }
    return pw.TextStyle(
        fontSize: fontSize, fontWeight: pw.FontWeight.bold, font: _koreanFont);
  }

  static pw.TextStyle _getTextStyle(Map<String, dynamic> attributes) {
    PdfColor? color;
    if (attributes['color'] is String) {
      try {
        color = PdfColor.fromHex(attributes['color']);
      } catch (e) {}
    }

    PdfColor? background;
    if (attributes['background'] is String) {
      try {
        background = PdfColor.fromHex(attributes['background']);
      } catch (e) {}
    }

    double? fontSize;
    final sizeAttr = attributes['size'];
    if (sizeAttr == 'small') {
      fontSize = 11;
    } else if (sizeAttr == 'large') {
      fontSize = 17;
    } else if (sizeAttr == 'huge') {
      fontSize = 20;
    }

    return pw.TextStyle(
      font: _koreanFont,
      fontWeight: attributes['bold'] == true
          ? pw.FontWeight.bold
          : pw.FontWeight.normal,
      fontStyle: attributes['italic'] == true
          ? pw.FontStyle.italic
          : pw.FontStyle.normal,
      color: color,
      background: pw.BoxDecoration(color: background),
      decoration: pw.TextDecoration.combine([
        if (attributes['underline'] == true) pw.TextDecoration.underline,
        if (attributes['strike'] == true) pw.TextDecoration.lineThrough,
      ]),
      fontSize: fontSize,
    );
  }

  static Future<List<pw.Widget>> _buildImage(
      String url, Map<String, dynamic> attributes) async {
    try {
      final imageBytes = await _getImageBytes(url);
      if (imageBytes != null) {
        final pdfImage = pw.MemoryImage(imageBytes);

        double? width;
        final style = attributes['style'] as String?;
        if (style != null) {
          final widthMatch =
              RegExp(r'width:\s*(\d+\.?\d*)px').firstMatch(style);
          if (widthMatch != null && widthMatch.group(1) != null) {
            final parsedPx = double.tryParse(widthMatch.group(1)!);
            if (parsedPx != null) {
              width = parsedPx * 0.75;
            }
          }
        }

        return [
          pw.Container(
              alignment: _getAlignment(attributes),
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Image(pdfImage, width: width, fit: pw.BoxFit.contain))
        ];
      }
    } catch (e) {
      print("이미지 로드 실패: $url, 오류: $e");
    }
    return [pw.SizedBox()];
  }

  static Future<Uint8List?> _getImageBytes(String url) async {
    if (url.startsWith('http')) {
      final response = await http.get(Uri.parse(url));
      return response.bodyBytes;
    } else if (url.startsWith('data:')) {
      return Uri.parse(url).data?.contentAsBytes();
    } else if (File(url).existsSync()) {
      return await File(url).readAsBytes();
    }
    return null;
  }
}
// import 'dart:async';
// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_quill/flutter_quill.dart' as quill;
// import 'package:flutter_quill/quill_delta.dart' as quill;
// import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:share_plus/share_plus.dart';

// // 저장 경로
// Future<Directory> _getSaveDirectory() async {
//   if (Platform.isAndroid) {
//     return await getExternalStorageDirectory() ??
//         await getApplicationDocumentsDirectory();
//   } else if (Platform.isIOS) {
//     return await getApplicationDocumentsDirectory();
//   } else {
//     throw Exception('지원하지 않는 플랫폼입니다.');
//   }
// }

// Future<void> captureMemoAsFullPdf({
//   required ScaffoldMessengerState scaffoldMessenger,
//   required GlobalKey repaintKey,
//   required String fileName,
// }) async {
//   try {
//     RenderRepaintBoundary? boundary =
//         repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//     if (boundary == null) {
//       debugPrint("캡처할 RepaintBoundary를 찾을 수 없습니다.");
//       return;
//     }

//     // 이미지 캡처
//     ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//     ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

//     if (byteData == null) {
//       debugPrint("이미지 캡처 실패");
//       scaffoldMessenger.showSnackBar(
//         SnackBar(content: Text("이미지 캡처 실패")),
//       );
//       return;
//     }

//     // 3. PDF로 변환 (한 페이지로 충분)
//     final pdf = pw.Document();
//     final img = pw.MemoryImage(byteData.buffer.asUint8List());

//     pdf.addPage(
//       pw.Page(
//         margin: pw.EdgeInsets.zero,
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context ctx) {
//           return pw.Image(
//             img,
//             // 이미지가 페이지의 가로에 꽉 차도록 설정
//             fit: pw.BoxFit.fitWidth,
//           );
//         },
//       ),
//     );

//     // 저장 및 공유
//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/$fileName.pdf');
//     await file.writeAsBytes(await pdf.save());

//     await Share.shareXFiles(
//       [XFile(file.path)],
//       subject: fileName, // 이메일 앱 등에서 제목으로 사용됨
//     );
//   } catch (e) {
//     debugPrint("PDF 생성 실패: $e");
//     scaffoldMessenger.showSnackBar(
//       SnackBar(content: Text('PDF 저장/공유 실패: $e')),
//     );
//   }
// }

// // Widget buildFullMemoEditor() {
// //   return Material(
// //     color: Colors.white,
// //     child: Container(
// //       padding: EdgeInsets.all(20),
// //       width: 1080, // 또는 null (auto)
// //       child: quill.QuillEditor(
// //         controller: quill.QuillController.basic(),
// //         focusNode: FocusNode(),
// //         scrollController: ScrollController(),
// //         config: quill.QuillEditorConfig(
// //           embedBuilders: FlutterQuillEmbeds.editorBuilders(),
// //           padding: EdgeInsets.zero,
// //           scrollable: false,
// //           autoFocus: false,
// //           expands: false,
// //           showCursor: false,
// //         ),
// //       ),
// //     ),
// //   );
// // }

// // 이 밑으로는 일일이 파싱하다가 너무 달라서 포기

// // Pretendard 폰트
// Future<pw.Font> loadKoreanFont() async {
//   final fontData = await rootBundle.load('assets/fonts/Pretendard-Regular.ttf');
//   return pw.Font.ttf(fontData);
// }

// // 코드블럭용 고정폭 폰트
// Future<pw.Font> loadMonoFont() async {
//   final fontData = await rootBundle.load('assets/fonts/Pretendard-Regular.ttf');
//   return pw.Font.ttf(fontData);
// }

// // Delta → PDF 위젯 변환 (폰트/간격/정렬/코드블럭 등 최대한 반영)
// Future<List<pw.Widget>> deltaToPdfWidgets(
//     quill.Delta delta, pw.Font font, pw.Font monoFont) async {
//   List<pw.Widget> widgets = [];
//   int orderedCount = 1; // 번호형 리스트 카운터

//   for (final op in delta.toList()) {
//     final data = op.data;
//     final attr = op.attributes ?? {};

//     // 정렬(기본: 왼쪽)
//     pw.TextAlign align = pw.TextAlign.left;
//     if (attr['align'] == 'center') align = pw.TextAlign.center;
//     if (attr['align'] == 'right') align = pw.TextAlign.right;
//     if (attr['align'] == 'justify') align = pw.TextAlign.justify;

//     // 텍스트 스타일
//     pw.TextStyle style = pw.TextStyle(
//       font: font,
//       fontSize: (attr['size'] == 'large')
//           ? 32
//           : (attr['size'] == 'small')
//               ? 12
//               : 18,
//       fontWeight:
//           attr['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
//       fontStyle:
//           attr['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
//       decoration: pw.TextDecoration.combine([
//         if (attr['underline'] == true) pw.TextDecoration.underline,
//         if (attr['strike'] == true) pw.TextDecoration.lineThrough,
//       ]),
//       color: attr['color'] != null
//           ? PdfColor.fromInt(int.parse(attr['color'].replaceFirst('#', '0xff')))
//           : PdfColors.black,
//       // lineSpacing은 pdf 패키지에서 스타일에 직접 없음 → 아래 SizedBox로 조절
//     );

//     // 코드블럭
//     if (attr['code-block'] == true) {
//       widgets.add(
//         pw.Container(
//           width: double.infinity,
//           color: PdfColor.fromHex('#F5F5F5'),
//           padding: const pw.EdgeInsets.all(8),
//           margin: const pw.EdgeInsets.symmetric(vertical: 4),
//           child: pw.Text(
//             data?.toString() ?? '',
//             style: pw.TextStyle(
//               font: monoFont,
//               fontSize: 14,
//               color: PdfColors.blueGrey800,
//             ),
//           ),
//         ),
//       );
//       continue;
//     }

//     // 리스트(ordered/bullet)
//     if (attr['list'] == 'ordered') {
//       widgets.add(
//         pw.Row(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text('${orderedCount++}. ',
//                 style: style.copyWith(fontWeight: pw.FontWeight.bold)),
//             pw.Expanded(
//               child: pw.Text(data is String ? data.trim() : '',
//                   style: style, textAlign: align),
//             ),
//           ],
//         ),
//       );
//       widgets.add(pw.SizedBox(height: 8)); // 줄간격
//       continue;
//     }
//     if (attr['list'] == 'bullet') {
//       widgets.add(
//         pw.Row(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text('•  ', style: style),
//             pw.Expanded(
//               child: pw.Text(data is String ? data.trim() : '',
//                   style: style, textAlign: align),
//             ),
//           ],
//         ),
//       );
//       widgets.add(pw.SizedBox(height: 8));
//       continue;
//     }

//     // 일반 텍스트
//     if (data is String) {
//       widgets.add(
//         pw.Container(
//           width: double.infinity,
//           child: pw.Text(
//             data,
//             style: style,
//             textAlign: align,
//           ),
//         ),
//       );
//       widgets.add(pw.SizedBox(height: 4)); // 줄간격 보정
//     }

//     // 이미지
//     else if (data is Map && data['image'] != null) {
//       String imageUrl = data['image'].toString();
//       Uint8List? imageBytes;
//       if (imageUrl.startsWith('http')) {
//         final res = await http.get(Uri.parse(imageUrl));
//         imageBytes = res.bodyBytes;
//       } else if (imageUrl.startsWith('data:image')) {
//         final uriData = Uri.parse(imageUrl);
//         imageBytes = uriData.data!.contentAsBytes();
//       } else {
//         final file = File(imageUrl);
//         imageBytes = await file.readAsBytes();
//       }
//       widgets.add(pw.SizedBox(height: 16));
//       widgets.add(
//         pw.Center(
//           child: pw.Image(pw.MemoryImage(imageBytes), width: 320),
//         ),
//       );
//       widgets.add(pw.SizedBox(height: 8));
//     }

//     // TODO: 표, 인라인 코드, 배경색, blockQuote 등도 확장 가능
//   }

//   return widgets;
// }

// // Delta → PDF 생성+공유
// Future<void> exportDeltaToPdfAndShare({
//   required quill.Delta delta,
//   required String fileName,
//   required BuildContext context,
// }) async {
//   try {
//     final pdf = pw.Document();
//     final ttf = await loadKoreanFont();
//     final mono = await loadMonoFont();

//     final widgets = await deltaToPdfWidgets(delta, ttf, mono);

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(24),
//         build: (pw.Context context) => widgets,
//       ),
//     );

//     final dir = await _getSaveDirectory();
//     final file = File('${dir.path}/$fileName.pdf');
//     await file.writeAsBytes(await pdf.save());

//     if (context.mounted) {
//       await Share.shareXFiles([XFile(file.path)]);
//     }
//   } catch (e) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF 저장/공유 실패: $e')),
//       );
//     }
//   }
// }
