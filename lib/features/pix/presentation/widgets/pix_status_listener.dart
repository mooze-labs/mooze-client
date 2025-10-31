import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/data/models/pix_status_event.dart';
import 'package:mooze_mobile/features/pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/pix_success_screen.dart';

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

      if (statusEvent.status == "processing" && mounted) {
        _processedDeposits.add(statusEvent.depositId);

        repository.getDeposit(statusEvent.depositId).run().then((result) {
          result.fold(
            (error) {
              debugPrint('Error fetching deposit details: $error');
            },
            (depositOption) {
              depositOption.fold(
                () {
                  debugPrint('Deposit not found: ${statusEvent.depositId}');
                },
                (deposit) {
                  if (mounted) {
                    PixSuccessScreen.show(
                      context,
                      asset: deposit.asset,
                      amountInCents: deposit.amountInCents,
                      assetAmount:
                          deposit.assetAmount != null
                              ? deposit.assetAmount!.toDouble() / 100000000
                              : 0.0,
                      depositId: deposit.depositId,
                      blockchainTxid: deposit.blockchainTxid,
                    );
                  }
                },
              );
            },
          );
        });
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
