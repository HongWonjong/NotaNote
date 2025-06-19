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
import 'package:nota_note/services/local_storage_service.dart';
import 'package:logger/logger.dart';
import 'dart:async';

void main() async {
  // Logger 초기화
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // 글로벌 에러 핸들링 설정
  runZonedGuarded(() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.e('Flutter 프레임워크 에러: ${details.exception}', stackTrace: details.stack);
    };

    WidgetsFlutterBinding.ensureInitialized();
    logger.i('WidgetsFlutterBinding 초기화 완료');

    // Firebase 초기화
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('Firebase 초기화 완료');
    } catch (e, stack) {
      logger.e('Firebase 초기화 실패: $e', stackTrace: stack);
    }

    // .env 파일 로드
    try {
      await dotenv.load(fileName: ".env");
      logger.i('dotenv 로드 완료');
    } catch (e, stack) {
      logger.e('dotenv 로드 실패: $e', stackTrace: stack);
    }

    // Kakao SDK 초기화
    try {
      KakaoSdk.init(
        nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
        javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
      );
      logger.i('Kakao SDK 초기화 완료');
    } catch (e, stack) {
      logger.e('Kakao SDK 초기화 실패: $e', stackTrace: stack);
    }

    // 로컬 데이터베이스 초기화
    try {
      await LocalStorageService().database;
      logger.i('로컬 데이터베이스 초기화 완료');
    } catch (e, stack) {
      logger.e('로컬 데이터베이스 초기화 실패: $e', stackTrace: stack);
    }

    // ProviderScope로 앱 실행
    logger.i('앱 실행 시작');
    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    // 비동기 및 기타 예외 처리
    logger.e('글로벌 에러: $error', stackTrace: stack);
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = Logger();
    logger.i('MyApp 빌드 시작');

    ref.watch(currentUserInitProvider);
    logger.i('userId 초기화 완료');

    return MaterialApp(
      title: 'NotaNote',
      debugShowCheckedModeBanner: false,
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
      home: const SplashPage(),
    );
  }
}

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