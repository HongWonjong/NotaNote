// lib/viewmodels/auth/apple_auth_viewmodel.dart
import 'dart:convert';
import 'dart:developer';
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

      print('[AppleLogin] Apple 로그인 요청...');

      print('[AppleLogin] .env clientId: ${dotenv.env['APPLE_CLIENT_ID']}');
      print(
          '[AppleLogin] .env redirectUri: ${dotenv.env['APPLE_REDIRECT_URI']}');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: dotenv.env['APPLE_CLIENT_ID']!,
          redirectUri: Uri.parse(dotenv.env['APPLE_REDIRECT_URI']!),
        ),
      );

      print('[AppleLogin] Apple credential 받음');
      print('[AppleLogin] identityToken: ${credential.identityToken}');
      print('[AppleLogin] authorizationCode: ${credential.authorizationCode}');
      print('[AppleLogin] userIdentifier: ${credential.userIdentifier}');
      print('[AppleLogin] email: ${credential.email}');
      print('[AppleLogin] givenName: ${credential.givenName}');
      print('[AppleLogin] familyName: ${credential.familyName}');

      if (credential.identityToken == null) {
        print('[AppleLogin] 오류: identityToken이 null입니다.');
        return null;
      }

      print('[AppleLogin] Firebase OAuthCredential 생성...');
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        rawNonce: rawNonce,
      );

      print('[AppleLogin] FirebaseAuth 인증 시도...');
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      final user = userCredential.user;
      if (user == null) {
        print('[AppleLogin] Firebase 인증 실패: user == null');
        return null;
      }

      print(
          '[AppleLogin] Firebase 로그인 성공: uid=${user.uid}, email=${user.email}');

      final userId = user.uid;
      final email = user.email ?? credential.email ?? 'no_email@apple.com';
      final displayName =
          credential.givenName ?? user.displayName ?? 'AppleUser';
      final photoUrl = '';

      final docRef = _firestore.collection('users').doc(userId);
      final userDoc = await docRef.get();

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

      await saveLoginUserId(userId);
      await saveLoginProvider('apple');

      final freshDoc = await docRef.get();
      print('[AppleLogin] 로그인 성공 → UserModel 반환 완료');
      return UserModel.fromJson(freshDoc.data()!);
    } catch (e, stack) {
      print('[AppleLogin] 오류 발생: $e');
      print('[AppleLogin] 스택트레이스:\n$stack');
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
