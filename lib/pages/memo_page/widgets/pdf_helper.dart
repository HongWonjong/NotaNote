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

  // Delta를 분석하여 위젯 리스트로 변환하는 최종 로직
  static Future<List<pw.Widget>> _deltaToPdfWidgets(Delta delta) async {
    final List<pw.Widget> widgets = [];
    final List<pw.InlineSpan> currentLineSpans = [];
    var currentBlockAttributes = <String, dynamic>{};
    var listCounter = 1;

    for (final op in delta.toList()) {
      final data = op.data;
      final attributes = op.attributes ?? <String, dynamic>{};

      // 이미지 처리
      if (data is Map<String, dynamic> && data['image'] != null) {
        if (currentLineSpans.isNotEmpty) {
          widgets
              .add(_createLineWidget(currentLineSpans, currentBlockAttributes));
          currentLineSpans.clear();
        }
        widgets.addAll(await _buildImage(data['image'] as String, attributes));
        currentBlockAttributes = {};
        continue;
      }

      if (data is String) {
        final lines = data.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.isNotEmpty) {
            currentLineSpans.add(
              pw.TextSpan(
                text: line,
                style: _getTextStyle(attributes),
                annotation: attributes['link'] is String
                    ? pw.AnnotationUrl(attributes['link'] as String)
                    : null,
              ),
            );
          }

          if (i < lines.length - 1) {
            currentBlockAttributes = op.attributes ?? {};
            if (currentBlockAttributes['list'] == 'ordered') {
              widgets.add(_createLineWidget(
                  currentLineSpans, currentBlockAttributes,
                  counter: listCounter));
              listCounter++;
            } else {
              widgets.add(
                  _createLineWidget(currentLineSpans, currentBlockAttributes));
              listCounter = 1;
            }
            currentLineSpans.clear();
          }
        }
      }
    }
    // 루프가 끝난 후 마지막 라인 처리
    if (currentLineSpans.isNotEmpty) {
      widgets.add(_createLineWidget(currentLineSpans, currentBlockAttributes));
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
      return pw.SizedBox(height: 14 * 0.5);
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
          textAlign: textAlign,
        ),
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

      // 첫 번째 텍스트 조각의 스타일을 가져와서 리스트 기호에 적용
      final pw.TextStyle prefixStyle =
          spans.isNotEmpty && spans.first.style != null
              ? spans.first.style!
              : pw.TextStyle(font: _koreanFont);

      return pw.Container(
        padding: const pw.EdgeInsets.only(left: 16, top: 1.5, bottom: 1.5),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
              width: 20,
              alignment: pw.Alignment.topRight,
              child: pw.Text(prefix, style: prefixStyle)),
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
    if (attributes.containsKey('link')) {
      return pw.TextStyle(
        font: _koreanFont,
        color: PdfColors.blue,
        decoration: pw.TextDecoration.underline,
      );
    }

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
    if (attributes['size'] is num) {
      fontSize = (attributes['size'] as num).toDouble();
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
        double? height;
        final style = attributes['style'] as String?;
        if (style != null) {
          final widthMatch =
              RegExp(r'width:\s*(\d+\.?\d*)px').firstMatch(style);
          if (widthMatch != null && widthMatch.group(1) != null) {
            width = double.tryParse(widthMatch.group(1)!)! * 0.75;
          }

          final heightMatch =
              RegExp(r'height:\s*(\d+\.?\d*)px').firstMatch(style);
          if (heightMatch != null && heightMatch.group(1) != null) {
            height = double.tryParse(heightMatch.group(1)!)! * 0.75;
          }
        }

        return [
          pw.Container(
              alignment: _getAlignment(attributes),
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Image(pdfImage,
                  width: width, height: height, fit: pw.BoxFit.contain))
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
