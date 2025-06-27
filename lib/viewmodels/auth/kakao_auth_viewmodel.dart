import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';
import 'package:nota_note/services/note_group_exemple_service.dart';

final kakaoAuthViewModelProvider =
    Provider<KakaoAuthViewModel>((ref) => KakaoAuthViewModel(ref));

class KakaoAuthViewModel {
  final Ref ref;
  KakaoAuthViewModel(this.ref);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NoteGroupExampleService _noteGroupExampleService =
      NoteGroupExampleService();

  Future<UserModel?> signInWithKakao() async {
    try {
      // // 1. 카카오톡 설치 여부 확인 후 로그인(현재 비활성화 지우지 마십쇼)
      // log('Kakao 로그인 시도');
      // final isInstalled = await isKakaoTalkInstalled();
      // log('카카오톡 설치여부: $isInstalled');

      // OAuthToken token;
      // if (isInstalled) {
      //   token = await UserApi.instance.loginWithKakaoTalk();
      //   log('loginWithKakaoTalk 완료: $token');
      // } else {
      //   token = await UserApi.instance.loginWithKakaoAccount();
      //   log('loginWithKakaoAccount 완료: $token');
      // }

      log('Kakao 계정 로그인 시도');
      // 현재 카카오톡 로그인 오류로 무조건 계정 로그인 방식만 사용(카카오 설치 여부 확인 안함.)
      final token = await UserApi.instance.loginWithKakaoAccount();
      log('loginWithKakaoAccount 완료: $token');

      // 토큰이 세팅되었는지 확인
      bool hasToken = await AuthApi.instance.hasToken();
      log('AuthApi.hasToken(): $hasToken');
      int retry = 0;
      while (!hasToken && retry < 5) {
        // iOS에서 복귀 직후 토큰이 아직 세팅 안 된 경우가 있다고함. 잠깐 대기 후 재시도
        await Future.delayed(const Duration(milliseconds: 200));
        hasToken = await AuthApi.instance.hasToken();
        log('재시도 $retry: hasToken: $hasToken');
        retry++;
      }
      if (!hasToken) throw Exception('카카오 토큰 획득 실패');

      // 토큰이 있다면 정상적으로 유저정보 요청
      final user = await UserApi.instance.me();
      final userId = user.id.toString();
      final email = user.kakaoAccount?.email ?? 'no_email@kakao.com';
      final displayName = user.kakaoAccount?.profile?.nickname ?? 'Unknown';
      final photoUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';
      final docRef = _firestore.collection('users').doc(userId);
      final userDoc = await docRef.get();

      if (!userDoc.exists) {
        final newUser = UserModel(
          userId: userId,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          hashTag: generateHashedTag(userId),
          loginProviders: 'kakao',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(newUser.toJson(), SetOptions(merge: true));
        await _noteGroupExampleService.createExampleNoteGroup(userId);
      }

      await saveLoginUserId(userId);
      await saveLoginProvider('kakao');
      ref.read(userIdProvider.notifier).state = userId;

      final freshDoc = await docRef.get();
      return UserModel.fromJson(freshDoc.data()!);
    } catch (e, st) {
      log('[카카오 로그인 실패] $e', stackTrace: st);
      return null;
    }
  }
}
