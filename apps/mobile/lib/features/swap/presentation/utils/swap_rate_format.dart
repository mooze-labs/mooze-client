import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// What one unit of the asset sent buys of [receive], in the unit of
/// [receive] ([Asset.displayUnit]): "244" in "1 Depix = 244 SATS".
///
/// [rate] is the amount received per base unit sent. The assets of a swap
/// all have 8 decimals, so one unit sent buys [rate] units of [receive],
/// or [rate] × 10⁸ sats. Bitcoin shows in whole sats, as the amounts of
/// the deal card: 1 Depix buys 244 sats reads better than 0.00000244
/// L-BTC. The swap screen and the confirm sheet both use it.
String formatSwapRate(
  double rate, {
  required Asset receive,
  required String locale,
}) {
  if (receive == Asset.btc || receive == Asset.lbtc) {
    return NumberFormat('#,##0', locale).format(rate * 100000000);
  }
  // Small rates need many decimals to be useful, large ones only a couple.
  final String pattern;
  if (rate < 0.0001) {
    pattern = '#,##0.########';
  } else if (rate < 1) {
    pattern = '#,##0.######';
  } else if (rate < 1000) {
    pattern = '#,##0.####';
  } else {
    pattern = '#,##0.##';
  }
  return NumberFormat(pattern, locale).format(rate);
}
