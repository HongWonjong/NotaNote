import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:nota_note/models/user_model.dart';

final kakaoAuthViewModelProvider = Provider((ref) => KakaoAuthViewmodel());

class KakaoAuthViewmodel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithKakao() async {
    try {
      // 1. 카카오톡 앱 or 계정으로 로그인
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken token = isInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      // 2. 사용자 정보 조회
      final user = await UserApi.instance.me();
      final kakaoAccount = user.kakaoAccount;
      final userId = user.id.toString();

      print('카카오 로그인 성공: ${kakaoAccount?.email}');

      // 3. UID 기반 해시태그 생성
      String generateHashedTag(String uid) {
        final bytes = utf8.encode(uid);
        final digest = sha256.convert(bytes);
        return '#${digest.toString().substring(0, 6)}';
      }

      final userModel = UserModel(
        userId: userId,
        displayName: kakaoAccount?.profile?.nickname ?? 'NoName',
        email: kakaoAccount?.email ?? 'unknown@email.com',
        photoUrl: kakaoAccount?.profile?.profileImageUrl ?? '',
        hashTag: generateHashedTag(userId),
        loginProviders: 'kakao',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 4. Firestore에 저장
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userModel.toJson(), SetOptions(merge: true));

      await _firestore.collection('users').doc(userId).update({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('카카오 로그인 실패: $e');
      rethrow;
    }
  }
}
