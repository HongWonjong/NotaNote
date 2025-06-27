import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// UID로부터 SHA256 해시를 생성하고, 앞 6자리만 잘라서 해시태그 생성
String generateHashedTag(String uid) {
  final bytes = utf8.encode(uid); // UID → byte로 인코딩
  final digest = sha256.convert(bytes); // SHA256 해시 계산
  return '#${digest.toString().substring(0, 6)}'; // 앞 6자리만 사용
}

/// 현재 로그인한 사용자 UID 조회 (SharedPreferences 기반)
Future<String?> getCurrentUserId({bool appLaunch = false}) async {
  final userId = await getLoginUserId();
  final provider = await getLoginProvider();

  log('[AuthCommon] SharedPreferences → userId: $userId, provider: $provider');

  if (userId == null || provider == null) return null;

  if (provider == 'google') return userId;

  if (provider == 'kakao') {
    final valid = await isKakaoSessionValid();
    log('[AuthCommon] Kakao 세션 유효성: $valid');
    return valid ? userId : null;
  }

  if (provider == 'apple') {
    final userIdentifier = await getAppleUserIdentifier();

    if (userIdentifier == null) {
      // 앱 처음 실행일 경우만 자동 로그인 방지
      log('[Apple] 앱 최초 실행 → 자동 로그인 방지 → null 반환');
      return null;
    } else {
      return userId; // 로그인 완료 후 내부에서는 유지
    }
  }

  return null;
}

/// Kakao 세션 유효성 확인
Future<bool> isKakaoSessionValid() async {
  try {
    final hasToken = await AuthApi.instance.hasToken();
    log('[Kakao] hasToken: $hasToken');

    if (!hasToken) return false;

    // 액세스 토큰 유효성 확인 (세션이 만료되었는지 확인)
    await UserApi.instance.accessTokenInfo();
    log('[Kakao] accessToken 유효함');
    return true;
  } catch (e) {
    log('[Kakao] 세션 유효하지 않음 → $e');
    return false;
  }
}

/// Apple은 재로그인 없이는 세션 확인이 불가능하므로 항상 false 반환
Future<bool> isAppleSessionValid() async {
  final userIdentifier = await getAppleUserIdentifier();

  if (userIdentifier == null) {
    log('[Apple] userIdentifier 없음 → 자동 로그인 불가');
    return false;
  }

  try {
    final credentialState =
        await SignInWithApple.getCredentialState(userIdentifier);
    log('[Apple] credentialState: $credentialState');
    return credentialState == CredentialState.authorized;
  } catch (e) {
    log('[Apple] getCredentialState 오류: $e');
    return false;
  }
}

/// 공통 로그아웃 처리
Future<void> signOut() async {
  final provider = await getLoginProvider();
  log('[AuthCommon] 로그아웃 시작 → provider: $provider');

  if (provider == 'google') {
    await FirebaseAuth.instance.signOut();
    log('[AuthCommon] Google 로그아웃 완료');
  } else if (provider == 'kakao') {
    try {
      await UserApi.instance.logout();
      log('[AuthCommon] Kakao 로그아웃 완료');
    } catch (e) {
      log('[AuthCommon] Kakao 로그아웃 예외 무시: $e');
    }
  } else if (provider == 'apple') {
    // Firebase에서 세션 제거
    await FirebaseAuth.instance.signOut();
    log('[AuthCommon] Apple(Firebase) 로그아웃 완료');
    // Apple은 별도 세션 없음 (getCredentialState로만 확인)
    // 필요시 SharedPreferences에서 apple_user_identifier 등 추가 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('apple_user_identifier');
    log('[AuthCommon] Apple userIdentifier 제거 완료');
  }

  await clearLoginInfo(); // SharedPreferences에서 유저 정보 초기화
  log('[AuthCommon] SharedPreferences 초기화 완료');
}
