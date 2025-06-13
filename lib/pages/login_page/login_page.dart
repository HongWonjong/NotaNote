import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/main.dart';
import 'package:nota_note/viewmodels/auth/apple_auth_viewmodel.dart';
import 'package:nota_note/viewmodels/auth/google_auth_viewmodel.dart';
import 'package:nota_note/viewmodels/auth/kakao_auth_viewmodel.dart';

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
            const Column(
              children: [
                Text(
                  'NotaNote',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('(로고)', style: TextStyle(fontSize: 16)),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () async {
                      log('[로그인] 구글 로그인 시도');

                      final user = await googleViewModel
                          .signInWithGoogle(); // UserModel 반환
                      if (user == null || !mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyHomePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F3F3),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '구글로 로그인',
                      style: TextStyle(
                        color: Color(0xFF595959),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () async {
                      log('[로그인] 카카오 로그인 시도');

                      final user = await kakaoViewModel
                          .signInWithKakao(); // UserModel 반환
                      if (user == null || !mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyHomePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '카카오로 로그인',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () async {
                      log('[로그인] Apple 로그인 시도');

                      final user = await ref
                          .read(appleAuthViewModelProvider)
                          .signInWithApple(); // UserModel 반환

                      if (user == null || !context.mounted) {
                        log('[로그인] Apple 로그인 실패 또는 context 미탑재');
                        return;
                      }

                      log('[로그인] Apple 로그인 성공 → 홈 이동');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyHomePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000), // Apple 공식 색상
                      minimumSize: const Size.fromHeight(48), // 버튼 높이
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32), // 좌우 여백
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apple로 로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
