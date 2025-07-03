import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// 플랫폼별, 모드별 광고 단위 ID를 관리하는 도우미 클래스
class AdHelper {
  // 실제 광고 단위 ID를
  static const String _realIOSAdUnitId =
      'ca-app-pub-8918591811866398/2218406512'; //ios 앱 ID
  static const String _realAndroidAdUnitId =
      'ca-app-pub-8918591811866398/1322281330'; // 안드로이드 앱 ID

  // 구글에서 제공하는 공식 테스트 ID
  static const String _testIOSAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testAndroidAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static String get interstitialAdUnitId {
    //릴리즈 모드일 때만 true가
    if (kReleaseMode) {
      // 릴리즈 모드일 경우: 실제 광고 ID 반환
      if (Platform.isAndroid) {
        return _realAndroidAdUnitId;
      } else if (Platform.isIOS) {
        return _realIOSAdUnitId;
      }
    }
    // 디버그 모드일 경우: 테스트 광고 ID 반환
    if (Platform.isAndroid) {
      return _testAndroidAdUnitId;
    } else if (Platform.isIOS) {
      return _testIOSAdUnitId;
    }

    // 지원하지 않는 플랫폼에 대한 예외 처리
    throw UnsupportedError('지원하지 않는 플랫폼입니다.');
  }
}
