import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("AppDelegate: application didFinishLaunchingWithOptions 시작")

    // Flutter 플러그인 등록
    print("AppDelegate: GeneratedPluginRegistrant 등록 시작")
    GeneratedPluginRegistrant.register(with: self)
    print("AppDelegate: GeneratedPluginRegistrant 등록 완료")

    // Firebase 초기화
    print("AppDelegate: Firebase 초기화 시작")
    FirebaseApp.configure()
    print("AppDelegate: Firebase 초기화 완료")

    print("AppDelegate: super.application 호출")
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    print("AppDelegate: super.application 완료, result: \(result)")

    return result
  }
}