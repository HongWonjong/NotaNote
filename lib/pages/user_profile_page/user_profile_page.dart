import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:nota_note/pages/login_page/login_page.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/pages/user_profile_page/account_delete_page.dart';
import 'package:nota_note/pages/user_profile_page/user_profile_edit_page.dart';
import 'package:nota_note/pages/user_profile_page/widgets/profile_action_buttons.dart';
import 'package:nota_note/services/oauth_revoke_service.dart';
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
        leading: Padding(padding: EdgeInsets.only(left: 20),
        child: const BackButton(color: Colors.grey),
        ),
        title: Text('프로필',
            style:
                PretendardTextStyles.titleS.copyWith(color: Colors.grey[900])),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[700]),
        actions: [
          // 프로필 수정 버튼
          Padding(padding: EdgeInsets.only(right: 20),
            child: TextButton(
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
            ),
          ),
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
                const SizedBox(height: 30),
                // 프로필 이미지 (가로 무제한, 세로 91, 중앙정렬)
                SizedBox(
                  width: double.infinity,
                  height: 91,
                  child: Center(
                    child: ProfileImageWidget(
                      userId: user.userId,
                      currentPhotoUrl: user.photoUrl,
                      displayName: user.displayName,
                      isEditable: false,
                    ),
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
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          height: 52,
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
                      ),
                      const SizedBox(height: 16),
                      Text('이메일',
                          style: PretendardTextStyles.bodyMEmphasis
                              .copyWith(color: Colors.grey[800])),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          height: 52,
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Divider(color: Colors.grey[200], thickness: 6),
                const SizedBox(height: 10),

                // 로그아웃/탈퇴 버튼은 별도 위젯으로 분리
                ProfileActionButtons(
                  onLogout: () => _showLogoutDialog(context),
                  onDeleteAccount: () =>
                      _showAccountDeleteDialog(context, userId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 로그아웃 다이얼로그
  void _showLogoutDialog(BuildContext context) {
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 탈퇴 다이얼로그
  void _showAccountDeleteDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 24),
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
                            final deleted =
                                await deleteUserAndAllData(userId, context);
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

  /// Firestore 데이터, Firebase Auth/Kakao/Apple/Google 계정까지 완전 삭제 (SNS별 분기, 최근 인증 필요시 안내)
  Future<bool> deleteUserAndAllData(String userId, BuildContext context) async {
    try {
      // 1. Firestore 내 유저 관련 데이터 모두 삭제 (노트 그룹, 유저 문서 등)
      final firestore = FirebaseFirestore.instance;
      final groups = await firestore
          .collection('notegroups')
          .where('creatorId', isEqualTo: userId)
          .get();
      for (var group in groups.docs) {
        await firestore.collection('notegroups').doc(group.id).delete();
      }
      await firestore.collection('users').doc(userId).delete();

      // 유저 녹음기록을 로컬 데이터베이스와 파이어베이스에서 전부 삭제
      final recordingViewModel =
          ProviderContainer().read(recordingViewModelProvider.notifier);
      await recordingViewModel.deleteAllRecordings();

      // 로그아웃/정보 초기화
      // 2. 로그인 provider 정보 (google, apple, kakao) 읽기
      final provider = await getLoginProvider();

      // 3. SNS별 회원탈퇴/연동해제 로직
      if (provider == 'google') {
        final googleAccessToken = await getGoogleAccessToken();
        if (googleAccessToken != null) {
          await revokeGoogleToken(googleAccessToken);
        }
        final auth = FirebaseAuth.instance;
        final user = auth.currentUser;
        if (user != null) {
          try {
            await user.delete();
          } on FirebaseAuthException catch (e) {
            if (e.code == 'requires-recent-login') {
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('재인증 필요'),
                    content: const Text('계정 탈퇴를 위해 로그인 후 다시 시도해주세요.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              }
              await signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
              return false;
            }
          }
        }
      } else if (provider == 'apple') {
        //탈퇴 로직
        // final appleRefreshToken = await getAppleRefreshToken();
        // if (appleRefreshToken != null) {
        //   await revokeAppleToken(appleRefreshToken);
        // }
        final auth = FirebaseAuth.instance;
        final user = auth.currentUser;
        if (user != null) {
          try {
            await user.delete();
          } on FirebaseAuthException catch (e) {
            if (e.code == 'requires-recent-login') {
              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('재인증 필요'),
                    content: const Text('계정 탈퇴를 위해 로그인 후 다시 시도해주세요.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              }
              await signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
              return false;
            }
          }
        }
      } else if (provider == 'kakao') {
        try {
          print('카카오 연결 해제시도');
          await UserApi.instance.unlink();
          print('카카오 연결 해제');
        } catch (e) {
          // 이미 해제되어도 무시
          print('카카오 연결 실패');
        }
      }

      // 4. SharedPreferences/Provider/세션 등 모든 로그인 정보 초기화
      await signOut();

      return true;
    } catch (e) {
      // 삭제 실패시 에러 처리 (필요하면 로그 등 추가)
      return false;
    }
  }
}
