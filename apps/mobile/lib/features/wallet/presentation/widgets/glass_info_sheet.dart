import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Shows the floating glass sheet that [builder] returns.
///
/// The sheet opens over [Motion.durationSlow] and closes over
/// [Motion.durationExit]. With reduced motion, it opens and closes at once.
/// It opens on the root navigator, so it also covers the floating
/// navigation bar.
Future<T?> showFloatingGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final reduced = Motion.isReduced(context);
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: AnimationStyle(
      duration: reduced ? Duration.zero : Motion.durationSlow,
      reverseDuration: reduced ? Duration.zero : Motion.durationExit,
      curve: Motion.curveEnter,
      reverseCurve: Motion.curveExit,
    ),
    builder: builder,
  );
}

/// Top of a floating glass sheet: the drag handle, the title, and a close
/// button.
///
/// Put it in a [GlassSheet] with an 8 pt side padding. The title then
/// starts 20 pt from the edge of the glass, as the sheet content does.
class GlassSheetHeader extends StatelessWidget {
  const GlassSheetHeader({super.key, required this.title});

  final String title;

  /// Largest text scale of the title.
  static const double _maxTitleScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  // As with the large screen titles, the title grows with
                  // the system text size up to 150%. Above that, a long
                  // word breaks inside the word on a narrow screen.
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: _maxTitleScale),
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: t.common_close,
              onPressed: () => Navigator.of(context).pop(),
              icon: PixIcon(
                PixIcons.close,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One step of a [GlassInfoSheet]: a short title and its description.
typedef GlassInfoStep = (String title, String description);

/// Shows a [GlassInfoSheet] with [showFloatingGlassSheet].
Future<void> showGlassInfoSheet(
  BuildContext context, {
  required String title,
  required List<GlassInfoStep> steps,
  String? hint,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return showFloatingGlassSheet<void>(
    context,
    builder: (_) => GlassInfoSheet(
      title: title,
      steps: steps,
      hint: hint,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}

/// Floating glass sheet that explains a screen in numbered steps.
///
/// Below the steps, it can show a hint and one action. The steps scroll
/// when they do not fit, and the action stays visible. A tap on the action
/// closes the sheet first and then runs [onAction].
class GlassInfoSheet extends StatelessWidget {
  const GlassInfoSheet({
    super.key,
    required this.title,
    required this.steps,
    this.hint,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'Give both actionLabel and onAction, or neither',
       );

  final String title;
  final List<GlassInfoStep> steps;

  /// Short note below the steps, with an info icon.
  final String? hint;

  /// Label of the action button. Null hides the button.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(title: title),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    _InfoStep(
                      index: i + 1,
                      title: steps[i].$1,
                      description: steps[i].$2,
                    ),
                    if (i < steps.length - 1) const SizedBox(height: 16),
                  ],
                  if (hint case final hint?) ...[
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: PixIcon(
                            PixIcons.info,
                            size: 16,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hint,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (actionLabel case final label?) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PrimaryButton(
                text: label,
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction!();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One numbered step. The number sits in a neutral glass lens.
class _InfoStep extends StatelessWidget {
  final int index;
  final String title;
  final String description;

  const _InfoStep({
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlassStyle.of(context).lensFill,
              border: Border.all(color: AppSurfaces.hairline(context)),
            ),
            child: Text(
              '$index',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
