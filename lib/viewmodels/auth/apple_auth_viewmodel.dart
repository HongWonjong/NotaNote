import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

// Apple 로그인 ViewModel을 Provider로 등록
final appleAuthViewModelProvider = Provider<AppleAuthViewModel>(
  (ref) => AppleAuthViewModel(),
);

class AppleAuthViewModel {
  // Firebase 인증 및 Firestore 인스턴스 초기화
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Apple 로그인 메서드
  Future<UserModel?> signInWithApple() async {
    try {
      // 로그인 요청 시 nonce 생성 (재사용 공격 방지)
      print('[AppleLogin] nonce 생성 중...');
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);
      print('[AppleLogin] rawNonce: $rawNonce');
      print('[AppleLogin] hashedNonce: $hashedNonce');

      // .env 파일에서 clientId, redirectUri 가져오기
      final clientId = dotenv.env['APPLE_CLIENT_ID'];
      final redirectUri = dotenv.env['APPLE_REDIRECT_URI'];
      if (clientId == null || redirectUri == null) {
        print('[AppleLogin] 경고: .env 환경 변수 누락됨');
        return null;
      }

      print('[AppleLogin] Apple 로그인 요청...');
      print('[AppleLogin] .env clientId: $clientId');
      print('[AppleLogin] .env redirectUri: $redirectUri');

      // Apple 인증 요청
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // nonce: hashedNonce,
      );

      // Apple에서 받은 정보 출력
      print('[AppleLogin] identityToken: ${credential.identityToken}');
      print('[AppleLogin] authorizationCode: ${credential.authorizationCode}');
      print('[AppleLogin] userIdentifier: ${credential.userIdentifier}');
      print('[AppleLogin] email: ${credential.email}');
      print('[AppleLogin] givenName: ${credential.givenName}');
      print('[AppleLogin] familyName: ${credential.familyName}');

      // 토큰 길이 확인 (디버깅용)
      print('[AppleLogin] 인증 토큰 길이: ${credential.identityToken?.length}');
      print('[AppleLogin] 인증 코드 길이: ${credential.authorizationCode?.length}');

      // identityToken이 없으면 중단
      if (credential.identityToken == null) {
        final msg = '[AppleLogin] 오류: identityToken이 null입니다.';
        print(msg);
        return null;
      }

      // Apple로 받은 토큰을 이용해 Firebase OAuth 자격 증명 생성
      print('[AppleLogin] Firebase OAuthCredential 생성...');
      final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode
          // rawNonce: rawNonce,
          );

      // Firebase 인증 시도
      print('[AppleLogin] FirebaseAuth 인증 시도...');
      final UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(oauthCredential);
      } catch (e, stack) {
        print('[AppleLogin] Firebase 인증 예외 발생: $e');
        return null;
      }

      // 인증된 사용자 정보 가져오기
      final user = userCredential.user;
      if (user == null) {
        final msg = '[AppleLogin] Firebase 인증 실패: user == null';
        print(msg);
        return null;
      }

      // Firebase 인증 성공 로그
      print(
          '[AppleLogin] Firebase 로그인 성공: uid=${user.uid}, email=${user.email}');

      // 사용자 정보 정리
      final userId = user.uid;
      final email = user.email ?? credential.email ?? 'no_email@apple.com';
      final displayName =
          credential.givenName ?? user.displayName ?? 'AppleUser';
      final photoUrl = '';

      // Firestore에서 유저 문서 확인
      final docRef = _firestore.collection('users').doc(userId);
      final userDoc = await docRef.get();

      // 문서가 없으면 신규 사용자로 등록
      if (!userDoc.exists) {
        print('[AppleLogin] Firestore 신규 유저 저장...');
        final userModel = UserModel(
          userId: userId,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          hashTag: generateHashedTag(userId),
          loginProviders: 'apple',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(userModel.toJson());
      } else {
        print('[AppleLogin] 기존 유저 문서 존재함');
      }

      // SharedPreferences에 로그인 정보 저장
      await saveLoginUserId(userId);
      await saveLoginProvider('apple');

      // 최신 사용자 정보 가져오기
      final freshDoc = await docRef.get();
      print('[AppleLogin] 로그인 최종 성공 → UserModel 반환');

      // 최종적으로 UserModel 반환
      return UserModel.fromJson(freshDoc.data()!);
    } catch (e, stack) {
      // 전체 예외 캐치
      print('[AppleLogin] 오류 발생: $e');
      print('[AppleLogin] 스택트레이스:\n$stack');
      return null;
    }
  }

  // nonce 생성기 (랜덤 문자열)
  String _generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // SHA256 해싱 함수
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
