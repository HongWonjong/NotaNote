// lib/pages/user_profile_page/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_edit_page.dart';
import 'package:nota_note/pages/user_profile_page/widgets/profile_image_widget';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/viewmodels/user_profile_viewmodel.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.grey),
        title: const Text(
          '내 프로필',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('사용자 정보를 찾을 수 없습니다.'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 프로필 정보
              Container(
                color: const Color(0xFFF4F4F4),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        // 프로필 이미지 (터치하여 수정 가능)
                        ProfileImageWidget(
                          userId: user.userId,
                          currentPhotoUrl: user.photoUrl,
                          displayName: user.displayName,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFA2A2A2),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 28,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFA7A7A7),
                          backgroundColor: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileEditPage(user: user),
                            ),
                          );
                        },
                        child: const Text(
                          '수정',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 계정 전환 + 로그아웃 포함한 본문 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '계정 전환',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(
                          Icons.account_circle,
                          size: 28,
                          color: Color(0xFFF2F2F2),
                        ),
                        title: Text(
                          user.email,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onTap: () {},
                        contentPadding: EdgeInsets.zero,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -2),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.add,
                          size: 28,
                          color: Color(0xFFF2F2F2),
                        ),
                        title: const Text(
                          '계정 추가하기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {},
                        contentPadding: EdgeInsets.zero,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -2),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: TextButton(
                          onPressed: () async {
                            await signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            '로그아웃',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
