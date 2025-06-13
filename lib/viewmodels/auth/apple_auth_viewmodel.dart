import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

final appleAuthViewModelProvider = Provider<AppleAuthViewModel>(
  (ref) => AppleAuthViewModel(),
);

class AppleAuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signInWithApple() async {
    try {
      print('[AppleLogin] nonce 생성 중...');
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);
      print('[AppleLogin] rawNonce: $rawNonce');
      print('[AppleLogin] hashedNonce: $hashedNonce');

      FirebaseCrashlytics.instance.log('[AppleLogin] Apple 로그인 요청 시작');

      // 환경 변수 확인
      final clientId = dotenv.env['APPLE_CLIENT_ID'];
      final redirectUri = dotenv.env['APPLE_REDIRECT_URI'];
      if (clientId == null || redirectUri == null) {
        print('[AppleLogin] 경고: .env 환경 변수 누락됨');
        FirebaseCrashlytics.instance.log('[AppleLogin] .env 설정 누락');
        return null;
      }

      print('[AppleLogin] Apple 로그인 요청...');
      print('[AppleLogin] .env clientId: $clientId');
      print('[AppleLogin] .env redirectUri: $redirectUri');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: clientId,
          redirectUri: Uri.parse(redirectUri),
        ),
      );

      FirebaseCrashlytics.instance.log('[AppleLogin] Apple credential 수신 완료');

      print('[AppleLogin] identityToken: ${credential.identityToken}');
      print('[AppleLogin] authorizationCode: ${credential.authorizationCode}');
      print('[AppleLogin] userIdentifier: ${credential.userIdentifier}');
      print('[AppleLogin] email: ${credential.email}');
      print('[AppleLogin] givenName: ${credential.givenName}');
      print('[AppleLogin] familyName: ${credential.familyName}');

      // credential 확인용 로그
      print('[AppleLogin] 인증 토큰 길이: ${credential.identityToken?.length}');
      print('[AppleLogin] 인증 코드 길이: ${credential.authorizationCode?.length}');

      if (credential.identityToken == null) {
        final msg = '[AppleLogin] 오류: identityToken이 null입니다.';
        print(msg);
        FirebaseCrashlytics.instance.log(msg);
        return null;
      }

      print('[AppleLogin] Firebase OAuthCredential 생성...');
      FirebaseCrashlytics.instance
          .log('[AppleLogin] Firebase OAuthCredential 생성 시도');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        rawNonce: rawNonce,
      );

      print('[AppleLogin] FirebaseAuth 인증 시도...');
      FirebaseCrashlytics.instance.log('[AppleLogin] FirebaseAuth 인증 시도');

      // Firebase 인증은 별도 try-catch로 구분
      final UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(oauthCredential);
      } catch (e, stack) {
        print('[AppleLogin] Firebase 인증 예외 발생: $e');
        await FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: '[AppleLogin] FirebaseAuth.signInWithCredential 실패',
        );
        return null;
      }

      final user = userCredential.user;
      if (user == null) {
        final msg = '[AppleLogin] Firebase 인증 실패: user == null';
        print(msg);
        FirebaseCrashlytics.instance.log(msg);
        return null;
      }

      print(
          '[AppleLogin] Firebase 로그인 성공: uid=${user.uid}, email=${user.email}');
      FirebaseCrashlytics.instance.log('[AppleLogin] Firebase 로그인 성공');

      final userId = user.uid;
      final email = user.email ?? credential.email ?? 'no_email@apple.com';
      final displayName =
          credential.givenName ?? user.displayName ?? 'AppleUser';
      final photoUrl = '';

      final docRef = _firestore.collection('users').doc(userId);
      final userDoc = await docRef.get();

      if (!userDoc.exists) {
        print('[AppleLogin] Firestore 신규 유저 저장...');
        FirebaseCrashlytics.instance.log('[AppleLogin] Firestore 신규 유저 저장');

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
        FirebaseCrashlytics.instance.log('[AppleLogin] 기존 유저 문서 존재함');
      }

      await saveLoginUserId(userId);
      await saveLoginProvider('apple');

      final freshDoc = await docRef.get();
      FirebaseCrashlytics.instance.log('[AppleLogin] 로그인 최종 성공 → UserModel 반환');

      return UserModel.fromJson(freshDoc.data()!);
    } catch (e, stack) {
      print('[AppleLogin] 오류 발생: $e');
      print('[AppleLogin] 스택트레이스:\n$stack');

      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: '[AppleLogin] 애플 로그인 중 예외 발생',
        fatal: false,
      );

      return null;
    }
  }

  String _generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
