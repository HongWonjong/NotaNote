import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';

class LoadingPage extends ConsumerStatefulWidget {
  final String recordingPath;
  final String language;
  final String mode;
  final QuillController controller;
  final RecordingViewModel recordingViewModel;

  const LoadingPage({
    required this.recordingPath,
    required this.language,
    required this.mode,
    required this.controller,
    required this.recordingViewModel,
    super.key,
  });

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 로드 후 즉시 변환 작업 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTranscription();
    });
  }

  Future<void> _startTranscription() async {
    try {
      if (widget.mode == 'original') {
        await widget.recordingViewModel.transcribeRecording(
          widget.recordingPath,
          widget.language,
          widget.controller,
        );
      } else {
        await widget.recordingViewModel.summarizeRecording(
          widget.recordingPath,
          widget.language,
          widget.controller,
        );
      }
    } catch (e) {
      // 에러 발생 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변환 실패: $e')),
      );
    } finally {
      // 작업 완료/에러 후 이전 페이지로 복귀
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 로고 (SVG로 변경)
            SvgPicture.asset(
              'assets/icons/LoadingLogo.svg',
              width: 94,
              height: 94,
            ),
            const SizedBox(height: 16),
            Text(
              '텍스트로 변환하고 있습니다.\n잠시만 기다려주세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF191919),
                fontSize: 18,
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60CFB1)),
            ),
          ],
        ),
      ),
    );
  }
}