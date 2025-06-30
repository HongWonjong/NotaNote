import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_page/main_page.dart';
import 'package:logger/logger.dart';
import 'package:nota_note/providers/onboarding_provider.dart';

class OnBoardingPage extends ConsumerStatefulWidget {
  const OnBoardingPage({super.key});

  @override
  ConsumerState<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends ConsumerState<OnBoardingPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final logger = Logger();

  final List<Map<String, String>> _onBoardingContents = [
    {
      'title': '나만의 메모장을',
      'subtitle': '다양한 텍스트 속성과 사진을 추가해서 \n메모장을 꾸며보세요.',
      'image': 'assets/images/onboarding1.png',
    },
    {
      'title': '비슷한 내용은 해시태그로,',
      'subtitle': '해시태그를 추가해서 \n비슷한 주제의 메모를 쉽게 구분해요.',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': '녹음은 AI 텍스트로 변환하고',
      'subtitle': '녹음을 텍스트로 변환해서 \n요약하여 메모에 정리할 수 있어요.',
      'image': 'assets/images/onboarding3.png',
    },
    {
      'title': '다른사람과 공유해요',
      'subtitle': '친구나 팀원과 공유해서 \n함께 내용을 편집해보세요.',
      'image': 'assets/images/onboarding4.png',
    },
  ];

  void _onNext() {
    if (_currentStep < _onBoardingContents.length - 1) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToMain();
    }
  }

  void _skipToLast() {
    _pageController.animateToPage(
      _onBoardingContents.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToMain() async {
    logger.i('온보딩 페이지 - 시작하기 버튼 눌림, 온보딩 완료 처리 시작');
    await ref.read(onBoardingProvider.notifier).completeOnBoarding();
    logger.i('온보딩 페이지 - 온보딩 완료 처리 후 메인 페이지로 이동');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF61CFB2);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToLast,
                  child: const Text(
                    '건너뛰기',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemCount: _onBoardingContents.length,
                  itemBuilder: (context, index) {
                    final content = _onBoardingContents[index];
                    return Column(
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          content['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
  content['subtitle'] ?? '',
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 16,             // Label/m에 맞는 크기 (예: 14)
    color: Color(0xFF757575), // Gray/600 
    fontWeight: FontWeight.w400, // 보통 굵기
  ),
),
                        const SizedBox(height: 44),
                        Expanded(
                          child: Column(
                            children: [
                              if (content['image'] != null)
                                SizedBox(
                                  height: 420,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.asset(
                                            content['image']!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          height: 80, // 그라디언트 높이 조절
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.white,
                                                    Colors.white.withOpacity(0.0),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_onBoardingContents.length, (i) {
                                  final isActive = _currentStep == i;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    width: isActive ? 24 : 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isActive ? Color(0xFF61CFB2) : Colors.grey[400],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _currentStep == _onBoardingContents.length - 1
                          ? themeColor
                          : Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == _onBoardingContents.length - 1
                      ? '시작하기'
                      : '다음',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
