import 'dart:io';

class AdHelper {
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // 이것은 구글에서 제공하는 테스트용 ID입니다.
      return 'ca-app-pub-8918591811866398/1322281330';
    } else if (Platform.isIOS) {
      // 기존에 사용하시던 iOS 전면 광고 단위 ID
      return 'ca-app-pub-8918591811866398/2218406512';
    } else {
      // 지원하지 않는 플랫폼에 대한 예외 처리
      throw UnsupportedError('지원하지 않는 플랫폼입니다.');
    }
  }
}
