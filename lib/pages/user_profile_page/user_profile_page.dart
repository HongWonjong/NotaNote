import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_edit_page.dart';
import 'package:nota_note/viewmodels/user_profile_viewmodel.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('에러: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('로그인이 필요합니다'));

          return Column(
            children: [
              // 회색 배경의 프로필 박스
              Container(
                width: double.infinity,
                color: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey,
                          child: Text(
                            user.displayName.characters.first,
                            style: const TextStyle(
                                fontSize: 24, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user.displayName,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 16,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserProfileEditPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('수정',
                            style: TextStyle(color: Colors.black)),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 연결된 계정 목록
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(user.email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('계정 추가하기'),
                onTap: () {
                  // TODO: 계정 추가 로직
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () {
                  // TODO: 로그아웃 로직
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
