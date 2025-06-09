import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/user_model.dart';

/// 사용자 ID를 기반으로 실시간 유저 정보를 제공하는 StreamProviderFamily
final userProfileProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
  final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

  // Firestore 문서의 실시간 변경사항을 수신하여 UserModel로 변환
  return docRef.snapshots().map((snapshot) {
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    return UserModel.fromJson(data);
  });
});

/// 사용자 정보 수정 함수 (Provider 외부에서 호출)
Future<void> updateUserProfile({
  required String userId,
  required String displayName,
  required String email,
}) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

  await docRef.update({
    'displayName': displayName,
    'email': email,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
