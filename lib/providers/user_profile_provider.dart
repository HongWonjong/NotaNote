import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/user_model.dart';

/// 사용자 정보를 userId 기반으로 실시간 스트리밍하는 ProviderFamily
final userProfileProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, userId) {
  final docStream =
      FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

  return docStream.map((doc) {
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    } else {
      return null;
    }
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
