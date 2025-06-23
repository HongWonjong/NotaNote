import 'package:shared_preferences/shared_preferences.dart';

/// 로그인한 사용자 ID 저장
Future<void> saveLoginUserId(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
}

/// 로그인한 사용자 ID 조회
Future<String?> getLoginUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}

/// 로그인 제공자(google/kakao) 저장
Future<void> saveLoginProvider(String provider) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('loginProvider', provider);
}

/// 로그인 제공자 조회
Future<String?> getLoginProvider() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('loginProvider');
}

/// 로그인 정보 초기화 (로그아웃용)
Future<void> clearLoginInfo() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId');
  await prefs.remove('loginProvider');
}

Future<void> saveAppleUserIdentifier(String userIdentifier) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('apple_user_identifier', userIdentifier);
}

Future<String?> getAppleUserIdentifier() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('apple_user_identifier');
}


