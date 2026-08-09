import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/installation_id_store.dart';
import '../data/app_ad_service.dart';
import '../data/monetization_api.dart';
import '../data/monetization_config.dart';
import '../domain/access_status.dart';
import '../domain/reward_attempt.dart';

enum RewardFlowState {
  idle,
  starting,
  showingAd,
  verifying,
  pending,
  verified,
  failed,
}

class MonetizationController extends ChangeNotifier {
  MonetizationController._({
    required this.enabled,
    required MonetizationApi? api,
    required AppAdService adService,
    DateTime Function()? now,
  }) : _api = api,
       _adService = adService,
       _now = now ?? DateTime.now;

  factory MonetizationController.create() {
    final api = MonetizationConfig.backendConfigured
        ? MonetizationApi(apiUrl: MonetizationConfig.apiUrl)
        : null;
    late MonetizationController controller;
    final adService = AppAdService(
      onPaidEvent: (placement, value, precision, currency) {
        controller.reportPaidAd(placement, value, precision, currency);
      },
      onStateChanged: () => controller._notifyAdStateChanged(),
    );
    controller = MonetizationController._(
      enabled: api != null,
      api: api,
      adService: adService,
    );
    return controller;
  }

  factory MonetizationController.disabled() => MonetizationController._(
    enabled: false,
    api: null,
    adService: AppAdService(),
  );

  @visibleForTesting
  factory MonetizationController.forTesting({
    required MonetizationApi api,
    required AppAdService adService,
    DateTime Function()? now,
  }) => MonetizationController._(
    enabled: true,
    api: api,
    adService: adService,
    now: now,
  );

  static const _completedScanCountKey =
      'mass_lens.completed_scan_count_for_ads';
  static const _rewardStateKey = 'mass_lens.reward_attempt_state.v1';
  static const _rewardAttemptLifetime = Duration(hours: 24);
  static const _rewardAdGuard = Duration(minutes: 2);
  static const _reconcileRequestLimit = Duration(seconds: 5);

  final bool enabled;
  final MonetizationApi? _api;
  final AppAdService _adService;
  final DateTime Function() _now;

  AccessStatus _access = const AccessStatus.fallback();
  String _clientId = '';
  String? _message;
  bool _initialized = false;
  Future<void>? _initialization;
  bool _loading = false;
  int _completedScanCount = 0;
  int? _pendingInterstitialScanCount;
  List<PendingRewardAttempt> _rewardAttempts = [];
  DateTime? _lastRewardAdStartedAt;
  RewardFlowState _rewardFlowState = RewardFlowState.idle;
  bool _rewardActionBusy = false;
  bool _reconcilingRewards = false;
  bool _rewardStateNeedsPersist = false;

  AccessStatus get access => _access;
  String? get message => _message;
  bool get loading => _loading;
  bool get canRequestAds => _adService.canRequestAds && _access.adsEnabled;
  bool get canRequestNativeAds =>
      _adService.canRequestNativeAds && _access.adsEnabled;
  bool get rewardedAdReady => _adService.rewardedReady;
  bool get onboardingInterstitialReady =>
      _access.adsEnabled && _adService.interstitialReady;
  bool get onboardingInterstitialLoading =>
      _access.adsEnabled && _adService.interstitialLoading;
  bool get privacyOptionsRequired => _adService.privacyOptionsRequired;
  RewardFlowState get rewardFlowState => _rewardFlowState;
  bool get rewardActionBusy => _rewardActionBusy || _reconcilingRewards;
  bool get hasPendingReward => _rewardAttempts.isNotEmpty;
  int get pendingRewardCount => _rewardAttempts.length;

