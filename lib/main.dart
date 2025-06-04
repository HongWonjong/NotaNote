import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/memo_group_page/memo_group_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_edit_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_page.dart';
import 'package:nota_note/pages/main_page/main_page.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';
import 'package:nota_note/services/initializer.dart';
import 'package:nota_note/viewmodels/user_profile_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 초기화
  await Initializer.initialize();

  KakaoSdk.init(
    nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
    javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 로그인한 사용자의 UID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // 유저 ID가 없으면 로그인 페이지
    if (currentUserId == null) {
      return const MaterialApp(home: LoginPage());
    }

    // 유저 ID가 있으면 Firestore에서 UserModel 불러오기
    final userAsync = ref.watch(userProfileViewModelProvider(currentUserId));

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: userAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('에러: $e'))),
        data: (user) {
          // 로그인은 되어있지만 유저 정보가 없으면 로그인 페이지로
          if (user == null) return const LoginPage();
          // 유저 정보가 있으면 홈 화면으로 진입
          return MyHomePage(user: user);
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final UserModel user;

  const MyHomePage({super.key, required this.user});

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
                  MaterialPageRoute(
                      builder: (context) => const MemoGroupPage()),
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
                      groupId: 'group1', // 테스트용
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage(user: user)),
                );
              },
              child: const Text('메인 페이지로 이동'),
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
