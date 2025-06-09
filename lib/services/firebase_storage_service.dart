import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 프로필 이미지를 Firebase Storage에 업로드하고 Firestore에 URL 저장
///
/// - [userId]: 현재 로그인한 사용자 ID
/// - [imageFile]: 갤러리에서 선택된 이미지 파일
///
/// 저장 위치: `users/{userId}/profile.jpg`
/// 업로드 완료 후 Firestore의 photoUrl 필드 업데이트
Future<void> uploadProfileImage({
  required String userId,
  required File imageFile,
}) async {
  try {
    // 1. Firebase Storage 경로 설정
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(userId)
        .child('profile.jpg');

    // 2. 이미지 업로드
    final uploadTask = await storageRef.putFile(imageFile);

    // 3. 업로드된 이미지의 다운로드 URL 획득
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // 4. Firestore의 사용자 문서에 URL 저장
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.update({
      'photoUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    // 오류 발생 시 로그 출력 및 throw
    print('프로필 이미지 업로드 오류: $e');
    rethrow;
  }
}
