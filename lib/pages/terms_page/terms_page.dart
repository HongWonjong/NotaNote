import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  String? _markdownData;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    final data =
        await rootBundle.loadString('assets/terms/terms_of_service.md');
    setState(() => _markdownData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이용약관',
            style: PretendardTextStyles.titleS.copyWith(
              color: AppColors.gray900,
            )),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.gray700,
        ),
      ),
      body: _markdownData == null
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              data: _markdownData!,
              //폰트 바꾸기
              styleSheet: MarkdownStyleSheet(
                p: PretendardTextStyles.bodyS,
                h1: PretendardTextStyles.headM,
                h2: PretendardTextStyles.titleM,
                h3: PretendardTextStyles.titleS,
                listBullet: PretendardTextStyles.bodyS,
              ),
            ),
    );
  }
}
