import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

class Initializer {
  static Future<void> initialize() async {
    // Firebase 초기화
    try {
      await Firebase.initializeApp();
      print('Firebase 초기화 완료');
    } catch (e) {
      print('Firebase 초기화 실패: $e');
    }

    // dotenv 초기화
    await dotenv.load(fileName: ".env");
    print('dotenv 로드 완료');

    // KakaoSdk 초기화
    KakaoSdk.init(
      nativeAppKey: '3994ba43bdfc5a2ac995b7743b33b320',
      javaScriptAppKey: '20b47f3f4ea59df1cdea65af1725c34a',
    );
    print('KakaoSdk 초기화 완료');
  }
}