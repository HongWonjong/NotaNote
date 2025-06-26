import Flutter
import UIKit
import KakaoSDKAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
   // 카카오톡으로 로그인을 위한 설정
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      if (AuthApi.isKakaoTalkLoginUrl(url)) {
          return AuthApi.handleOpenUrl(url: url)
      }
      // 다른 플러그인(구글, 파이어베이스 등등) 처리를 위해 super 유지
      return super.application(app, open: url, options: options)
  }
}