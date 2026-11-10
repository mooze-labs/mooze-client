import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Submit section for the referral code input.
///
/// Shows either an API-down warning or the submit button,
/// depending on the API availability state.
class ReferralSubmitButton extends StatelessWidget {
  final bool isApiDown;
  final bool isLoading;
  final VoidCallback? onSubmit;

  const ReferralSubmitButton({
    super.key,
    required this.isApiDown,
    required this.isLoading,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (isApiDown) {
      return _buildApiDownWarning(context);
    }

    return PrimaryButton(
      onPressed: isLoading ? null : onSubmit,
      text: isLoading ? t.referral_validating : t.referral_apply_code,
      isEnabled: !isLoading,
    );
  }

  /// A glass panel with a small warning icon. The warning color stays on
  /// the icon, so the text keeps its contrast.
  Widget _buildApiDownWarning(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: context.appColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.referral_api_down_warning,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
