import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdPage extends StatefulWidget {
  final VoidCallback? onAdComplete;

  const InterstitialAdPage({this.onAdComplete, super.key});

  @override
  State<InterstitialAdPage> createState() => _InterstitialAdPageState();
}

class _InterstitialAdPageState extends State<InterstitialAdPage> {
  InterstitialAd? _ad;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-8918591811866398/2218406512', // 실제 광고 단위 ID 사용
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _ad = ad;

          // 전면 광고 콜백 설정
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (mounted) {
                Navigator.of(context).pop(); // 광고 페이지 pop
                if (widget.onAdComplete != null) {
                  Future.microtask(
                      () => widget.onAdComplete!()); // 광고 종료 후 콜백 호출
                }
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (mounted) {
                Navigator.of(context).pop(); // 광고 페이지 pop
                if (widget.onAdComplete != null) {
                  Future.microtask(
                      () => widget.onAdComplete!()); // 실패 시에도 콜백 호출
                }
              }
            },
          );

          _ad!.show(); // 광고 표시
        },
        onAdFailedToLoad: (LoadAdError error) {
          // 광고 로드 실패 시 즉시 pop 및 콜백
          if (mounted) {
            Navigator.of(context).pop();
            if (widget.onAdComplete != null) {
              widget.onAdComplete!();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }
}
