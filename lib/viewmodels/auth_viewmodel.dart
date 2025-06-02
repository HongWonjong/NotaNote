// 인증 관련 비즈니스 로직을 처리하는 ViewModel
// - 로그인/로그아웃 기능
// - 소셜 로그인 (구글, 네이버, 카카오) 통합
// - 유저 프로필 정보 관리
// - 인증 상태 관리 및 감지

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/services/auth_service.dart';

final authViewModelProvider = Provider((ref) => AuthViewmodel());

class AuthViewmodel {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Google 로그인 실행 후 Firestore에 사용자 데이터 저장
  Future<UserCredential?> signInWithGoogle() async {
    final userCredential = await _authService.signInWithGoogle();
    final user = userCredential?.user;

    /// UID 기반 해시태그 생성기
    /// UID로부터 SHA256 해시를 생성하고, 앞 6자리만 잘라서 해시태그 생성
    String generateHashedTag(String uid) {
      final bytes = utf8.encode(uid); // UID → byte로 인코딩
      final digest = sha256.convert(bytes); // SHA256 해시 계산
      return '#${digest.toString().substring(0, 6)}'; // 앞 6자리만 사용
    }

    if (user != null) {
      final userModel = UserModel(
        userId: user.uid,
        displayName: user.displayName ?? 'NoName',
        email: user.email ?? 'unknown@email.com',
        photoUrl: user.photoURL ?? '',
        hashTag: generateHashedTag(user.uid),
        loginProviders: 'google',
        createdAt: DateTime.now(), // 임시 표시, Firestore에서 서버시간으로 덮어씀
        updatedAt: DateTime.now(),
      );

      // Firestore에 저장
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toJson(), SetOptions(merge: true));

      // 서버 시간으로 createdAt, updatedAt 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } else {
      throw Exception("로그인 실패");
    }
  }

  /// 로그아웃 처리
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // 나중에 카카오 로그아웃 추가
  }
}
