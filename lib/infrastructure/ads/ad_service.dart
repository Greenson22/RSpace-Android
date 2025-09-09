// lib/data/services/ad_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Gunakan ID unit iklan pengujian dari AdMob
  static String get bannerAdUnitId {
    if (kReleaseMode) {
      // Mode Produksi
      if (Platform.isAndroid) {
        return 'ca-app-pub-5320800343545863/2766800880';
      } else if (Platform.isIOS) {
        // Ganti dengan ID unit iklan banner iOS Anda
        return 'ca-app-pub-5320800343545863/2766800880';
      }
    }
    // Mode Debug (menggunakan ID pengujian)
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kReleaseMode) {
      // Ganti dengan ID unit iklan rewarded produksi Anda
      if (Platform.isAndroid) {
        // ==> ID ANDA TELAH DITERAPKAN DI SINI <==
        return 'ca-app-pub-5320800343545863/7888481612';
      } else if (Platform.isIOS) {
        // ==> GANTI JUGA JIKA ANDA PUNYA VERSI IOS <==
        return 'ca-app-pub-5320800343545863/7888481612';
      }
    }
    // ID pengujian dari AdMob
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  // Fungsi untuk membuat dan memuat banner ad
  static BannerAd createBannerAd({VoidCallback? onAdLoaded}) {
    BannerAd ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (kDebugMode) {
            print('BannerAd loaded.');
          }
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (kDebugMode) {
            print('BannerAd failed to load: $error');
          }
        },
      ),
    );
    return ad;
  }

  static void loadRewardedAd({
    required Function(RewardedAd) onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
