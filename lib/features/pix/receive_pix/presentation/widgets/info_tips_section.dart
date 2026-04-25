import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Data model for a single info tip. Keep it immutable so tips can live as
/// compile-time constants and are trivially replaceable with a dynamic source.
class InfoTip {
  final IconData icon;
  final String text;
  final Color iconColor;

  const InfoTip({
    required this.icon,
    required this.text,
    required this.iconColor,
  });
}

// ---------------------------------------------------------------------------
// Static tips for the PIX deposit flow.
// Each item combines a reassurance or rule into one concise sentence.
// Extend or swap this list for dynamic/remote content in the future.
// ---------------------------------------------------------------------------
const _pixDepositTips = [
  InfoTip(
    icon: Icons.info_outline_rounded,
    text:
        'Máx. 3 PIX seguidos do mesmo titular em 30 min · Limite de R\$ 5.000/dia por titular.',
    iconColor: Color(0xFFE8733A),
  ),
  InfoTip(
    icon: Icons.shield_rounded,
    text:
        'Pagamentos fora das regras são devolvidos automaticamente ao remetente.',
    iconColor: Color(0xFF2A9D6B),
  ),
  InfoTip(
    icon: Icons.access_time_rounded,
    text:
        'Processamento em 5–25 min. PIX com sinal de risco bancário pode levar 3–7 dias (estornável).',
    iconColor: Color(0xFFE8A020),
  ),
];

/// Maximum number of tips shown by default. Keeps the screen uncluttered
/// while the full list stays ready for future dynamic display.
const _defaultMaxTips = 3;

// ---------------------------------------------------------------------------
// Section widget
// ---------------------------------------------------------------------------

/// Displays a card with concise reassurance tips.
///
/// Fades in with a subtle upward slide on first render. Accepts an optional
/// [tips] override and [maxTips] cap so the caller can control content
/// without touching this file.
class InfoTipsSection extends StatefulWidget {
  /// Override the default static tip list (e.g. from a remote config).
  final List<InfoTip>? tips;

  /// Maximum number of tips to render. Defaults to [_defaultMaxTips].
  final int maxTips;

  const InfoTipsSection({super.key, this.tips, this.maxTips = _defaultMaxTips});

  @override
  State<InfoTipsSection> createState() => _InfoTipsSectionState();
}

class _InfoTipsSectionState extends State<InfoTipsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slight delay so the screen settles before the tips appear.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleTips =
        (widget.tips ?? _pixDepositTips).take(widget.maxTips).toList();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.colors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < visibleTips.length; i++) ...[
                InfoTipItem(tip: visibleTips[i]),
                if (i < visibleTips.length - 1)
                  Divider(
                    height: 20,
                    thickness: 0.5,
                    color: context.colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single tip row
// ---------------------------------------------------------------------------

/// Renders one tip: a tinted icon badge on the left and short text on the
/// right. Fully reusable — pass any [InfoTip] instance.
class InfoTipItem extends StatelessWidget {
  final InfoTip tip;

  const InfoTipItem({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: tip.iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(tip.icon, size: 16, color: tip.iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tip.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.68),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
