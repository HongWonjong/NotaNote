import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter/foundation.dart'; // kDebugMode 사용

class ReviewHelper {
  static const _launchCountKey = 'launch_count';
  static const _hasRequestedReviewKey = 'has_requested_review';

  /// 앱 실행 횟수 누적 후 조건 맞으면 리뷰 요청
  static Future<void> checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    final hasRequestedReview = prefs.getBool(_hasRequestedReviewKey) ?? false;
    int launchCount = prefs.getInt(_launchCountKey) ?? 0;

    if (kDebugMode) {
      debugPrint('✅ [리뷰체크] 실행 횟수: $launchCount / 리뷰 요청함?: $hasRequestedReview');
    }

    if (hasRequestedReview) return;

    launchCount++;
    await prefs.setInt(_launchCountKey, launchCount);

    if (launchCount == 3) {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        if (kDebugMode) {
          debugPrint('🎯 [리뷰체크] 조건 만족! 리뷰 요청 시도');
        }
        await inAppReview.requestReview();
        await prefs.setBool(_hasRequestedReviewKey, true);
        if (kDebugMode) {
          debugPrint('🙌 [리뷰체크] 리뷰 요청 완료 및 플래그 저장');
        }
      }
    }
  }
}
