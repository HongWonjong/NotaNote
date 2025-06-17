import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/user_model.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';

/// 실시간 사용자 프로필 정보를 제공하는 StreamProvider
/// userIdProvider를 통해 로그인된 사용자 ID를 구한 후
/// Firestore의 users/{userId} 경로에서 UserModel 데이터를 구독한다.
final userProfileProvider =
    StreamProvider.autoDispose<UserModel?>((ref) async* {
  final userId = ref.watch(userIdProvider); // 현재 로그인된 사용자 ID를 가져옴
  if (userId == null) {
    yield null;
    return;
  }

  final snapshot = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots(); // Firestore 실시간 스트림

  // 실시간 문서 변경에 따라 UserModel로 변환
  await for (final doc in snapshot) {
    if (doc.exists) {
      yield UserModel.fromJson(doc.data()!);
    } else {
      yield null;
    }
  }
});

/// 외부에서 사용자 정보를 업데이트할 수 있는 함수
/// 사용자 ID를 기반으로 Firestore의 users/{userId} 문서를 업데이트한다.
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
