import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

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

  Widget _buildApiDownWarning(BuildContext context) {
    final t = AppLocalizations.of(context);
    final extraColors = Theme.of(context).extension<AppExtraColors>();
    final textTheme = Theme.of(context).textTheme;
    final warningColor = extraColors?.warning ?? Colors.orange;
    final onWarningColor = extraColors?.onWarning ?? Colors.orange.shade300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: onWarningColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.referral_api_down_warning,
              style: textTheme.titleSmall?.copyWith(color: onWarningColor),
            ),
          ),
        ],
      ),
    );
  }
}
