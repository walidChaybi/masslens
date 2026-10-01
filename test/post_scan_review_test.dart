import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/services/app_review_service.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/monetization/application/monetization_controller.dart';
import 'package:mass_lens/features/monetization/data/app_ad_service.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('post-scan review is requested once at the 3rd scan', () async {
    final review = _FakeAppReviewService();
    final adService = AppAdService.forTesting(
      interstitialAdLoader: (_) async => null,
    );
    addTearDown(adService.dispose);

    final monetization = MonetizationController.forTesting(
      api: _AdsEnabledApi(),
      adService: adService,
    );
    // Disposed by AppController.

    await monetization.initialize();
    final appController = AppController(
      measurementStore: const _FakeMeasurementStore(),
      monetizationController: monetization,
      appReviewService: review,
      postScanReviewRequested: false,
    );
    addTearDown(appController.dispose);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mass_lens.post_scan_review_requested'), isNull);

    await monetization.onScanCompleted();
    await monetization.onScanCompleted();
    await monetization.onScanCompleted();

    expect(monetization.completedScanCount, 3);

    await appController.maybeRequestPostScanReview();
    expect(review.requestCount, 1);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'mass_lens.post_scan_review_requested',
      ),
      isTrue,
    );

    // A second call must be ignored and never request again.
    await appController.maybeRequestPostScanReview();
    expect(review.requestCount, 1);
  });
}

class _FakeMeasurementStore extends MeasurementStore {
  const _FakeMeasurementStore();
}

class _FakeAppReviewService implements AppReviewService {
  int requestCount = 0;

  @override
  Future<bool> requestReview() async {
    requestCount += 1;
    return true;
  }
}

class _AdsEnabledApi extends MonetizationApi {
  _AdsEnabledApi() : super(apiUrl: 'https://example.invalid');

  @override
  Future<AccessStatus> getAccess(String clientId) async => const AccessStatus(
    starterScansRemaining: 2,
    rewardedScans: 0,
    legacyScans: 0,
    remainingScans: 2,
    rewardBalanceCap: 3,
    hasLifetime: false,
    scanAccessEnforced: true,
    adsEnabled: true,
    isAuthoritative: true,
    analysisModel: 'gpt-5-nano',
    adPolicy: AdPolicy(),
  );
}
