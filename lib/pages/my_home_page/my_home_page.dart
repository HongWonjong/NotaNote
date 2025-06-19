import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/memo_group_page/memo_group_page.dart';
import 'package:nota_note/pages/main_page/main_page.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/viewmodels/user_profile_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nota_note/firebase_options.dart';
import 'package:nota_note/pages/on_boarding_page/on_boarding_page.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nota_note/services/local_storage_service.dart';


class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = Logger();
    logger.i('MyHomePage 빌드 시작');

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('NotaNote 예시 페이지'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                logger.i('메인 페이지로 이동 버튼 클릭');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainPage()),
                );
              },
              child: const Text('메인 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () {
                logger.i('메모 그룹 페이지로 이동 버튼 클릭');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MemoGroupPage(
                        groupId: 'group1',
                        groupName: '그룹1',
                      )),
                );
              },
              child: const Text('메모 그룹 페이지로 이동 (테스트)'),
            ),
            ElevatedButton(
              onPressed: () {
                logger.i('메모 페이지로 이동 버튼 클릭');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemoPage(
                      groupId: 'group1',
                      noteId: 'note1',
                      pageId: 'page1',
                    ),
                  ),
                );
              },
              child: const Text('메모 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () {
                logger.i('온보딩 페이지로 이동 버튼 클릭');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OnBoardingPage()),
                );
              },
              child: const Text('온보딩 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () async {
                logger.i('로그아웃 버튼 클릭');
                try {
                  await FirebaseAuth.instance.signOut();
                  logger.i('Firebase 로그아웃 완료');
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                  logger.i('로그인 페이지로 이동');
                } catch (e, stack) {
                  logger.e('로그아웃 실패: $e', stackTrace: stack);
                  FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
                }
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}