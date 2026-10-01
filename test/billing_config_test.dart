import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/monetization/data/billing_config.dart';

void main() {
  test('only the lifetime product is offered and recognized', () {
    expect(BillingConfig.allProductIds, {'masslens_lifetime_unlimited'});
    expect(
      BillingConfig.isLifetimeProductId('masslens_lifetime_unlimited'),
      isTrue,
    );
    for (final percent in [30, 40, 50, 60, 70, 80, 90]) {
      expect(
        BillingConfig.isLifetimeProductId('masslens_lifetime_off_$percent'),
        isFalse,
      );
    }
    expect(BillingConfig.isLifetimeProductId('coins_pack'), isFalse);
  });
}
