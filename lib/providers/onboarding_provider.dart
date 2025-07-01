import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final onBoardingProvider =
    StateNotifierProvider<OnBoardingNotifier, bool>((ref) {
  return OnBoardingNotifier();
});

final onBoardingStatusFutureProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasCompletedOnBoarding') ?? false;
});

class OnBoardingNotifier extends StateNotifier<bool> {
  final logger = Logger();

  OnBoardingNotifier() : super(false) {
    _loadOnBoardingStatus();
  }

  Future<void> _loadOnBoardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('hasCompletedOnBoarding') ?? false;
      state = hasCompleted;
      logger.i('온보딩 상태 로드: $hasCompleted');
    } catch (e) {
      logger.e('온보딩 상태 로드 실패: $e');
    }
  }

  Future<void> completeOnBoarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnBoarding', true);
      state = true;
      logger.i('온보딩 완료 상태 저장: true');
    } catch (e) {
      logger.e('온보딩 완료 상태 저장 실패: $e');
    }
  }
}
