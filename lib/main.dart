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
import 'services/local_storage_service.dart';
import 'pages/my_home_page/my_home_page.dart';

import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");
  print('dotenv 로드 완료');

  KakaoSdk.init(
    nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
    javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
  );

  await LocalStorageService().database;

  timeago.setLocaleMessages('ko', timeago.KoMessages());

  runApp(const ProviderScope(child: MyApp()));
}

final userIdProvider = FutureProvider<String?>((ref) async {
  return await getCurrentUserId();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUserId = ref.watch(userIdProvider);

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
      home: asyncUserId.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('에러: $e'))),
        data: (userId) {
          if (userId == null) {
            return const LoginPage();
          }

          final userAsync = ref.watch(userProfileProvider(userId));

          return userAsync.when(
            loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                Scaffold(body: Center(child: Text('유저 정보 에러: $e'))),
            data: (user) {
              if (user == null) return const LoginPage();
              return const OnBoardingPage();
              //return const MyHomePage(); 테스트용 홈페이지로 복귀하고 싶을 때 돌려놓으세요

            },
          );
        },
      ),
    );
  }
}