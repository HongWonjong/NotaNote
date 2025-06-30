import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nota_note/pages/memo_page/widgets/transcribe_settings_dialog.dart';

Future<Map<String, dynamic>?> showTranscribeSettingsDialog(
    BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    builder: (_) => TranscribeSettingsDialog(),
  );
}

Future<void> showRewardedAd(BuildContext context) async {
  // 로딩 다이얼로그 먼저 표시 (사용자 경험 보호용)
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  bool adWatched = false;

  // 광고 준비 및 표시 로직
  RewardedAd.load(
    adUnitId: 'ca-app-pub-8918591811866398/2218406512', // 실제 광고 유닛 ID로 변경
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (RewardedAd ad) {
        ad.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            adWatched = true;
          },
        );
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
      onAdFailedToLoad: (LoadAdError error) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        }
        // 필요시 에러 안내
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('광고를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.')),
        );
      },
    ),
  );

  // 광고 시청 완료까지 대기
  while (!adWatched) {
    await Future.delayed(Duration(milliseconds: 100));
  }
}

void showTranscribingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 32),
          Icon(Icons.hourglass_empty, size: 48, color: Colors.teal),
          SizedBox(height: 16),
          Text('텍스트로 변환하고 있습니다.\n잠시만 기다려주세요!', textAlign: TextAlign.center),
          SizedBox(height: 32),
        ],
      ),
    ),
  );
}
