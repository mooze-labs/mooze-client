import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

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
    with TickerProviderStateMixin {
  final TextEditingController _referralCodeController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Código aplicado com sucesso!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Código de Indicação'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          ApiDownIndicatorIcon(),
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ReferralInfoCard(),
                        const SizedBox(height: 16),
                        if (state.existingReferralCode != null)
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
                        if (state.existingReferralCode == null) ...[
                          const SizedBox(height: 24),
                          ReferralSubmitButton(
                            isApiDown: isApiDown,
                            isLoading: state.isLoading,
                            onSubmit: _onSubmit,
                          ),
                          const SizedBox(height: 25),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
