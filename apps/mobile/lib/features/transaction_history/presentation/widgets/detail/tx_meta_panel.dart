import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One short fact of the metadata grid, such as the date or the fee.
class MetaCell {
  final String label;
  final String value;

  /// Optional icon before the value, such as the asset coin.
  final Widget? leading;

  /// Takes a whole row of the grid, for a value too long for half of it,
  /// such as the date and time.
  final bool wide;

  const MetaCell(this.label, this.value, {this.leading, this.wide = false});
}

/// The metadata of a transaction in one glass panel, in three bands:
///
/// 1. A two-column grid of short facts, label above value. Short values
///    share a line, so the panel stays compact.
/// 2. The long identifiers (transaction IDs, invoice, preimage), one per
///    row, each with a copy button.
/// 3. The links that leave the app, such as the block explorer.
///
/// Hairlines separate the bands, not the cells: space groups the grid.
class TxMetaPanel extends StatelessWidget {
  const TxMetaPanel({
    super.key,
    required this.cells,
    this.ids = const [],
    this.links = const [],
  });

  final List<MetaCell> cells;

  /// Rows of long identifiers, usually [DetailRow]s with copy.
  final List<Widget> ids;

  /// Link rows, usually [InCardActionButton]s.
  final List<Widget> links;

  /// Space between the panel edge and the content.
  static const double padding = 16;

  /// Text scale from which the grid uses one column.
  static const double _singleColumnTextScale = 1.6;

  @override
  Widget build(BuildContext context) {
    final hairline = AppSurfaces.hairline(context);
    final divider = Divider(height: 1, thickness: 1, color: hairline);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final columns = textScale >= _singleColumnTextScale ? 1 : 2;

    final bands = <Widget>[
      if (cells.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(padding, 16, padding, 4),
          child: _Grid(cells: cells, columns: columns),
        ),
      if (ids.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < ids.length; i++) ...[
                if (i > 0) divider,
                ids[i],
              ],
            ],
          ),
        ),
      if (links.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < links.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: InCardActionButton.textInset,
                  color: hairline,
                ),
              links[i],
            ],
          ],
        ),
    ];

    return GlassPanel(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < bands.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: padding),
                child: divider,
              ),
            bands[i],
          ],
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.cells, required this.columns});

  final List<MetaCell> cells;
  final int columns;

  @override
  Widget build(BuildContext context) {
    // A wide cell closes the current row and takes one of its own.
    final rows = <List<MetaCell>>[];
    var current = <MetaCell>[];
    for (final cell in cells) {
      if (cell.wide) {
        if (current.isNotEmpty) rows.add(current);
        rows.add([cell]);
        current = [];
        continue;
      }
      current.add(cell);
      if (current.length == columns) {
        rows.add(current);
        current = [];
      }
    }
    if (current.isNotEmpty) rows.add(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.length == 1 && row.first.wide)
                  Expanded(child: _Cell(cell: row.first))
                else
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: 16),
                    Expanded(
                      child: col < row.length
                          ? _Cell(cell: row[col])
                          : const SizedBox.shrink(),
                    ),
                  ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell});

  final MetaCell cell;

  @override
  Widget build(BuildContext context) {
    final value = Text(
      cell.value,
      style: detailValueStyle(context)?.copyWith(height: 1.3),
    );
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cell.label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (cell.leading == null)
            value
          else
            Row(
              children: [
                ExcludeSemantics(child: cell.leading!),
                const SizedBox(width: 6),
                Flexible(child: value),
              ],
            ),
        ],
      ),
    );
  }
}
