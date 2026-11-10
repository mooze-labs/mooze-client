import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/services/price_service.dart';

/// A period of the market chart and the price history it loads.
enum MarketPeriod {
  day(
    label: '1D',
    interval: KlineInterval.oneHour,
    step: Duration(hours: 1),
    days: 1,
    freshFor: Duration(minutes: 5),
  ),
  week(
    label: '7D',
    interval: KlineInterval.fourHours,
    step: Duration(hours: 4),
    days: 7,
    freshFor: Duration(minutes: 30),
  ),
  month(
    label: '1M',
    interval: KlineInterval.oneDay,
    step: Duration(days: 1),
    days: 30,
    freshFor: Duration(hours: 2),
  );

  const MarketPeriod({
    required this.label,
    required this.interval,
    required this.step,
    required this.days,
    required this.freshFor,
  });

  /// Short label of the selector, for example "7D".
  final String label;

  /// Time between two points of the history.
  final KlineInterval interval;

  /// [interval] as a [Duration].
  final Duration step;

  /// Length of the history in days.
  final int days;

  /// Age up to which a cached history counts as fresh. A prefetch skips a
  /// fresh history. The shortest period has the shortest window, because
  /// its points move the most.
  final Duration freshFor;

  /// Returns the history parameters of [asset] for this period.
  AssetPriceHistoryParams paramsFor(Asset asset) => AssetPriceHistoryParams(
    asset: asset,
    interval: interval,
    periodInDays: days,
  );

  /// Returns the spoken name, for example "7 days".
  String spokenName(AppLocalizations t) => switch (this) {
    MarketPeriod.day => t.wallet_asset_period_day,
    MarketPeriod.week => t.wallet_asset_period_week,
    MarketPeriod.month => t.wallet_asset_period_month,
  };
}
