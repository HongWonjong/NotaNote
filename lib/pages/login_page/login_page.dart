import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/main.dart';
import 'package:nota_note/viewmodels/auth_viewmodel.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(authViewModelProvider);

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
                            await viewModel.signInWithGoogle();
                        final user = userCredential?.user;

                        if (user == null) {
                          log('[로그인] 유저 정보 없음');
                          return;
                        }

                        log('[로그인] 로그인 성공: ${user.uid}');

                        if (!mounted) return;
                        log('[로그인] MyHomePage로 이동');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MyHomePage()),
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

                // 카카오 로그인 버튼 (현재는 UI만)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ElevatedButton(
                    onPressed: () {
                      log('[로그인] 카카오 로그인 버튼 클릭됨 (기능 없음)');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBE200), // 카카오로그인 텍스트
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '카카오로 로그인',
                      style: TextStyle(
                        color: Color(0xFF000000), //카카오로그인 텍스트
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
