import 'package:flutter/material.dart';
import '../main_page/main_page.dart';


class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  int _currentStep = 0;

  final List<Map<String, String>> _onBoardingContents = [
  {
    'title': '다양한 레이아웃으로\n나만의 메모장을 만들어요',
    'image': 'assets/images/onboarding1.png',
  },
  {
    'title': 'AI 기능으로 음성을 텍스트로 변환하고,\n내용을 요약해서 관리할 수 있어요',
    'image': 'assets/images/onboarding2.png',
  },
  {
    'title': '친구나 팀원과 메모를 공유해\n함께 내용을 편집해보세요',
    'image': 'assets/images/onboarding3.png',
  },
];

  void _onNext() {
    if (_currentStep < _onBoardingContents.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _goToMain();
    }
  }

  void _skipToLast() {
    setState(() {
      _currentStep = _onBoardingContents.length - 1;
    });
  }

  void _goToMain() {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const MainPage()),
  );
}

  @override
  Widget build(BuildContext context) {
    final content = _onBoardingContents[_currentStep];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToLast,
                  child: const Text('건너뛰기', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                content['title'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: content['image'] != null
                            ? Image.asset(content['image']!, fit: BoxFit.contain)
                            : const Text('이미지 없음'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_onBoardingContents.length, (index) {
                        final isActive = _currentStep == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentStep = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.black : Colors.grey[400],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == _onBoardingContents.length - 1 ? '시작하기' : '다음',
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
