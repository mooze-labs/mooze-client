import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One row of a [PixOperationList].
class PixOperationItem {
  final PixIconData icon;
  final String label;
  final VoidCallback onTap;

  const PixOperationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Compact list of operations in one glass panel, split by inset hairlines.
///
/// The panel is the same Liquid Glass group as the settings and the wallet
/// lists. The icons sit in neutral wells, so the brand color stays on the
/// main actions above the list.
class PixOperationList extends StatelessWidget {
  final List<PixOperationItem> items;

  const PixOperationList({super.key, required this.items});

  static const double _rowInset = 14;
  static const double _iconWellSize = 36;
  static const double _iconGap = 14;

  /// Distance from the panel edge to the label. Dividers start here.
  static const double textInset = _rowInset + _iconWellSize + _iconGap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                // The divider starts at the label, as in the platform lists.
                indent: textInset,
                color: AppSurfaces.hairline(context),
              ),
            _PixOperationRow(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _PixOperationRow extends StatelessWidget {
  final PixOperationItem item;

  const _PixOperationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      onTap: item.onTap,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PixOperationList._rowInset,
            vertical: 10,
          ),
          child: Row(
            children: [
              PixIconWell(
                icon: item.icon,
                size: PixOperationList._iconWellSize,
              ),
              const SizedBox(width: PixOperationList._iconGap),
              Expanded(
                child: Text(
                  item.label,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PixIcon(
                PixIcons.chevronRight,
                size: 18,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
