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
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';

void main() async {
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

  logger.i('main() 함수 시작');

  // Flutter 프레임워크 에러 핸들링
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Flutter 프레임워크 에러: ${details.exception}', stackTrace: details.stack);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  logger.i('dotenv 로드 완료');

  // 글로벌 에러 핸들링 설정
  runZonedGuarded(() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      logger.i('Firebase 및 Crashlytics 초기화 완료');

      KakaoSdk.init(
        nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
        javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
      );
      logger.i('Kakao SDK 초기화 완료');

      await LocalStorageService().database;
      logger.i('로컬 데이터베이스 초기화 완료');

      await SharedPreferences.getInstance();
      logger.i('SharedPreferences 초기화 완료');

      runApp(const ProviderScope(child: MyApp()));
      logger.i('앱 실행 시작');
    } catch (e, stack) {
      logger.e('초기화 중 에러: $e', stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
      await Sentry.captureException(e, stackTrace: stack);
    }
  }, (error, stack) async {
    logger.e('글로벌 에러: $error', stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    await Sentry.captureException(error, stackTrace: stack);
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
