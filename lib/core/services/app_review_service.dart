import 'package:in_app_review/in_app_review.dart';

/// Small boundary around Google Play's native in-app review flow.
///
/// The platform controls whether the review card is actually displayed. A
/// missing Play Store, review quota, or plugin error must never block entry to
/// the app.
abstract interface class AppReviewService {
  Future<bool> requestReview();
}

class PlayAppReviewService implements AppReviewService {
  PlayAppReviewService({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> requestReview() async {
    try {
      if (!await _inAppReview.isAvailable()) return false;
      await _inAppReview.requestReview();
      return true;
    } on Object {
      return false;
    }
  }
}
