// kakao_auth_viewmodel.dart
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

final kakaoAuthViewModelProvider =
    Provider<KakaoAuthViewModel>((ref) => KakaoAuthViewModel());

class KakaoAuthViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signInWithKakao() async {
    try {
      final isInstalled = await isKakaoTalkInstalled();
      final token = isInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      final user = await UserApi.instance.me();
      final kakaoAccount = user.kakaoAccount;
      final userId = user.id.toString();

      final email = kakaoAccount?.email ?? 'no_email@kakao.com';
      final displayName = kakaoAccount?.profile?.nickname ?? 'Unknown';
      final photoUrl = kakaoAccount?.profile?.profileImageUrl ?? '';

      final docRef = _firestore.collection('users').doc(userId);
      final userDoc = await docRef.get();

      if (!userDoc.exists) {
        final userModel = UserModel(
          userId: userId,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          hashTag: generateHashedTag(userId),
          loginProviders: 'kakao',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(userModel.toJson(), SetOptions(merge: true));
      }

      await saveLoginUserId(userId);
      await saveLoginProvider('kakao');

      final freshDoc = await docRef.get();
      return UserModel.fromJson(freshDoc.data()!);
    } catch (e, st) {
      log('[카카오 로그인 실패] $e', stackTrace: st);
      return null;
    }
  }
}
