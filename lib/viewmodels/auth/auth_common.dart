//공통 로직 관리용: UID 해시 생성, 공통 유틸 함수
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// UID로부터 SHA256 해시를 생성하고, 앞 6자리만 잘라서 해시태그 생성
String generateHashedTag(String uid) {
  final bytes = utf8.encode(uid); // UID → byte로 인코딩
  final digest = sha256.convert(bytes); // SHA256 해시 계산
  return '#${digest.toString().substring(0, 6)}'; // 앞 6자리만 사용
}

/// 공통 로그아웃 처리
Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
}
