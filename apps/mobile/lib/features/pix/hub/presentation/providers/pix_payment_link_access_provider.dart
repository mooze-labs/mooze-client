import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

/// Lowest wallet level that creates payment links: Silver. Bronze is 0.
const int pixPaymentLinkMinLevel = 1;

/// True when the account is below [pixPaymentLinkMinLevel], so it cannot
/// create payment links. The hub and the merchant mode then show why.
///
/// While the levels load, or after they fail, the app cannot tell, so
/// nothing is locked: the API answers INELIGIBLE to an account below the
/// level. A refresh keeps the last known level, so the screen does not
/// flicker.
final pixPaymentLinkLockedProvider = Provider.autoDispose<bool>((ref) {
  final level = ref.watch(levelsProvider).valueOrNull?.spendingLevel;
  return level != null && level < pixPaymentLinkMinLevel;
});
