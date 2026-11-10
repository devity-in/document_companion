import 'dart:io';

import 'package:document_companion/local_database/handler/settings_database_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service to manage interstitial and rewarded ads
/// Provides a clean interface for showing ads after user actions
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  // Counter to limit ad frequency
  int _operationCount = 0;
  static const int _adFrequency = 3; // Show ad every 3 operations

  static const _adsDisabledUntilKey = 'ads_disabled_until';

  /// When set and in the future, no banner or interstitial ads are shown.
  /// Earned by watching a rewarded ad.
  final ValueNotifier<DateTime?> adsDisabledUntil = ValueNotifier(null);

  bool get adsDisabled {
    final until = adsDisabledUntil.value;
    return until != null && until.isAfter(DateTime.now());
  }

  /// Restores the ad-free period saved by a previous session.
  Future<void> loadState() async {
    try {
      final stored = await settingsDatabaseHandler.getValue(
        _adsDisabledUntilKey,
      );
      final millis = int.tryParse(stored ?? '');
      if (millis != null) {
        adsDisabledUntil.value = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (e) {
      debugPrint('Could not load ad state: $e');
    }
  }

  /// Turns banner and interstitial ads off for [duration], starting now.
  Future<void> disableAdsFor(Duration duration) async {
    final until = DateTime.now().add(duration);
    adsDisabledUntil.value = until;
    await settingsDatabaseHandler.setValue(
      _adsDisabledUntilKey,
      until.millisecondsSinceEpoch.toString(),
    );
  }

  // Ad unit IDs. Debug builds use Google's published test units: loading
  // live units during development counts as invalid traffic and can get
  // the AdMob account suspended.
  static String get bannerAdUnitId => kDebugMode
      ? (Platform.isIOS
            ? 'ca-app-pub-3940256099942544/2934735716'
            : 'ca-app-pub-3940256099942544/6300978111')
      : 'ca-app-pub-3672075156086851/4113110525';
  static String get _interstitialAdUnitId => kDebugMode
      ? (Platform.isIOS
            ? 'ca-app-pub-3940256099942544/4411468910'
            : 'ca-app-pub-3940256099942544/1033173712')
      : 'ca-app-pub-3672075156086851/3071491590';
  static String get _rewardedAdUnitId => kDebugMode
      ? (Platform.isIOS
            ? 'ca-app-pub-3940256099942544/1712485313'
            : 'ca-app-pub-3940256099942544/5224354917')
      : 'ca-app-pub-3672075156086851/4328732948';

  /// Loads an interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _setInterstitialListeners(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialReady = false;
        },
      ),
    );
  }

  /// Sets up listeners for interstitial ad
  void _setInterstitialListeners(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialReady = false;
        // Load next ad
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _isInterstitialReady = false;
        loadInterstitialAd();
      },
    );
  }

  /// Shows interstitial ad after operation completion
  /// Returns true if ad was shown, false otherwise
  bool showInterstitialAdIfReady() {
    if (adsDisabled) return false;

    // Increment operation counter
    _operationCount++;

    // Only show ad every N operations
    if (_operationCount < _adFrequency) {
      return false;
    }

    // Reset counter
    _operationCount = 0;

    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
      return true;
    } else {
      // Load ad for next time
      loadInterstitialAd();
      return false;
    }
  }

  /// Loads a rewarded ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          _setRewardedListeners(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedReady = false;
        },
      ),
    );
  }

  /// Sets up listeners for rewarded ad
  void _setRewardedListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        // Call dismissed callback if set
        if (_rewardedAdDismissedCallback != null) {
          _rewardedAdDismissedCallback!();
        }
        ad.dispose();
        _isRewardedReady = false;
        // Clear callbacks
        _rewardedAdDismissedCallback = null;
        _rewardedAdFailedCallback = null;
        // Load next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        // Call failed callback if set
        if (_rewardedAdFailedCallback != null) {
          _rewardedAdFailedCallback!(error.toString());
        }
        ad.dispose();
        _isRewardedReady = false;
        // Clear callbacks
        _rewardedAdDismissedCallback = null;
        _rewardedAdFailedCallback = null;
        loadRewardedAd();
      },
    );
  }

  /// Shows rewarded ad with callback for reward handling
  /// Returns true if ad was shown, false if not ready
  bool showRewardedAd({
    required Function() onRewarded,
    Function()? onAdDismissed,
    Function(String)? onAdFailedToShow,
  }) {
    if (_isRewardedReady && _rewardedAd != null) {
      // Store callbacks for use in listeners
      _rewardedAdDismissedCallback = onAdDismissed;
      _rewardedAdFailedCallback = onAdFailedToShow;

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          // Call the reward callback
          onRewarded();
        },
      );
      return true;
    } else {
      // Load ad for next time
      loadRewardedAd();
      if (onAdFailedToShow != null) {
        onAdFailedToShow('Ad not ready. Please try again in a moment.');
      }
      return false;
    }
  }

  // Callback storage for rewarded ad listeners
  Function()? _rewardedAdDismissedCallback;
  Function(String)? _rewardedAdFailedCallback;

  /// Preloads both ad types (call this on app startup)
  void preloadAds() {
    loadInterstitialAd();
    loadRewardedAd();
  }

  /// Disposes all ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _isInterstitialReady = false;
    _isRewardedReady = false;
  }

  /// Check if rewarded ad is ready
  bool get isRewardedAdReady => _isRewardedReady;
}

final adService = AdService();
