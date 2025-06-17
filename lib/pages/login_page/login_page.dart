// lib/pages/login_page/login_page.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/main.dart';
import 'package:nota_note/viewmodels/auth/apple_auth_viewmodel.dart';
import 'package:nota_note/viewmodels/auth/google_auth_viewmodel.dart';
import 'package:nota_note/viewmodels/auth/kakao_auth_viewmodel.dart';
import 'package:nota_note/pages/my_home_page/my_home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final kakaoViewModel = ref.read(kakaoAuthViewModelProvider);
    final googleViewModel = ref.read(googleAuthViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 80),

            // 상단 로고 아이콘
            Center(
              child: SvgPicture.asset(
                'assets/icons/NotaNote.svg',
                width: 186,
                height: 36,
              ),
            ),

            // 하단 로그인 버튼들
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  // Apple 로그인 버튼
                  _buildLoginButton(
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => MyHomePage()),
                      );
                    },
                  ),

                  // Google 로그인 버튼
                  _buildLoginButton(
                    color: Colors.white,
                    border: const BorderSide(color: Color(0xFFFFFFFF)),
                    textColor: Colors.grey[800]!,
                    iconPath: 'assets/icons/Google.svg',
                    text: '구글로 로그인',
                    onTap: () async {
                      log('[로그인] 구글 로그인 시도');
                      final user = await googleViewModel.signInWithGoogle();
                      if (user == null || !mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => MyHomePage()),
                      );
                    },
                  ),

                  // Kakao 로그인 버튼
                  _buildLoginButton(
                    color: const Color(0xFFFEE500),
                    textColor: Colors.grey[800]!,
                    iconPath: 'assets/icons/Kakao.svg',
                    text: '카카오로 로그인',
                    onTap: () async {
                      log('[로그인] 카카오 로그인 시도');
                      final user = await kakaoViewModel.signInWithKakao();
                      if (user == null || !mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => MyHomePage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required Color color,
    required String text,
    required String iconPath,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    BorderSide? border,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: border ?? BorderSide.none,
          ),
          padding: EdgeInsets.zero,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 중앙 텍스트
            Align(
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            // 좌측 아이콘
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
    );
  }
}
