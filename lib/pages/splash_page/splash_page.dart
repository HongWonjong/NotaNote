import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/providers/user_profile_provider.dart';
import 'package:nota_note/pages/on_boarding_page/on_boarding_page.dart';
import 'package:nota_note/pages/main_page/main_page.dart';
import 'package:nota_note/providers/onboarding_provider.dart';
import 'package:logger/logger.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    logger.i('스플래시 페이지 - 네비게이션 시작');
    await Future.delayed(const Duration(seconds: 2));
    logger.i('스플래시 페이지 - 2초 대기 완료');

    if (!mounted) return;

    // 모든 비동기 작업을 기다림
    final results = await Future.wait([
      ref.read(onBoardingStatusFutureProvider.future),
      getCurrentUserId(appLaunch: true),
      // userProfileProvider는 userId가 확정된 후에 호출해야 하므로 여기서 바로 호출하지 않음
    ]);

    final hasCompletedOnBoarding = results[0] as bool;
    final userId = results[1] as String?;
    logger.i('스플래시 페이지 - 온보딩 완료 여부: $hasCompletedOnBoarding, 사용자 ID: $userId');

    if (!mounted) return;

    if (userId == null) {
      logger.i('스플래시 페이지 - 사용자 ID 없음, 로그인 페이지로 이동');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final userAsync = await ref.read(userProfileProvider(userId).future);
    logger.i('스플래시 페이지 - 사용자 프로필: $userAsync');
    if (!mounted) return;

    if (userAsync == null) {
      logger.i('스플래시 페이지 - 사용자 프로필 없음, 로그인 페이지로 이동');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      if (hasCompletedOnBoarding) {
        logger.i('스플래시 페이지 - 온보딩 완료, 메인 페이지로 이동');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        logger.i('스플래시 페이지 - 온보딩 미완료, 온보딩 페이지로 이동');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnBoardingPage()),
        );
      }
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
              Color(0xFF9BDBCA),
              Color(0xFF76D6A3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/SplashVector.svg',
                width: 100,
                height: 100,
                placeholderBuilder: (context) =>
                const CircularProgressIndicator(),
              ),
              const SizedBox(height: 32),
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