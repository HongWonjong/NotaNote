import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/user_model.dart';

/// Firestore 사용자 데이터 처리 서비스
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 사용자 정보 저장
  Future<void> setUser(UserModel user) async {
    // toMap() → toJson()으로 수정
    await _db.collection('users').doc(user.userId).set(user.toJson());
  }

  /// 사용자 정보 업데이트
  Future<void> updateUser(UserModel user) async {
    // toMap() → toJson()으로 수정
    await _db.collection('users').doc(user.userId).update(user.toJson());
  }

  /// 단일 사용자 정보 1회 로딩
  Future<UserModel?> getUserOnce(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      // fromMap() → fromJson()으로 수정
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// 실시간 사용자 정보 스트림
  Stream<UserModel?> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        // fromMap() → fromJson()으로 수정
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }
}
