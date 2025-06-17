import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/providers/user_profile_provider.dart';
import 'package:nota_note/pages/on_boarding_page/on_boarding_page.dart';

/// 스플래시 페이지 (로그인 여부에 따라 분기)
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  /// 로그인 여부 확인 → 로그인 or 홈 화면 분기
  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // 스플래시 유지 시간

    // 세션 유효성을 고려한 userId 조회 (google은 유지, kakao는 세션 검사, apple은 무조건 null)
    final userId = await getCurrentUserId(appLaunch: true);
    if (!mounted) return;

    if (userId == null) {
      // 세션 없음 → 로그인 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    // 세션 있음 → 해당 userId로 사용자 정보 로딩
    final userAsync = await ref.read(userProfileProvider(userId).future);
    if (!mounted) return;

    if (userAsync == null) {
      // Firestore에 사용자 정보 없음 → 로그인 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      // Firestore에 사용자 정보 있음 → 온보딩 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnBoardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF9BDBCA), // 왼쪽 색상
              Color(0xFF76D6A3), // 오른쪽 색상
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 위쪽 아이콘
              SvgPicture.asset(
                'assets/icons/SplashVector.svg',
                width: 100,
                height: 100,
                placeholderBuilder: (context) =>
                    const CircularProgressIndicator(),
              ),
              const SizedBox(height: 32),
              // 아래쪽 아이콘 (NotaNote 텍스트 형태의 SVG)
              SvgPicture.asset(
                'assets/icons/SplashNotaNote.svg',
                width: 141,
                height: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
