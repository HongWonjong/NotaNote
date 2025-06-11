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
import 'package:flutter_quill/flutter_quill.dart'; // FlutterQuillLocalizations 임포트
import 'package:flutter_localizations/flutter_localizations.dart'; // 기본 로컬라이제이션
import 'services/local_storage_service.dart';

import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // dotenv 초기화 (한 번만)
  await dotenv.load(fileName: ".env");
  print('dotenv 로드 완료');

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
    javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
  );

  // LocalStorageService 초기화 (캐시 미리 로드) - 한 번만 호출
  await LocalStorageService().database;

  // timeago 한국어 메시지 설정
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
    // SharedPreferences에서 로그인된 사용자 ID 조회
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
        Locale('en', 'US'), // 영어
        Locale('ko', 'KR'), // 한국어
      ],
      home: asyncUserId.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('에러: $e'))),
        data: (userId) {
          if (userId == null) {
            // 로그인된 사용자 없음 → 로그인 페이지로 이동
            return const LoginPage();
          }

          // 로그인된 사용자 있음 → 실시간 유저 정보 StreamProvider 구독
          final userAsync = ref.watch(userProfileProvider(userId));

          return userAsync.when(
            loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                Scaffold(body: Center(child: Text('유저 정보 에러: $e'))),
            data: (user) {
              if (user == null) return const LoginPage();
              return const MyHomePage();
            },
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
  });

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MemoGroupPage(groupId: 'group1', groupName: '그룹1',)),
                );
              },
              child: const Text('메모 그룹 페이지로 이동'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemoPage(
                      groupId: 'group1', // 테스트용 값
                      noteId: 'note1',   // 테스트용 값
                      pageId: 'page1',   // 테스트용 값
                    ),
                  ),
                );
              },
              child: const Text('메모 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
              child: const Text('메인 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OnBoardingPage()),
                );
              },
              child: const Text('온보딩 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () async {
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
