import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/firebase_options.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/test_page/test_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  print('dotenv 로드 완료');

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  KakaoSdk.init(
    nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
    javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:
          FirebaseAuth.instance.currentUser != null
              ? const MyHomePage()
              : const LoginPage(),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestPage()),
                );
              },
              child: const Text('테스트 페이지로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
