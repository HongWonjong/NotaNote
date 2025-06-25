import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? result = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('알림 서비스 초기화 결과: $result');

      // Android 채널 생성
      await _createNotificationChannels();
    } catch (e) {
      debugPrint('알림 서비스 초기화 오류: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
        'test_channel',
        '테스트 알림',
        description: '앱 테스트용 알림 채널',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel customChannel =
          AndroidNotificationChannel(
        'custom_channel',
        '커스텀 알림',
        description: '사용자 정의 알림 채널',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(testChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(customChannel);

      debugPrint('알림 채널 생성 완료');
    } catch (e) {
      debugPrint('알림 채널 생성 오류: $e');
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      // Android 13 이상에서 알림 권한 요청
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        debugPrint('알림 권한 요청 결과: $status');
        return status.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('알림 권한 요청 오류: $e');
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 알림을 탭했을 때의 처리 로직
    debugPrint('알림이 탭되었습니다: ${response.payload}');
  }

  Future<void> showTestNotification() async {
    try {
      // 알림 권한 확인 및 요청
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        throw Exception('알림 권한이 필요합니다.');
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'test_channel',
        '테스트 알림',
        channelDescription: '앱 테스트용 알림 채널',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.show(
        0,
        'NotaNote 알림',
        '새로운 메모가 생성되었습니다!',
        platformChannelSpecifics,
        payload: 'test_notification',
      );

      debugPrint('테스트 알림 전송 완료');
    } catch (e) {
      debugPrint('테스트 알림 전송 오류: $e');
      rethrow;
    }
  }

  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // 알림 권한 확인 및 요청
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        throw Exception('알림 권한이 필요합니다.');
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'custom_channel',
        '커스텀 알림',
        channelDescription: '사용자 정의 알림 채널',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('커스텀 알림 전송 완료');
    } catch (e) {
      debugPrint('커스텀 알림 전송 오류: $e');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('모든 알림 취소 완료');
    } catch (e) {
      debugPrint('알림 취소 오류: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('알림 취소 완료: $id');
    } catch (e) {
      debugPrint('알림 취소 오류: $e');
    }
  }
}
