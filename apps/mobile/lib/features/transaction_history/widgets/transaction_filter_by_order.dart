import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class FilterOrderBy extends StatefulWidget {
  final bool isMostRecentSelected;
  final ValueChanged<bool> onSelectionChanged;

  const FilterOrderBy({
    super.key,
    required this.isMostRecentSelected,
    required this.onSelectionChanged,
  });

  @override
  State<FilterOrderBy> createState() => _FilterOrderByState();
}

class _FilterOrderByState extends State<FilterOrderBy> {
  late bool _isMostRecentSelected;

  @override
  void initState() {
    super.initState();
    _isMostRecentSelected = widget.isMostRecentSelected;
  }

  void _updateSelection(bool isMostRecent) {
    setState(() {
      _isMostRecentSelected = isMostRecent;
    });
    widget.onSelectionChanged(_isMostRecentSelected);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _OrderSegments(
            mostRecent: _isMostRecentSelected,
            mostRecentLabel: t.tx_filter_most_recent,
            oldestLabel: t.tx_filter_oldest,
            onChanged: _updateSelection,
          ),
        ),
        const SizedBox(width: 8),
        // Flips the order, as the arrows between the two choices did.
        Semantics(
          button: true,
          child: SizedBox.square(
            dimension: _OrderSegments.height,
            child: Material(
              type: MaterialType.transparency,
              shape: CircleBorder(
                side: BorderSide(color: AppSurfaces.hairline(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _updateSelection(!_isMostRecentSelected);
                },
                child: Icon(
                  Icons.swap_vert_rounded,
                  size: 22,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two-segment choice of the order. A glass lens slides under the selected
/// segment.
class _OrderSegments extends StatelessWidget {
  const _OrderSegments({
    required this.mostRecent,
    required this.mostRecentLabel,
    required this.oldestLabel,
    required this.onChanged,
  });

  final bool mostRecent;
  final String mostRecentLabel;
  final String oldestLabel;
  final ValueChanged<bool> onChanged;

  static const double height = 48;
  static const double _inset = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(color: AppSurfaces.hairline(context)),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: Motion.of(context, Motion.durationEmphasis),
              curve: Motion.curveMove,
              alignment: mostRecent
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: const FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: Padding(
                  padding: EdgeInsets.all(_inset),
                  child: GlassLens(),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _OrderSegment(
                  label: mostRecentLabel,
                  selected: mostRecent,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _OrderSegment(
                  label: oldestLabel,
                  selected: !mostRecent,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSegment extends StatelessWidget {
  const _OrderSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelLarge?.copyWith(
                color: selected ? colors.textPrimary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
