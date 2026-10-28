import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/network_detection_provider.dart';

/// Tabular figures, so the digits of amounts line up.
const sendTabularFigures = [FontFeature.tabularFigures()];

/// Page shell of the send flow screens.
///
/// It has the look of `PixScreenScaffold`: the shared backdrop behind a
/// clear app bar, a large title, a 20 pt gutter, and a main action pinned
/// above the keyboard. The content is a [Column] in a scroll view, so every
/// form part stays mounted while the user scrolls. Some parts load data when
/// they mount.
class SendFlowScaffold extends StatelessWidget {
  const SendFlowScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.appBarActions,
    this.bottomAction,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? appBarActions;

  /// Main action of the screen, pinned above the bottom edge.
  final Widget? bottomAction;

  static const double gutter = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(actions: appBarActions),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          // A tap outside a field closes the keyboard.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SendEntrance(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          8,
                          gutter,
                          bottomAction == null ? 32 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PixScreenTitle(title: title, subtitle: subtitle),
                            const SizedBox(height: 28),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                    if (bottomAction != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          gutter,
                          8,
                          gutter,
                          12,
                        ),
                        child: bottomAction!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page shell of a state screen of the send flow, for example "Preparing"
/// or an error.
///
/// The [status] sits in the middle of the backdrop. The optional
/// [bottomAction] stays pinned at the bottom.
class SendStatusScaffold extends StatelessWidget {
  const SendStatusScaffold({
    super.key,
    required this.status,
    this.bottomAction,
  });

  final Widget status;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const BackdropAppBar(),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: SendEntrance(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: status,
                      ),
                    ),
                  ),
                  if (bottomAction != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: bottomAction!,
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

/// Fades and raises [child] once, when it mounts.
///
/// The entrance takes [Motion.durationBase] and never blocks a tap. With
/// reduced motion, the content appears at once.
class SendEntrance extends StatefulWidget {
  const SendEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<SendEntrance> createState() => _SendEntranceState();
}

class _SendEntranceState extends State<SendEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(animation: _animation, child: widget.child);
  }
}

/// A short message about the form: a warning, an error, or a note.
///
/// The icon shape and the text carry the meaning. The tone color only
/// tints the box, so the message never depends on color alone.
class SendNotice extends StatelessWidget {
  const SendNotice({
    super.key,
    required this.icon,
    this.tone = PixTone.neutral,
    this.title,
    this.message,
    this.body,
    this.onTap,
    this.onDismiss,
    this.dismissTooltip,
  });

  final PixIconData icon;
  final PixTone tone;
  final String? title;
  final String? message;

  /// Extra content below [message], for example a list or an action.
  final Widget? body;

  /// Makes the whole notice a button.
  final VoidCallback? onTap;

  /// Adds a close button at the end of the notice.
  final VoidCallback? onDismiss;
  final String? dismissTooltip;

