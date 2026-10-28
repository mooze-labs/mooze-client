import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../../providers/send_funds/send_validation_controller.dart';
import 'send_flow_parts.dart';

/// Lists the validation errors of the send form.
///
/// An alert icon, the "Attention" title, and one line per error carry the
/// state. The error color only tints the box.
class ValidationErrorsWidget extends ConsumerWidget {
  const ValidationErrorsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final validationState = ref.watch(sendValidationControllerProvider);
    final errors = validationState.errors;
    final showHelp = errors.any(
      (error) =>
          error.category == SendValidationErrorCategory.amount ||
          error.category == SendValidationErrorCategory.limits ||
          error.category == SendValidationErrorCategory.address,
    );

    return SizeFadeSwitcher(
      child: errors.isEmpty
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: const ValueKey('errors'),
              padding: const EdgeInsets.only(top: 18),
              child: SendNotice(
                icon: PixIcons.warning,
                tone: PixTone.negative,
                title: t.wallet_send_validation_attention,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    for (final error in errors)
                      _ErrorLine(text: error.localize(context)),
                    if (showHelp) ...[
                      const SizedBox(height: 6),
                      Text(
                        t.wallet_send_validation_help,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.4,
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

/// One error, after a small bullet.
class _ErrorLine extends StatelessWidget {
  final String text;

  const _ErrorLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.negativeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
