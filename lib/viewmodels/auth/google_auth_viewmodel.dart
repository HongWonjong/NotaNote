// 인증 관련 비즈니스 로직을 처리하는 ViewModel
// - 로그인/로그아웃 기능
// - 소셜 로그인 (구글, 네이버, 카카오) 통합
// - 유저 프로필 정보 관리
// - 인증 상태 관리 및 감지

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/services/auth_service.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

final googleAuthViewModelProvider = Provider((ref) => GoogleAuthViewmodel());

class GoogleAuthViewmodel {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Google 로그인 실행 후 Firestore에 사용자 데이터 저장
  Future<UserCredential?> signInWithGoogle() async {
    final userCredential = await _authService.signInWithGoogle();
    final user = userCredential?.user;

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
      throw Exception("구글 로그인 실패");
    }
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;
}
