import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/data/models/pix_status_event.dart';
import 'package:mooze_mobile/features/pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/pix_success_screen.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/pix_error_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/wallet_levels_provider.dart';
import 'package:mooze_mobile/routes.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

class PixStatusListener extends ConsumerStatefulWidget {
  final Widget child;

  const PixStatusListener({super.key, required this.child});

  @override
  ConsumerState<PixStatusListener> createState() => _PixStatusListenerState();
}

class _PixStatusListenerState extends ConsumerState<PixStatusListener> {
  StreamSubscription<PixStatusEvent>? _subscription;
  final Set<String> _processedDeposits = {};

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    final repository = ref.read(pixRepositoryProvider);

    _subscription = repository.statusUpdates.listen((statusEvent) {
      if (_processedDeposits.contains(statusEvent.depositId)) {
        return;
      }

      if (statusEvent.status == "under_review" ||
          statusEvent.status == "depix_sent" ||
          statusEvent.status == "paid" && mounted) {
        _processedDeposits.add(statusEvent.depositId);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          repository.getDeposit(statusEvent.depositId).run().then((result) {
            if (!mounted) return;

            result.fold(
              (error) {
                // error fetch deposit
              },
              (depositOption) {
                if (!mounted) return;

                depositOption.fold(
                  () {
                    // deposit not found
                  },
                  (deposit) {
                    final navigatorContext = rootNavigatorKey.currentContext;
                    if (navigatorContext != null && mounted) {
                      try {
                        PixSuccessScreen.show(
                          navigatorContext,
                          asset: deposit.asset,
                          amountInCents: deposit.amountInCents,
                          assetAmount:
                              deposit.assetAmount != null
                                  ? deposit.assetAmount!.toDouble() / 100000000
                                  : 0.0,
                          depositId: deposit.depositId,
                          blockchainTxid: deposit.blockchainTxid,
                          onClosed: () {
                            ref.invalidate(walletLevelsProvider);
                            ref.invalidate(levelsProvider);
                            ref.invalidate(userDataProvider);
                          },
                        );
                      } catch (e, stack) {
                        debugPrint('Stack: $stack');
                      }
                    } else {
                      debugPrint('Navigator context não disponível');
                    }
                  },
                );
              },
            );
          });
        });
      } else if (statusEvent.status == "failed" && mounted) {
        _processedDeposits.add(statusEvent.depositId);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          repository.getDeposit(statusEvent.depositId).run().then((result) {
            if (!mounted) return;

            result.fold(
              (error) {
                // error fetch deposit
              },
              (depositOption) {
                if (!mounted) return;

                depositOption.fold(
                  () {
                    // deposit not found
                  },
                  (deposit) {
                    final navigatorContext = rootNavigatorKey.currentContext;
                    if (navigatorContext != null && mounted) {
                      try {
                        PixErrorScreen.show(
                          navigatorContext,
                          asset: deposit.asset,
                          amountInCents: deposit.amountInCents,
                          depositId: deposit.depositId,
                          errorMessage: statusEvent.errorMessage,
                        );
                      } catch (e, stack) {
                        debugPrint('Stack: $stack');
                      }
                    } else {
                      debugPrint('Navigator context não disponível');
                    }
                  },
                );
              },
            );
          });
        });
      } else {
        debugPrint('Notification not sent for status ${statusEvent.status}');
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
