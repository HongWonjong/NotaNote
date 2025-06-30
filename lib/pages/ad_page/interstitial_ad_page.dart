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
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-8918591811866398/2218406512', //광고 단위 id
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _ad = ad;
          setState(() => _isAdLoaded = true);
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (widget.onAdComplete != null) widget.onAdComplete!();
              Navigator.of(context).maybePop();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (widget.onAdComplete != null) widget.onAdComplete!();
              Navigator.of(context).maybePop();
            },
          );
          _ad!.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (widget.onAdComplete != null) widget.onAdComplete!();
          Navigator.of(context).maybePop();
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
