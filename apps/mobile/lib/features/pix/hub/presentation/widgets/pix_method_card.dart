import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Standalone glass card used by the method list of the send flow.
///
/// Each option sits on its own card so the choices read as a stack of
/// equal, tappable blocks. A press scales the card down a little.
class PixMethodCard extends StatelessWidget {
  final PixIconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  /// Short facts shown as chips below [description], to help a quick choice.
  final List<String> tags;

  const PixMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: PressScale(
        child: GlassPanel(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  PixIconWell(icon: icon, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [for (final tag in tags) PixTag(tag)],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  PixIcon(
                    PixIcons.chevronRight,
                    size: 18,
                    color: context.colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short neutral fact, such as "Instant" or "No fee".
///
/// Tags inform. They are not actions, so they stay neutral and leave the
/// brand color to the main action.
class PixTag extends StatelessWidget {
  const PixTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Selectable row used by the key type list.
///
/// The selected row has a brand border and a check, so the selection never
/// depends on color alone.
class PixOptionRow extends StatelessWidget {
  final PixIconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PixOptionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primaryColor;
    const radius = BorderRadius.all(Radius.circular(16));
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GlassPanel(
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? primary : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  PixIconWell(
                    icon: icon,
                    size: 36,
                    tone: isSelected ? PixTone.brand : PixTone.neutral,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    PixIcon(PixIcons.check, size: 18, color: primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
