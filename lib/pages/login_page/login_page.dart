import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/viewmodels/auth/apple_auth_viewmodel.dart';
import 'package:nota_note/viewmodels/auth/google_auth_viewmodel.dart';
import 'package:nota_note/viewmodels/auth/kakao_auth_viewmodel.dart';
import 'package:nota_note/pages/on_boarding_page/on_boarding_page.dart';
import 'package:nota_note/providers/onboarding_provider.dart';
import 'package:logger/logger.dart';
import 'package:nota_note/pages/main_page/main_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final logger = Logger();

  Future<void> _navigateAfterLogin() async {
    final hasCompletedOnBoarding =
        await ref.read(onBoardingStatusFutureProvider.future);
    logger.i('로그인 페이지 - 온보딩 완료 여부: $hasCompletedOnBoarding');
    if (!mounted) return;

    if (hasCompletedOnBoarding) {
      logger.i('로그인 페이지 - 온보딩 완료, 메인 페이지로 이동');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      logger.i('로그인 페이지 - 온보딩 미완료, 온보딩 페이지로 이동');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnBoardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kakaoViewModel = ref.read(kakaoAuthViewModelProvider);
    final googleViewModel = ref.read(googleAuthViewModelProvider);

    const double bottomSpace = 50.0;
    const double buttonWidth = 335;
    const double buttonHeight = 48;
    const double buttonMargin = 14;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 앱바와 로고 사이 Spacer
            const Spacer(),
            // 로고
            Center(
              child: SvgPicture.asset(
                'assets/icons/NotaNote.svg',
                width: 186,
                height: 36,
              ),
            ),
            // 로고와 Apple 버튼 사이 Spacer (앱바~로고와 동일한 비율)
            const Spacer(),
            // 버튼들
            _buildLoginButton(
              width: buttonWidth,
              height: buttonHeight,
              textWidth: 89,
              textHeight: 21,
              color: Colors.black,
              textColor: Colors.white,
              iconPath: 'assets/icons/Apple.svg',
              text: 'Apple로 로그인',
              onTap: () async {
                log('[로그인] Apple 로그인 시도');
                final user = await ref
                    .read(appleAuthViewModelProvider)
                    .signInWithApple();
                if (user == null || !context.mounted) {
                  log('[로그인] Apple 로그인 실패');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apple 로그인에 실패했습니다')),
                  );
                  return;
                }
                await _navigateAfterLogin();
              },
            ),
            const SizedBox(height: buttonMargin),
            _buildLoginButton(
              width: buttonWidth,
              height: buttonHeight,
              textWidth: 77,
              textHeight: 21,
              color: Colors.white,
              border: BorderSide(color: AppColors.gray200),
              textColor: AppColors.gray800,
              iconPath: 'assets/icons/Google.svg',
              text: '구글로 로그인',
              onTap: () async {
                log('[로그인] 구글 로그인 시도');
                final user = await googleViewModel.signInWithGoogle();
                if (user == null || !mounted) return;
                await _navigateAfterLogin();
              },
            ),
            const SizedBox(height: buttonMargin),
            _buildLoginButton(
              width: buttonWidth,
              height: buttonHeight,
              textWidth: 89,
              textHeight: 21,
              color: const Color(0xFFFEE500),
              textColor: Colors.grey[800]!,
              iconPath: 'assets/icons/Kakao.svg',
              text: '카카오로 로그인',
              onTap: () async {
                log('[로그인] 카카오 로그인 시도');
                final user = await kakaoViewModel.signInWithKakao();
                if (user == null || !mounted) return;
                await _navigateAfterLogin();
              },
            ),
            // 카카오~하단만 고정
            const SizedBox(height: bottomSpace),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required double width,
    required double height,
    required double textWidth,
    required double textHeight,
    required Color color,
    required String text,
    required String iconPath,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    BorderSide? border,
  }) {
    return Padding(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: Size(width, height),
            maximumSize: Size(width, height),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: border ?? BorderSide.none,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: textWidth,
                  height: textHeight,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      style:
                          PretendardTextStyles.bodyS.copyWith(color: textColor),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                child: SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
