import 'package:flutter/material.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_page.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.bold, // 일단 볼드체로 추후 조정
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(
          //앱바 뒤로가기 버튼
          size: 24,
          color: Color(0xFFB5B5B5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ListTile(
            title: const Text(
              '내 프로필',
              style: TextStyle(
                color: Color(0xFF545454),
              ),
            ),
            onTap: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    //프로필 페이지로이동
                    builder: (_) => UserProfilePage(userId: userId),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: const Text(
              '알림',
              style: TextStyle(color: Color(0xFF545454)),
            ),
            onTap: () {
              // 알림 설정 페이지 이동
            },
          ),
          ListTile(
            title: const Text(
              '테마 설정',
              style: TextStyle(color: Color(0xFF545454)),
            ),
            onTap: () {
              // 다크모드 등 테마 설정 페이지 이동
            },
          ),
          ListTile(
            title: const Text(
              '암호',
              style: TextStyle(color: Color(0xFF545454)),
            ),
            onTap: () {
              //
            },
          ),
          ListTile(
            title: const Text(
              '고객지원',
              style: TextStyle(color: Color(0xFF545454)),
            ),
            onTap: () {
              // 고객지원 페이지 이동
            },
          ),
          const SizedBox(height: 30),
          ListTile(
            title: const Text(
              '탈퇴하기',
              style: TextStyle(color: Color(0xFFFF2F2F)),
            ),
            onTap: () {
              // 탈퇴 기능
            },
          ),
        ],
      ),
    );
  }
}
