import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';

class LoadingPage extends ConsumerStatefulWidget {
  final String recordingPath;
  final String language;
  final String mode;
  final QuillController controller;
  final RecordingViewModel recordingViewModel;
  final double adProbability; // 0.0 ~ 1.0 범위로 광고 표시 확률 조절

  const LoadingPage({
    required this.recordingPath,
    required this.language,
    required this.mode,
    required this.controller,
    required this.recordingViewModel,
    this.adProbability = 0.0, // 0고정, 다이얼로그 창에서 바꿀 것.
    super.key,
  });

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  bool _transcriptionComplete = false; // 변환 완료 여부
  bool _navigated = false; // 중복 이동 방지 플래그
  bool? _willShowAd; // 광고를 띄울지 여부를 한 번만 판단해 저장

  @override
  void initState() {
    super.initState();
    // 광고를 띄울지 여부를 확률적으로 한 번만 결정
    _willShowAd = widget.adProbability > 0 &&
        widget.adProbability >= Random().nextDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowAdAndStartTranscription();
    });
  }

  // 광고를 띄울지 여부에 따라 광고 또는 변환 실행
  void _maybeShowAdAndStartTranscription() {
    if (_willShowAd == true) {
      _loadAndShowAd(); //광고
    } else {
      _startTranscription(); // 페이지 로드 후 즉시 변환 작업 시작
    }
  }

  // 전면 광고 로딩 및 표시
  void _loadAndShowAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-8918591811866398/2218406512',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              // 광고 콜백 설정
              ad.dispose();
              _checkAndNavigate(); // 광고 종료 후 내비게이션 처리
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _checkAndNavigate(); // 광고 표시 실패 시에도 진행
            },
          );

          ad.show();
          _startTranscription(); // 광고 뜨는 동시에 변환 시작
        },
        onAdFailedToLoad: (LoadAdError error) {
          _startTranscription(); // 광고 실패 시 즉시 변환
        },
      ),
    );
  }

  void _startTranscription() async {
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

      _transcriptionComplete = true;
    } catch (e) {
      // 에러 발생 시 스낵바 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('변환 실패: $e')),
        );
      }
    } finally {
      // 작업 완료/에러 후 이전 페이지로 복귀
      _checkAndNavigate();
    }
  }

  void _checkAndNavigate() {
    if (!mounted || _navigated) return;
    _navigated = true;

    if (_transcriptionComplete) {
      Navigator.of(context).pop(); // 변환 완료 → 메모장 복귀
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _LoadingIndicatorPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 광고 없이 바로 로딩 페이지로 시작하는 경우
    if (_willShowAd == false) {
      return const _LoadingIndicatorPage();
    }

    // 광고를 띄우기로 결정된 경우
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// 실제 로딩 UI를 보여주는 로딩 페이지
class _LoadingIndicatorPage extends StatelessWidget {
  const _LoadingIndicatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로고 (SVG로 변경)
            SvgPicture.asset(
              'assets/icons/LoadingLogo.svg',
              width: 94,
              height: 94,
            ),
            const SizedBox(height: 16),
            const Text(
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
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60CFB1)),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:nota_note/viewmodels/recording_viewmodel.dart';

// class LoadingPage extends ConsumerStatefulWidget {
//   final String recordingPath;
//   final String language;
//   final String mode;
//   final QuillController controller;
//   final RecordingViewModel recordingViewModel;

//   const LoadingPage({
//     required this.recordingPath,
//     required this.language,
//     required this.mode,
//     required this.controller,
//     required this.recordingViewModel,
//     super.key,
//   });

//   @override
//   _LoadingPageState createState() => _LoadingPageState();
// }

// class _LoadingPageState extends ConsumerState<LoadingPage> {
//   @override
//   void initState() {
//     super.initState();
//     // 페이지 로드 후 즉시 변환 작업 시작
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _startTranscription();
//     });
//   }

//   Future<void> _startTranscription() async {
//     try {
//       if (widget.mode == 'original') {
//         await widget.recordingViewModel.transcribeRecording(
//           widget.recordingPath,
//           widget.language,
//           widget.controller,
//         );
//       } else {
//         await widget.recordingViewModel.summarizeRecording(
//           widget.recordingPath,
//           widget.language,
//           widget.controller,
//         );
//       }
//     } catch (e) {
//       // 에러 발생 시 스낵바 표시
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('변환 실패: $e')),
//       );
//     } finally {
//       // 작업 완료/에러 후 이전 페이지로 복귀
//       if (mounted) {
//         Navigator.of(context).pop();
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // 로고 (SVG로 변경)
//             SvgPicture.asset(
//               'assets/icons/LoadingLogo.svg',
//               width: 94,
//               height: 94,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               '텍스트로 변환하고 있습니다.\n잠시만 기다려주세요!',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Color(0xFF191919),
//                 fontSize: 18,
//                 fontFamily: 'Pretendard',
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 16),
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60CFB1)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
