import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_header.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_highlights_section.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_activity/asset_activity_summary_section.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/expanding_glass_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Opens the activity sheet of [asset].
///
/// The sheet grows out of the nearest [GlassSheetOrigin] above [context],
/// for example the tapped holding row, and floats above the bottom edge of
/// the screen (see [showExpandingGlassSheet]).
Future<void> showAssetActivitySheet(
  BuildContext context, {
  required Asset asset,
}) {
  return showExpandingGlassSheet<void>(
    context,
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
    builder: (_) => AssetActivitySheet(asset: asset),
  );
}

/// Floating glass sheet with the activity of one asset: the balance and
/// its market price, the received, sent, and transaction totals, and the
/// highlights of the history.
///
/// A custody view built from local data (transactions, balances, prices),
/// without investment framing: no ROI, profit, cost basis, or performance.
/// The content scrolls when it does not fit.
///
/// The widget is the sheet content. [showAssetActivitySheet] puts it on
/// the glass.
class AssetActivitySheet extends StatelessWidget {
  const AssetActivitySheet({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSheetHeader(
          title: asset.name,
          subtitle: asset.ticker,
          leading: ExcludeSemantics(
            child: SvgPicture.asset(asset.iconPath, width: 36, height: 36),
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AssetActivityHeader(asset: asset),
                const SizedBox(height: 20),
                AssetSummarySection(asset: asset),
                const SizedBox(height: 20),
                AssetHighlightsSection(asset: asset),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
