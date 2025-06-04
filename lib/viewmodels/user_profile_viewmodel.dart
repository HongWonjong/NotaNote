import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/user_model.dart';

final userProfileViewModelProvider =
    AsyncNotifierProvider<UserProfileViewModel, UserModel?>(
  () => UserProfileViewModel(),
);

class UserProfileViewModel extends AsyncNotifier<UserModel?> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> build() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      if (!snapshot.exists) return null;
      return UserModel.fromJson(snapshot.data()!);
    } catch (e, st) {
      log('[UserProfile] 유저 정보 불러오기 실패: $e', stackTrace: st);
      return null;
    }
  }

  /// 사용자 정보 업데이트 (이름, 이메일 수정)
  Future<void> updateUser({
    String? email,
    String? displayName,
  }) async {
    final currentUser = state.value;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      email: email,
      displayName: displayName,
    );

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updatedUser.toJson());
      state = AsyncData(updatedUser);
      log('[UserProfile] 유저 정보 수정 완료');
    } catch (e, st) {
      log('[UserProfile] 유저 정보 수정 실패: $e', stackTrace: st);
    }
  }
}
