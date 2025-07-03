// lib/utils/review_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewHelper {
  static const _launchCountKey = 'launch_count';
  static const _hasRequestedReviewKey = 'has_requested_review';

  /// 앱 실행 횟수 누적 후 조건 맞으면 리뷰 요청
  static Future<void> checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    final hasRequestedReview = prefs.getBool(_hasRequestedReviewKey) ?? false;
    if (hasRequestedReview) return;

    int launchCount = prefs.getInt(_launchCountKey) ?? 0;
    launchCount++;
    await prefs.setInt(_launchCountKey, launchCount);

    // 조건: 앱 3회 실행 시 리뷰 요청
    if (launchCount == 3) {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool(_hasRequestedReviewKey, true);
      }
    }
  }

  /// 수동 리뷰 요청 (리뷰 남기기 버튼 등에서 사용)
  static Future<void> forceRequestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }
}
