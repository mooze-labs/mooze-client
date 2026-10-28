import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The wallet action row: Send, Receive, Swap, and an optional More.
///
/// Each action is a 48 pt Liquid Glass circle with a label below it. A
/// press scales the circle with [PressScale]. The row does not use haptics.
/// The home screen shows all four actions. The holdings screen leaves out
/// More.
class HomeActionRow extends StatelessWidget {
  const HomeActionRow({
    super.key,
    required this.onSend,
    required this.onReceive,
    required this.onSwap,
    this.onMore,
  });

  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onSwap;

  /// Opens more actions. Null hides the More button.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: HomeActionButton(
            svgAsset: 'assets/icons/menu/send.svg',
            label: t.wallet_holding_action_send,
            onPressed: onSend,
          ),
        ),
        Expanded(
          child: HomeActionButton(
            svgAsset: 'assets/icons/menu/receive.svg',
            label: t.wallet_holding_action_receive,
            onPressed: onReceive,
          ),
        ),
        Expanded(
          child: HomeActionButton(
            svgAsset: 'assets/icons/menu/swap.svg',
            label: t.wallet_holding_action_swap,
            onPressed: onSwap,
          ),
        ),
        if (onMore case final onMore?)
          Expanded(
            child: HomeActionButton(
              icon: Icons.more_horiz,
              label: t.wallet_action_more,
              onPressed: onMore,
            ),
          ),
      ],
    );
  }
}

/// A Liquid Glass circle action button with a label below it.
class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    super.key,
    this.svgAsset,
    this.icon,
    required this.label,
    required this.onPressed,
  }) : assert(
         svgAsset != null || icon != null,
         'Either svgAsset or icon must be provided',
       );

  static const double circleSize = 48;
  static const double iconSize = 24;

  final String? svgAsset;
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = context.colors.textPrimary;
    return MergeSemantics(
      child: Column(
        children: [
          PressScale(
            scale: Motion.pressScaleCircle,
            // The row sits on the fixed screen backdrop, so the glass needs
            // no backdrop blur (see LiquidGlass.blurBackdrop).
            child: LiquidGlass(
              blurBackdrop: false,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onPressed,
                  child: SizedBox.square(
                    dimension: circleSize,
                    child: Center(
                      child: svgAsset != null
                          ? SvgPicture.asset(
                              svgAsset!,
                              width: iconSize,
                              height: iconSize,
                              colorFilter: ColorFilter.mode(
                                foreground,
                                BlendMode.srcIn,
                              ),
                            )
                          : Icon(icon, size: iconSize, color: foreground),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // The label is part of the tap target, so a tap on the text also
          // runs the action.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// An entry of the More sheet.
class HomeMoreAction {
  const HomeMoreAction({
    required this.label,
    required this.onSelected,
    this.svgAsset,
    this.icon,
  });

  final String label;
  final VoidCallback onSelected;
  final String? svgAsset;
  final IconData? icon;
}

/// Opens the More sheet with [actions].
///
/// The sheet floats above the bottom edge of the screen (see
/// [showFloatingGlassSheet]). A tap on an entry closes the sheet first and
/// then runs the action.
Future<void> showHomeMoreSheet(
  BuildContext context, {
  required List<HomeMoreAction> actions,
}) {
  return showFloatingGlassSheet<void>(
    context,
    builder: (sheetContext) => _HomeMoreSheet(actions: actions),
  );
}

/// Floating glass sheet that lists the More actions.
class _HomeMoreSheet extends StatelessWidget {
  const _HomeMoreSheet({required this.actions});

  final List<HomeMoreAction> actions;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(title: t.wallet_more_sheet_title),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final action in actions)
                    _HomeMoreEntry(
                      action: action,
                      onTap: () {
                        Navigator.of(context).pop();
                        action.onSelected();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One entry of the More sheet: the icon in a neutral glass lens, the
/// label, and a chevron.
class _HomeMoreEntry extends StatelessWidget {
  const _HomeMoreEntry({required this.action, required this.onTap});

  final HomeMoreAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = context.colors.textPrimary;
    const radius = BorderRadius.all(Radius.circular(16));

    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GlassStyle.of(context).lensFill,
                    border: Border.all(color: AppSurfaces.hairline(context)),
                  ),
                  child: action.svgAsset != null
                      ? SvgPicture.asset(
                          action.svgAsset!,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            foreground,
                            BlendMode.srcIn,
                          ),
                        )
                      : Icon(action.icon, size: 20, color: foreground),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    action.label,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PixIcon(
                  PixIcons.chevronRight,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
