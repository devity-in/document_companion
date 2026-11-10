import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    adService.adsDisabledUntil.addListener(_onAdStateChanged);
    if (!adService.adsDisabled) _loadAd();
  }

  void _loadAd() {
    // Use standard banner size - adaptive size will be handled in build
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Dispose the ad if it fails to load
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isAdLoaded = false;
          });
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    );

    _bannerAd?.load();
  }

  void _onAdStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    adService.adsDisabledUntil.removeListener(_onAdStateChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (adService.adsDisabled || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible header
          InkWell(
            onTap: _toggleCollapse,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Ad',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isCollapsed ? Icons.expand_more : Icons.expand_less,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  Text(
                    _isCollapsed ? 'Show ad' : 'Hide ad',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ad content
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isCollapsed
                ? const SizedBox.shrink()
                : Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: _bannerAd!.size.height.toDouble(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AdWidget(ad: _bannerAd!),
                  ),
          ),
        ],
      ),
    );
  }
}