  @override
  Widget build(BuildContext context) {
    final color = pixToneColor(context, tone);
    final neutral = tone == PixTone.neutral;
    const radius = BorderRadius.all(Radius.circular(16));

    Widget content = Padding(
      padding: EdgeInsets.fromLTRB(14, 12, onDismiss == null ? 14 : 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PixIcon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (title != null && message != null) const SizedBox(height: 2),
                if (message != null)
                  Text(
                    message!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: title == null
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ?body,
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: dismissTooltip,
              visualDensity: VisualDensity.compact,
              icon: PixIcon(
                PixIcons.close,
                size: 16,
                color: context.colors.textSecondary,
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: radius, child: content);
    }

    return Semantics(
      container: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: neutral
                ? GlassStyle.of(context).lensFill
                : color.withValues(alpha: 0.10),
            border: Border.all(
              color: neutral
                  ? AppSurfaces.hairline(context)
                  : color.withValues(alpha: 0.30),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Small label above a form part, for example "Destination address".
class SendSectionLabel extends StatelessWidget {
  const SendSectionLabel(this.text, {super.key, this.active = false});

  final String text;

  /// Draws the label in the primary text color, for a focused field.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.labelLarge?.copyWith(
        color: active
            ? context.colors.textPrimary
            : context.colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The logo of [asset] in a round glass lens.
class SendAssetLogo extends StatelessWidget {
  const SendAssetLogo({super.key, required this.asset, this.size = 40});

  final Asset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GlassStyle.of(context).lensFill,
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: SvgPicture.asset(
        asset.iconPath,
        width: size * 0.62,
        height: size * 0.62,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// The network of an address as a small pill: an icon and a name.
///
/// An unknown network shows an alert icon and the error color.
class SendNetworkBadge extends StatelessWidget {
  const SendNetworkBadge({super.key, required this.network});

  final NetworkType network;

  /// Returns the name of [network].
  static String labelOf(AppLocalizations t, NetworkType network) =>
      switch (network) {
        NetworkType.bitcoin => t.wallet_send_network_bitcoin,
        NetworkType.liquid => t.wallet_send_network_liquid,
        NetworkType.unknown => t.wallet_send_network_unidentified,
      };

  /// Returns the icon of [network].
  static PixIconData iconOf(NetworkType network) => switch (network) {
    NetworkType.bitcoin => PixIcons.bitcoin,
    NetworkType.liquid => PixIcons.link,
    NetworkType.unknown => PixIcons.error,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final unknown = network == NetworkType.unknown;
    final negative = context.colors.negativeColor;
    final foreground = unknown ? negative : context.colors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: unknown
            ? negative.withValues(alpha: 0.10)
            : GlassStyle.of(context).lensFill,
        border: Border.all(
          color: unknown
              ? negative.withValues(alpha: 0.30)
              : AppSurfaces.hairline(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixIcon(
            iconOf(network),
            size: 14,
            color: unknown ? negative : context.colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              labelOf(t, network),
              style: context.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns [value] with its middle replaced by an ellipsis.
///
/// The first and the last [keep] characters stay, because users compare the
/// start and the end of an address.
String shortenMiddle(String value, {int keep = 10}) {
  if (value.length <= keep * 2 + 3) return value;
  return '${value.substring(0, keep)}…${value.substring(value.length - keep)}';
}

/// One line of a [SendSummaryPanel].
class SendSummaryRow {
  const SendSummaryRow({
    required this.label,
    required this.value,
    this.detail,
    this.highlight = false,
  });

  final String label;
  final String value;

  /// Optional quiet line below the value, for example its fiat value.
  final Widget? detail;

  /// Draws the value larger and bolder, for the total.
  final bool highlight;
}

/// Glass panel with the details of a send: label on the left, value on the
/// right, and a hairline between the rows.
class SendSummaryPanel extends StatelessWidget {
  const SendSummaryPanel({super.key, required this.rows});

  final List<SendSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppSurfaces.hairline(context),
                ),
              _SummaryLine(row: rows[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.row});

  final SendSummaryRow row;

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        (row.highlight
                ? context.textTheme.titleMedium
                : context.textTheme.bodyMedium)
            ?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: row.highlight ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: sendTabularFigures,
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                row.label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: row.highlight
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                  fontWeight: row.highlight ? FontWeight.w600 : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // The value side takes its share of the row, so the value ends
            // at the right edge.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(row.value, textAlign: TextAlign.end, style: valueStyle),
                  ?row.detail,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet line under a value, for example "≈ R$ 1,20".
class SendQuietText extends StatelessWidget {
  const SendQuietText(this.text, {super.key, this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        textAlign: textAlign,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
          fontFeatures: sendTabularFigures,
        ),
      ),
    );
  }
}

/// A hero amount: large digits with tabular figures and a muted unit.
///
/// The text shrinks to fit the width, so a long amount stays on one line.
class SendHeroAmount extends StatelessWidget {
  const SendHeroAmount({
    super.key,
    required this.digits,
    required this.unit,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final String digits;
  final String unit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: digits),
            if (unit.isNotEmpty)
              TextSpan(
                text: ' $unit',
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
        maxLines: 1,
        style: context.textTheme.headlineLarge?.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          fontFeatures: sendTabularFigures,
        ),
      ),
    );
  }
}

/// The destination of a send: the address and its network.
///
/// The address shows with its middle shortened. A tap shows the full
/// address, and a second tap shortens it again. Screen readers always read
/// the full address. The copy button sits at the end of the row.
class SendRecipient extends StatefulWidget {
  const SendRecipient({
    super.key,
    required this.label,
    required this.address,
    this.network,
  });

  final String label;
  final String address;
  final NetworkType? network;

  @override
  State<SendRecipient> createState() => _SendRecipientState();
}

class _SendRecipientState extends State<SendRecipient> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final address = widget.address;
    final shown = _expanded ? address : shortenMiddle(address);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SendSectionLabel(widget.label),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: widget.label,
                value: address,
                excludeSemantics: true,
                onTap: _toggle,
                child: InkWell(
                  onTap: _toggle,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizeFadeSwitcher(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        shown,
                        key: ValueKey(_expanded),
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.colors.textPrimary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SendCopyButton(value: address),
          ],
        ),
        if (widget.network != null) ...[
          const SizedBox(height: 4),
          SendNetworkBadge(network: widget.network!),
        ],
      ],
    );
  }
}

/// An icon button that copies [value].
///
/// A tap gives a selection haptic and swaps the icon for a check for two
/// seconds. A screen reader announces "Copied!", so the feedback never
/// depends on the icon alone.
class SendCopyButton extends StatefulWidget {
  const SendCopyButton({super.key, required this.value});

  final String value;

  @override
  State<SendCopyButton> createState() => _SendCopyButtonState();
}

class _SendCopyButtonState extends State<SendCopyButton> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final t = AppLocalizations.of(context);
    final view = View.of(context);
    final direction = Directionality.of(context);
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    SemanticsService.sendAnnouncement(view, t.receive_qr_copied, direction);
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = _copied
        ? context.colors.primaryColor
        : context.colors.textSecondary;
    return IconButton(
      onPressed: _copy,
      tooltip: _copied ? t.receive_qr_copied : t.receive_qr_copy_address,
      icon: AnimatedSwitcher(
        duration: Motion.of(context, Motion.durationFast),
        child: PixIcon(
          _copied ? PixIcons.check : PixIcons.copy,
          key: ValueKey(_copied),
          size: 18,
          color: color,
        ),
      ),
    );
  }
}
