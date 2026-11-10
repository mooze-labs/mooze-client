import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../controllers/referral_input_controller.dart';
import '../widgets/active_referral_card.dart';
import '../widgets/referral_code_input.dart';
import '../widgets/referral_info_card.dart';
import '../widgets/referral_submit_button.dart';

/// Screen for viewing and applying referral codes.
///
/// Orchestrates state from Riverpod and delegates rendering
/// to focused child widgets. Uses ConsumerStatefulWidget
/// for animation controllers and text editing controller lifecycle.
class ReferralInputScreen extends ConsumerStatefulWidget {
  const ReferralInputScreen({super.key});

  @override
  ConsumerState<ReferralInputScreen> createState() =>
      _ReferralInputScreenState();
}

class _ReferralInputScreenState extends ConsumerState<ReferralInputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _referralCodeController = TextEditingController();

  /// Fades and raises the content once, when the screen opens.
  late final AnimationController _animationController = AnimationController(
    duration: Motion.durationBase,
    vsync: this,
  );
  late final Animation<double> _entrance = CurvedAnimation(
    parent: _animationController,
    curve: Motion.curveEnter,
  );

  /// Side margin of the content.
  static const double _gutter = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationController.isDismissed) {
      if (Motion.isReduced(context)) {
        _animationController.value = 1;
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(referralInputControllerProvider.notifier).clearError();
  }

  void _onSubmit() async {
    final code = _referralCodeController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      await ref
          .read(referralInputControllerProvider.notifier)
          .applyReferralCode(code);
    }
  }

  void _showSuccessMessage(BuildContext context) {
    AppSnackBar.success(
      context,
      AppLocalizations.of(context).referral_applied_success,
    );
  }

  String _translateError(BuildContext context, String errorKey) {
    final t = AppLocalizations.of(context);
    switch (errorKey) {
      case 'referral_error_empty_code':
        return t.referral_error_empty_code;
      case 'referral_error_invalid_code':
        return t.referral_error_invalid_code;
      case 'referral_error_apply_failed':
        return t.referral_error_apply_failed;
      case 'referral_error_fetch_failed':
        return t.referral_error_fetch_failed;
      case 'referral_error_validate_failed':
        return t.referral_error_validate_failed;
      default:
        return errorKey;
    }
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    AppSnackBar.error(context, _translateError(context, error));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralInputControllerProvider);
    final isApiDown = ref.watch(apiDownProvider);

    ref.listen(referralInputControllerProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        _showErrorSnackBar(context, next.error!);
        _referralCodeController.clear();
      }

      if (next.isSuccess &&
          previous?.isSuccess != next.isSuccess &&
          next.existingReferralCode != null) {
        ref.invalidate(userDataProvider);
        _showSuccessMessage(context);
        _referralCodeController.clear();
      }
    });

    final hasCode = state.existingReferralCode != null;

    // The app bar is clear and paints its slice of the backdrop, so the bar
    // and the page read as one surface.
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(
        title: Text(AppLocalizations.of(context).referral_title),
        actions: [
          ApiDownIndicatorIcon(),
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: FadeSlideIn(
              animation: _entrance,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        _gutter,
                        24,
                        _gutter,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ReferralInfoCard(),
                          const SizedBox(height: 32),
                          if (hasCode)
                            ActiveReferralCard(
                              referralCode: state.existingReferralCode!,
                            )
                          else
                            ReferralCodeInput(
                              controller: _referralCodeController,
                              isEnabled: !state.isLoading && !isApiDown,
                              isApiDown: isApiDown,
                              onChanged: _onTextChanged,
                            ),
                        ],
                      ),
                    ),
                  ),
                  // The main action stays above the keyboard and the bottom
                  // edge.
                  if (!hasCode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _gutter,
                        8,
                        _gutter,
                        12,
                      ),
                      child: ReferralSubmitButton(
                        isApiDown: isApiDown,
                        isLoading: state.isLoading,
                        onSubmit: _onSubmit,
                      ),
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
