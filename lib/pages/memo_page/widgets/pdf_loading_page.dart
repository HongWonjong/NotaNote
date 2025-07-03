import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/pages/memo_page/widgets/quill_to_pdf_converter.dart';
import 'package:share_plus/share_plus.dart';

class PdfLoadingPage extends StatefulWidget {
  final Document document;

  const PdfLoadingPage({super.key, required this.document});

  @override
  State<PdfLoadingPage> createState() => _PdfLoadingPageState();
}

class _PdfLoadingPageState extends State<PdfLoadingPage> {
  @override
  void initState() {
    super.initState();
    // 로딩 페이지가 화면에 완전히 그려진 직후에 PDF 생성 및 공유를 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createAndSharePdf();
    });
  }

  Future<void> _createAndSharePdf() async {
    try {
      // 1. PDF 파일을 생성.
      final pdfFile = await PdfGenerator.createPdfFile(widget.document);

      // 2. 파일 생성이 성공했을 경우 공유창을 띄움.
      if (pdfFile != null) {
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          subject: pdfFile.path.split('/').last,
        );
      } else {
        // 3. 실패 시 사용자에게 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF 파일을 생성하는데 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      // 4. 예기치 않은 오류 발생 시 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      // 5. 공유가 끝나거나, 실패하거나, 어떤 경우든 이 페이지를 닫고 이전 화면으로 돌아감.
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PDF가 생성되는 동안 보여줄 로딩 UI
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 녹음 변환과 비슷하게함
            SvgPicture.asset(
              'assets/icons/LoadingLogo.svg',
              width: 94,
              height: 94,
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF 파일을 생성 중입니다.\n잠시만 기다려주세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF191919),
                fontSize: 18,
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60CFB1)),
            ),
          ],
        ),
      ),
    );
  }
}
