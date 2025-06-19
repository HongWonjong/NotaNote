import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_edit_page.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/pages/user_profile_page/widgets/profile_image_widget.dart';
import 'package:nota_note/providers/user_profile_provider.dart';

/// 사용자 프로필 페이지
class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.grey),
        title: Text(
          '프로필',
          style: PretendardTextStyles.titleS.copyWith(
            color: Colors.grey[900],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[700]),
        actions: [
          TextButton(
            onPressed: () async {
              userAsync.whenOrNull(
                data: (user) async {
                  if (user != null) {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileEditPage(user: user),
                      ),
                    );

                    // 변경이 감지되었을 때만 invalidate 수행
                    if (changed == true) {
                      ref.invalidate(userProfileProvider(userId));
                    }
                  }
                },
              );
            },
            child: Text(
              '수정',
              style: PretendardTextStyles.bodyM.copyWith(
                color: Colors.grey[700],
              ),
            ),
          )
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('사용자 정보를 찾을 수 없습니다.'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // 프로필 이미지 (읽기 전용)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ProfileImageWidget(
                        userId: user.userId,
                        currentPhotoUrl: user.photoUrl,
                        displayName: user.displayName,
                        isEditable: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 닉네임, 이메일 정보
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '닉네임',
                        style: PretendardTextStyles.bodyMEmphasis.copyWith(
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        //52,332
                        height: 52,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.displayName,
                          style: PretendardTextStyles.bodyM.copyWith(
                            color: Colors.grey[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이메일',
                        style: PretendardTextStyles.bodyMEmphasis.copyWith(
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 52,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.email,
                          style: PretendardTextStyles.bodyM.copyWith(
                            color: Colors.grey[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Divider(color: Colors.grey[200], thickness: 6),
                const SizedBox(height: 10),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
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
                        child: Text(
                          '로그아웃',
                          style: PretendardTextStyles.bodyM.copyWith(
                            color: Colors.grey[900],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '계정 탈퇴하기',
                          style: PretendardTextStyles.bodyM.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
