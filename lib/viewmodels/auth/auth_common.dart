// auth_common.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';

/// UID로부터 SHA256 해시를 생성하고, 앞 6자리만 잘라서 해시태그 생성
String generateHashedTag(String uid) {
  final bytes = utf8.encode(uid); // UID → byte로 인코딩
  final digest = sha256.convert(bytes); // SHA256 해시 계산
  return '#${digest.toString().substring(0, 6)}'; // 앞 6자리만 사용
}

/// 현재 로그인한 사용자 UID 조회 (SharedPreferences 기반)
Future<String?> getCurrentUserId() async {
  return await getLoginUserId();
}

/// 공통 로그아웃 처리
Future<void> signOut() async {
  final provider = await getLoginProvider();

  if (provider == 'google') {
    await FirebaseAuth.instance.signOut();
  } else if (provider == 'kakao') {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      print('카카오 로그아웃 예외 무시: $e');
    }
  }

  await clearLoginInfo(); // SharedPreferences에서 유저 정보 초기화
}
