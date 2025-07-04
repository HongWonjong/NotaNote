import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nota_note/pages/splash_page/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nota_note/firebase_options.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';
import 'package:nota_note/services/local_storage_service.dart';
import 'package:nota_note/services/notification_service.dart';
import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // .env 로드
  try {
    await dotenv.load(fileName: ".env");
    logger.i('.env 로드 완료');
  } catch (e, stack) {
    logger.e('.env 로드 실패: $e', stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
  }

  runZonedGuarded(() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.e('Flutter 프레임워크 에러: ${details.exception}',
          stackTrace: details.stack);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Firebase 초기화
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      logger.i('Firebase 및 Crashlytics 초기화 완료');
    } catch (e, stack) {
      logger.e('Firebase 초기화 실패: $e', stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
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
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }

    // AdMob 초기화
    try {
      await MobileAds.instance.initialize();
      logger.i('AdMob 초기화 완료');
    } catch (e, stack) {
      logger.e('AdMob 초기화 실패: $e', stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }

    // 알림 서비스 초기화
    try {
      await NotificationService().initialize();
      logger.i('알림 서비스 초기화 완료');
    } catch (e, stack) {
      logger.e('알림 서비스 초기화 실패: $e', stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }

    // 로컬 DB 초기화
    try {
      await LocalStorageService().database;
      logger.i('로컬 DB 초기화 완료');
    } catch (e, stack) {
      logger.e('로컬 DB 초기화 실패: $e', stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }

    // SharedPreferences 초기화
    try {
      await SharedPreferences.getInstance();
      logger.i('SharedPreferences 초기화 완료');
    } catch (e, stack) {
      logger.e('SharedPreferences 초기화 실패: $e', stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }

    logger.i('앱 실행 시작');
    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    logger.e('글로벌 에러: $error', stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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