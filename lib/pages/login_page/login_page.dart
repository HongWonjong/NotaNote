import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/main.dart';
import 'package:nota_note/viewmodels/auth/google_auth_viewmodel.dart';
import 'package:nota_note/viewmodels/auth/kakao_auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin(); // 자동 로그인 확인
  }

  // 자동 로그인 체크 함수
  Future<void> _checkAutoLogin() async {
    final kakaoViewModel = ref.read(kakaoAuthViewModelProvider);
    final googleViewModel = ref.read(googleAuthViewModelProvider);

    // 1. Firebase(Google) 로그인 여부 확인
    final firebaseUser = googleViewModel.currentUser;
    if (firebaseUser != null) {
      log('[자동로그인] Firebase 로그인 감지됨: ${firebaseUser.uid}');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyHomePage()),
        );
      }
      return;
    }

    // 2. Kakao 토큰 유무 확인 → 자동 로그인 시도
    final hasToken = await kakaoViewModel.hasKakaoToken();
    if (hasToken) {
      log('[자동로그인] Kakao 토큰 유효함, 사용자 정보 조회 시작');
      try {
        await kakaoViewModel.signInWithKakao();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyHomePage()),
          );
        }
      } catch (e) {
        log('[자동로그인] Kakao 자동 로그인 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kakaoViewModel = ref.read(kakaoAuthViewModelProvider); // 카카오 로그인용
    final googleViewModel = ref.read(googleAuthViewModelProvider); // 구글 로그인용

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
                // 구글 로그인 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      log('[로그인] 구글 로그인 버튼 클릭됨');
                      try {
                        final userCredential =
                            await googleViewModel.signInWithGoogle();

                        if (userCredential == null ||
                            userCredential.user == null) {
                          log('[로그인] 유저 정보 없음');
                          return;
                        }

                        log('[로그인] 로그인 성공: ${userCredential.user!.uid}');

                        if (!mounted) return;
                        log('[로그인] MyHomePage로 이동');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyHomePage(),
                          ),
                        );

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('로그인 성공')));
                      } catch (e, stackTrace) {
                        log('[로그인] 구글 로그인 실패: $e', stackTrace: stackTrace);
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('로그인 실패')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF3F3F3), //구글로그인 배경
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '구글로 로그인',
                      style: TextStyle(
                        color: Color(0xFF595959), // 구글로그인 텍스트
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 카카오 로그인 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        log('[로그인] 카카오 로그인 시도');
                        await kakaoViewModel.signInWithKakao();
                        if (!context.mounted) return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MyHomePage()),
                        );
                      } catch (e) {
                        log('[로그인] 카카오 로그인 실패: $e');
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('카카오 로그인 실패')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500), // 카카오 배경
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '카카오로 로그인',
                      style: TextStyle(
                        color: Color(0xFF000000), //카카오 로그인 텍스트
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