  Duration get rewardRetryAfter {
    final startedAt = _lastRewardAdStartedAt;
    if (startedAt == null) return Duration.zero;
    final elapsed = _now().difference(startedAt);
    if (elapsed.isNegative) return _rewardAdGuard;
    final remaining = _rewardAdGuard - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get rewardStartBlocked => rewardRetryAfter > Duration.zero;

  void _notifyAdStateChanged() {
    if (!hasListeners) return;
    notifyListeners();
  }

  Future<void> initialize() {
    final pending = _initialization;
    if (pending != null) return pending;
    if (_initialized) return Future<void>.value();
    _initialized = true;
    late final Future<void> initialization;
    initialization = _initialize().whenComplete(() {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    });
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initialize() async {
    if (!enabled) {
      notifyListeners();
      return;
    }

    _clientId = await InstallationIdStore.getOrCreate();
    try {
      final preferences = await SharedPreferences.getInstance();
      _completedScanCount = preferences.getInt(_completedScanCountKey) ?? 0;
      _restoreRewardState(preferences.getString(_rewardStateKey));
      if (_rewardStateNeedsPersist) await _persistRewardState();
    } on Object {
      // Access and ad cadence can continue if local preferences are unavailable.
    }
    notifyListeners();
    await refreshAccess();
    await reconcileRewardAttempts();
  }

  Future<void> refreshAccess() async {
    if (!enabled || _clientId.isEmpty || _api == null) return;
    _loading = true;
    notifyListeners();
    try {
      final access = await _api.getAccess(_clientId);
      _access = access;
      _message = null;
      await _adService.updatePlan(
        adsAllowed: access.adsEnabled,
        policy: access.adPolicy,
      );
    } on Object {
      // The Worker remains the authority; stale data never grants an AI scan.
      _message = 'Could not refresh scan access.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> onScanCompleted() async {
    _completedScanCount += 1;
    if (_completedScanCount % _access.adPolicy.interstitialEvery == 0) {
      _pendingInterstitialScanCount = _completedScanCount;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_completedScanCountKey, _completedScanCount);
    } on Object {
      // Continue with this session's cadence if persistence is unavailable.
    }
    await refreshAccess();
  }

  /// Full-screen ads wait until the user closes the result, which is the
  /// natural transition back to app content. Multiple scans started from the
  /// same result route are still counted individually.
  Future<void> onResultScreenClosed() async {
    final qualifyingCount = _pendingInterstitialScanCount;
    if (qualifyingCount == null) return;
    final shown = await _adService.showInterstitialAfterScan(qualifyingCount);
    if (shown) _pendingInterstitialScanCount = null;
  }

  Future<bool> waitForOnboardingInterstitial({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await initialize();
    if (!_access.isAuthoritative && enabled) await refreshAccess();
    if (!_access.adsEnabled) return false;
    return _adService.waitForInterstitial(timeout: timeout);
  }

  Future<bool> showOnboardingInterstitial() {
    if (!_access.adsEnabled) return Future<bool>.value(false);
    return _adService.showOnboardingInterstitial();
  }

  Future<bool> showDrawerModeInterstitial({required bool aiScan}) async {
    await initialize();
    if (!_access.adsEnabled) return false;
    final ready = await _adService.waitForInterstitial(
      timeout: const Duration(milliseconds: 900),
    );
    if (!ready) return false;
    return _adService.showDrawerModeInterstitial(aiScan: aiScan);
  }

  Future<bool> watchAdForScan() async {
    if (_rewardActionBusy || _reconcilingRewards) return false;

    // Recover a locally earned reward before asking the user to spend time on
    // another ad.
    if (_rewardAttempts.isNotEmpty && await reconcileRewardAttempts()) {
      return true;
    }
    if (!_access.adsEnabled) {
      _message = 'Ads are unavailable. Your existing scans are still safe.';
      notifyListeners();
      return false;
    }
    if (!_access.canEarnReward) {
      _message =
          'You can hold up to ${_access.rewardBalanceCap} rewarded scans.';
      notifyListeners();
      return false;
    }
    if (rewardStartBlocked) {
      _message = 'Please wait before starting another rewarded ad.';
      notifyListeners();
      return false;
    }
    if (!_adService.rewardedReady) {
      _message = 'A rewarded ad is not ready. Try again shortly.';
      notifyListeners();
      return false;
    }
    final api = _api;
    if (api == null || _clientId.isEmpty) return false;

    final attempt = PendingRewardAttempt(
      attemptId: RewardAttemptId.create(),
      createdAt: _now(),
    );
    _rewardAttempts = [..._rewardAttempts, attempt];
    _lastRewardAdStartedAt = attempt.createdAt;
    _rewardActionBusy = true;
    _rewardFlowState = RewardFlowState.starting;
    _message = 'Starting the rewarded ad…';
    await _persistRewardState();
    notifyListeners();

    Future<bool>? earnedAcknowledgement;
    try {
      final started = await api.recordRewardAttempt(
        clientId: _clientId,
        attemptId: attempt.attemptId,
        event: RewardAttemptEvent.started,
      );
      if (started.state == RewardAttemptServerState.verified) {
        return await _finalizeVerified(attempt.attemptId);
      }
      if (started.state != RewardAttemptServerState.pending) {
        await _finalizeTerminal(attempt.attemptId, started.state);
        return false;
      }

      _rewardFlowState = RewardFlowState.showingAd;
      _message = 'Rewarded ad started.';
      notifyListeners();
      final earned = await _adService.showRewarded(
        onClientEarned: () {
          earnedAcknowledgement ??= _acknowledgeClientEarned(attempt.attemptId);
        },
      );
      if (!earned) {
        final acknowledgement = earnedAcknowledgement;
        if (acknowledgement != null) return await acknowledgement;
        final active = _findAttempt(attempt.attemptId);
        if (active?.clientEarned == true) {
          return await (earnedAcknowledgement ??= _acknowledgeClientEarned(
            attempt.attemptId,
          ));
        }
        await _removeRewardAttempt(attempt.attemptId);
        _rewardFlowState = RewardFlowState.failed;
        _message = 'The ad ended before a reward was earned.';
        return false;
      }

      return await (earnedAcknowledgement ??= _acknowledgeClientEarned(
        attempt.attemptId,
      ));
    } on Object catch (error) {
      final acknowledgement = earnedAcknowledgement;
      if (acknowledgement != null) return await acknowledgement;
      final active = _findAttempt(attempt.attemptId);
      if (active?.clientEarned == true) {
        return await (earnedAcknowledgement ??= _acknowledgeClientEarned(
          attempt.attemptId,
        ));
      } else {
        await _removeRewardAttempt(attempt.attemptId);
        _rewardFlowState = RewardFlowState.failed;
        _message = error is MonetizationApiException && error.statusCode == 429
            ? 'Please wait before starting another rewarded ad.'
            : 'The rewarded ad could not start.';
      }
      return false;
    } finally {
      _rewardActionBusy = false;
      notifyListeners();
    }
  }

  Future<bool> _acknowledgeClientEarned(String attemptId) async {
    final index = _rewardAttempts.indexWhere(
      (attempt) => attempt.attemptId == attemptId,
    );
    if (index < 0) return false;
    if (!_rewardAttempts[index].clientEarned) {
      _rewardAttempts = [..._rewardAttempts]
        ..[index] = _rewardAttempts[index].copyWith(clientEarned: true);
      await _persistRewardState();
    }
    _rewardFlowState = RewardFlowState.verifying;
    _message = 'Ad completed. Adding your scan…';
    notifyListeners();
    final api = _api;
    if (api == null) {
      await _markRewardSyncPending();
      return false;
    }
    try {
      final status = await api
          .recordRewardAttempt(
            clientId: _clientId,
            attemptId: attemptId,
            event: RewardAttemptEvent.clientEarned,
          )
          .timeout(_reconcileRequestLimit);
      if (status.state == RewardAttemptServerState.verified) {
        return _finalizeVerified(attemptId);
      }
      if (status.state != RewardAttemptServerState.pending) {
        await _finalizeTerminal(attemptId, status.state);
        return false;
      }
    } on MonetizationApiException catch (error) {
      if (error.statusCode == 404) {
        await _removeRewardAttempt(attemptId);
        _rewardFlowState = RewardFlowState.failed;
        _message = 'This reward attempt could not be found.';
        notifyListeners();
        return false;
      }
      if (error.statusCode == 409) {
        await _markRewardSyncPending(
          message:
              'Your rewarded scan balance is full. This earned scan is saved '
              'and will retry after you use one.',
        );
        return false;
      }
      // The earned callback is persisted before this request. Retrying the
      // same exact attempt ID is idempotent and cannot add a second scan.
    } on Object {
      // The earned callback is persisted before this request. Retrying the
      // same exact attempt ID is idempotent and cannot add a second scan.
    }
    await _markRewardSyncPending();
    return false;
  }

  Future<void> _markRewardSyncPending({String? message}) async {
    _rewardFlowState = RewardFlowState.pending;
    _message =
        message ??
        'Your ad was completed. Scan credit sync is pending and will retry '
            'automatically for 24 hours.';
    await _persistRewardState();
    notifyListeners();
  }

  /// Reconciles only locally earned, exact attempt IDs. A lost response is
  /// recovered with GET first; a still-pending attempt retries the idempotent
  /// client-earned acknowledgement.
  Future<bool> reconcileRewardAttempts() async {
    if (_reconcilingRewards || _rewardActionBusy) return false;
    final api = _api;
    if (api == null || _clientId.isEmpty) return false;

    final expiredLocally = _pruneExpiredRewardAttempts();
    if (_rewardAttempts.isEmpty) {
      if (expiredLocally) await _persistRewardState();
      if (_rewardFlowState == RewardFlowState.pending) {
        _rewardFlowState = RewardFlowState.idle;
        notifyListeners();
      }
      return false;
    }

    _reconcilingRewards = true;
    _rewardFlowState = RewardFlowState.verifying;
    notifyListeners();
    var credited = false;
    var terminalFailure = false;
    var balanceFull = false;
    try {
      for (final attempt in List<PendingRewardAttempt>.from(_rewardAttempts)) {
        if (!attempt.clientEarned) {
          _removeRewardAttemptInMemory(attempt.attemptId);
          continue;
        }
        try {
          var status = await api
              .getRewardAttempt(
                clientId: _clientId,
                attemptId: attempt.attemptId,
              )
              .timeout(_reconcileRequestLimit);
          if (status.state == RewardAttemptServerState.pending) {
            status = await api
                .recordRewardAttempt(
                  clientId: _clientId,
                  attemptId: attempt.attemptId,
                  event: RewardAttemptEvent.clientEarned,
                )
                .timeout(_reconcileRequestLimit);
          }
          switch (status.state) {
            case RewardAttemptServerState.pending:
              break;
            case RewardAttemptServerState.verified:
              _removeRewardAttemptInMemory(attempt.attemptId);
              credited = true;
              break;
            case RewardAttemptServerState.rejected:
            case RewardAttemptServerState.expired:
              _removeRewardAttemptInMemory(attempt.attemptId);
              terminalFailure = true;
              break;
          }
        } on MonetizationApiException catch (error) {
          if (error.statusCode == 404) {
            _removeRewardAttemptInMemory(attempt.attemptId);
            terminalFailure = true;
          } else if (error.statusCode == 409) {
            balanceFull = true;
          }
        } on Object {
          // Keep an earned attempt for a later launch/resume when the network
          // is available.
        }
      }
      await _persistRewardState();
      if (credited) {
        await refreshAccess();
        _rewardFlowState = RewardFlowState.verified;
        _message = 'One scan was added.';
      } else if (_rewardAttempts.isNotEmpty) {
        _rewardFlowState = RewardFlowState.pending;
        _message = balanceFull
            ? 'Your rewarded scan balance is full. This earned scan is saved '
                  'and will retry after you use one.'
            : 'Scan credit sync is pending. It is safe to close this screen.';
      } else if (terminalFailure || expiredLocally) {
        _rewardFlowState = RewardFlowState.failed;
        _message = 'A reward attempt expired before a scan could be added.';
      } else {
        _rewardFlowState = RewardFlowState.idle;
      }
      return credited;
    } finally {
      _reconcilingRewards = false;
      notifyListeners();
    }
  }

  Future<bool> _finalizeVerified(String attemptId) async {
    await _removeRewardAttempt(attemptId);
    await refreshAccess();
    _rewardFlowState = RewardFlowState.verified;
    _message = 'One scan was added.';
    notifyListeners();
    return true;
  }

  Future<void> _finalizeTerminal(
    String attemptId,
    RewardAttemptServerState state,
  ) async {
    await _removeRewardAttempt(attemptId);
    _rewardFlowState = RewardFlowState.failed;
    _message = state == RewardAttemptServerState.expired
        ? 'This reward expired before a scan could be added.'
        : 'This reward could not be credited. No scan was added.';
    notifyListeners();
  }

  PendingRewardAttempt? _findAttempt(String attemptId) {
    for (final attempt in _rewardAttempts) {
      if (attempt.attemptId == attemptId) return attempt;
    }
    return null;
  }

  Future<void> _removeRewardAttempt(String attemptId) async {
    _removeRewardAttemptInMemory(attemptId);
    await _persistRewardState();
  }

  void _removeRewardAttemptInMemory(String attemptId) {
    _rewardAttempts = _rewardAttempts
        .where((attempt) => attempt.attemptId != attemptId)
        .toList();
  }

  void _restoreRewardState(String? encoded) {
    if (encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      final json = Map<String, Object?>.from(decoded);
      final lastStartedAtMs = json['lastStartedAtMs'];
      _lastRewardAdStartedAt = lastStartedAtMs is num
          ? DateTime.fromMillisecondsSinceEpoch(lastStartedAtMs.toInt())
          : null;
      final attempts = json['attempts'];
      if (attempts is List) {
        _rewardAttempts = attempts
            .whereType<Map>()
            .map(
              (item) => PendingRewardAttempt.fromJson(
                Map<String, Object?>.from(item),
              ),
            )
            .toList();
      }
      final beforeEarnedFilter = _rewardAttempts.length;
      _rewardAttempts = _rewardAttempts
          .where((attempt) => attempt.clientEarned)
          .toList();
      _rewardStateNeedsPersist =
          _pruneExpiredRewardAttempts() ||
          beforeEarnedFilter != _rewardAttempts.length;
      if (_rewardAttempts.isNotEmpty) {
        _rewardFlowState = RewardFlowState.pending;
      }
    } on Object {
      _rewardAttempts = [];
      _lastRewardAdStartedAt = null;
    }
  }

  bool _pruneExpiredRewardAttempts() {
    final before = _rewardAttempts.length;
    final now = _now();
    _rewardAttempts = _rewardAttempts.where((attempt) {
      final age = now.difference(attempt.createdAt);
      return age.isNegative || age < _rewardAttemptLifetime;
    }).toList();
    return before != _rewardAttempts.length;
  }

  Future<void> _persistRewardState() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _rewardStateKey,
        jsonEncode({
          'lastStartedAtMs': _lastRewardAdStartedAt?.millisecondsSinceEpoch,
          'attempts': _rewardAttempts
              .map((attempt) => attempt.toJson())
              .toList(),
        }),
      );
    } on Object {
      // Server state remains authoritative if local persistence is unavailable.
    }
  }

  Future<void> handleAppResumed(Duration backgroundTime) async {
    await reconcileRewardAttempts();
    if (backgroundTime <
        Duration(seconds: _access.adPolicy.appOpenCooldownSeconds)) {
      return;
    }
    await _adService.showAppOpenAfterLongBackground(backgroundTime);
  }

  void reportPaidAd(
    String placement,
    double valueMicros,
    PrecisionType precision,
    String currencyCode,
  ) {
    final api = _api;
    if (api == null || _clientId.isEmpty) return;
    unawaited(
      api
          .reportAdRevenue(
            clientId: _clientId,
            placement: placement,
            valueMicros: valueMicros,
            precision: precision.name,
            currencyCode: currencyCode,
          )
          .onError((_, _) {}),
    );
  }

  Future<void> showPrivacyOptions() async {
    await _adService.showPrivacyOptions();
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }
}
