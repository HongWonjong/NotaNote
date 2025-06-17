import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/memo_group_page/memo_group_page.dart';
import 'package:nota_note/pages/main_page/main_page.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nota_note/pages/splash_page/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nota_note/firebase_options.dart';
import 'package:nota_note/pages/on_boarding_page/on_boarding_page.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';
import 'services/local_storage_service.dart';

import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  print('dotenv 로드 완료');

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
    javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
  );

  // 로컬 데이터베이스 초기화
  await LocalStorageService().database;

  // timeago 한글 메시지 등록
  timeago.setLocaleMessages('ko', timeago.KoMessages());

  // ProviderScope로 앱 실행
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 앱 실행 시 userId 초기화 (getCurrentUserId() → userIdProvider로 주입)
    ref.watch(currentUserInitProvider);

    return MaterialApp(
      title: 'NotaNote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        scaffoldBackgroundColor: Colors.white,
      ),
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ko', 'KR'),
      ],
      // 최초 진입 SplashPage로 설정
      home: const SplashPage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('NotaNote 예시 페이지'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // MainPage로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainPage()),
                );
              },
              child: const Text('메인 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () {
                // 테스트 데이터로 MemoGroupPage 직접 이동 (이전 코드 용도)
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
                // MemoPage로 직접 이동
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
                // 온보딩 페이지로 이동
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
                // Firebase 로그아웃 + 로그인 페이지로 이동
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
