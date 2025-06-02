import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/pages/test_page/test_page.dart';
import 'pages/memo_page/memo_page.dart';
import 'package:nota_note/services/initializer.dart'; // Initializer 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 초기화 로직 호출
  await Initializer.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        appBarTheme: AppBarTheme(backgroundColor: Colors.white),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MyHomePage(),
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
          ],
        ),
      ),
    );
  }
}