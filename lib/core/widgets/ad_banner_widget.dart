// lib/presentation/widgets/ad_banner_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../infrastructure/ads/ad_service.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isBannerAdReady = true;
          });
        }
      },
    );
    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBannerAdReady && _bannerAd != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
