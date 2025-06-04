// viewmodels/user_profile_viewmodel.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/user_model.dart';

/// 사용자 ID에 따라 상태를 분리하기 위한 ProviderFamily
final userProfileViewModelProvider =
    AsyncNotifierProviderFamily<UserProfileViewModel, UserModel?, String>(
        UserProfileViewModel.new);

/// 사용자 프로필 ViewModel (ProviderFamily 기반)ㅁ
class UserProfileViewModel extends FamilyAsyncNotifier<UserModel?, String> {
  final _firestore = FirebaseFirestore.instance;
  late String _userId;

  /// 빌드 시 사용자 ID 저장하고 Firestore에서 불러오기
  @override
  Future<UserModel?> build(String userId) async {
    _userId = userId;

    final doc = await _firestore.collection('users').doc(_userId).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return UserModel.fromJson(data);
  }

  /// 최신 유저 정보 다시 불러오기
  Future<void> refreshUser() async {
    final doc = await _firestore.collection('users').doc(_userId).get();
    if (!doc.exists) return;

    state = AsyncValue.data(UserModel.fromJson(doc.data()!));
  }

  /// Firestore에서 사용자 정보 업데이트
  Future<void> updateUser({
    required String displayName,
    required String email,
  }) async {
    await _firestore.collection('users').doc(_userId).update({
      'displayName': displayName,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updated = await _firestore.collection('users').doc(_userId).get();
    state = AsyncValue.data(UserModel.fromJson(updated.data()!));
  }
}
