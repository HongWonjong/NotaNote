import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/user_profile_page/account_delete_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_edit_page.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/pages/user_profile_page/widgets/profile_image_widget.dart';
import 'package:nota_note/providers/user_profile_provider.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';

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
        title: Text('프로필',
            style:
                PretendardTextStyles.titleS.copyWith(color: Colors.grey[900])),
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
                          builder: (_) => UserProfileEditPage(user: user)),
                    );
                    if (changed == true) {
                      ref.invalidate(userProfileProvider(userId));
                    }
                  }
                },
              );
            },
            child: Text('수정',
                style: PretendardTextStyles.bodyM
                    .copyWith(color: Colors.grey[700])),
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
                Center(
                  child: ProfileImageWidget(
                    userId: user.userId,
                    currentPhotoUrl: user.photoUrl,
                    displayName: user.displayName,
                    isEditable: false,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('닉네임',
                          style: PretendardTextStyles.bodyMEmphasis
                              .copyWith(color: Colors.grey[800])),
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
                        child: Text(user.displayName,
                            style: PretendardTextStyles.bodyM
                                .copyWith(color: Colors.grey[900])),
                      ),
                      const SizedBox(height: 16),
                      Text('이메일',
                          style: PretendardTextStyles.bodyMEmphasis
                              .copyWith(color: Colors.grey[800])),
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
                        child: Text(user.email,
                            style: PretendardTextStyles.bodyM
                                .copyWith(color: Colors.grey[900])),
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
                      // 로그아웃
                      TextButton(
                        onPressed: () => _showLogoutDialog(context, ref),
                        child: Text('로그아웃',
                            style: PretendardTextStyles.bodyM
                                .copyWith(color: Colors.grey[900])),
                      ),
                      // 계정 탈퇴
                      TextButton(
                        onPressed: () =>
                            _showAccountDeleteDialog(context, ref, userId),
                        child: Text('계정 탈퇴하기',
                            style: PretendardTextStyles.bodyM
                                .copyWith(color: Colors.red)),
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 268,
          height: 164,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 텍스트(중앙정렬, 상단 마진 24)
              SizedBox(height: 46),
              Center(
                child: SizedBox(
                  width: 228,
                  height: 24,
                  child: Text(
                    '로그아웃 하시겠습니까?',
                    style: PretendardTextStyles.bodyM.copyWith(
                      color: Colors.grey[900],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 텍스트~버튼 영역 간격 24
              const SizedBox(height: 24),
              // 버튼 Row
              Center(
                child: SizedBox(
                  width: 236,
                  height: 50,
                  child: Row(
                    children: [
                      // 취소 버튼
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.grey[600],
                            textStyle: PretendardTextStyles.bodyM,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('취소', textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 로그아웃 버튼
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
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
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.primary300Main,
                            textStyle: PretendardTextStyles.bodyM.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              const Text('로그아웃', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 하단 마진 16
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountDeleteDialog(
      BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(24, 36, 24, 20), // 좌24, 위36, 우24, 아래20
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 텍스트 영역 (228x89)
              Center(
                child: SizedBox(
                  width: 228,
                  height: 89,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '정말 탈퇴하시겠습니까?',
                        style: PretendardTextStyles.bodyL.copyWith(
                          color: Colors.grey[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '메모와 공유된 내용은 모두 삭제되며 복구할 수 없습니다.',
                        style: PretendardTextStyles.bodyM.copyWith(
                          color: Colors.grey[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // 텍스트~버튼 간격 24
              const SizedBox(height: 24),
              // 버튼 영역 (236x50)
              Center(
                child: SizedBox(
                  width: 236,
                  height: 50,
                  child: Row(
                    children: [
                      // 취소 버튼
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.grey[600],
                            textStyle: PretendardTextStyles.bodyM,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('취소', textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 탈퇴 버튼
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final deleted = await deleteUserAndData(userId);
                            if (deleted && context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AccountDeletedPage()),
                                (route) => false,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.red,
                            textStyle: PretendardTextStyles.bodyM.copyWith(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              const Text('탈퇴하기', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> deleteUserAndData(String userId) async {
    try {
      // 1. 사용자 관련 데이터(메모, 그룹 등) 모두 삭제 (예시: notegroups, users)
      final firestore = FirebaseFirestore.instance;

      // 사용자 그룹 모두 삭제
      final groups = await firestore
          .collection('notegroups')
          .where('creatorId', isEqualTo: userId)
          .get();
      for (var group in groups.docs) {
        await firestore.collection('notegroups').doc(group.id).delete();
      }
      // 사용자 document 삭제
      await firestore.collection('users').doc(userId).delete();

      // 유저 녹음기록을 로컬 데이터베이스와 파이어베이스에서 전부 삭제
      final recordingViewModel = ProviderContainer().read(recordingViewModelProvider.notifier);
      await recordingViewModel.deleteAllRecordings();


      // 로그아웃/정보 초기화
      await signOut();
      return true;
    } catch (e) {
      // 삭제 실패시 에러 처리
      return false;
    }
  }
}
