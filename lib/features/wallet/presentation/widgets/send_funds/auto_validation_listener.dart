import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';

class AutoValidationListener extends ConsumerStatefulWidget {
  final Widget child;

  const AutoValidationListener({super.key, required this.child});

  @override
  ConsumerState<AutoValidationListener> createState() =>
      _AutoValidationListenerState();
}

class _AutoValidationListenerState
    extends ConsumerState<AutoValidationListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateTransaction();
    });
  }

  void _validateTransaction() async {
    await ref
        .read(sendValidationControllerProvider.notifier)
        .validateTransaction();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(addressStateProvider, (_, __) {
      _validateTransaction();
    });

    ref.listen<int>(amountStateProvider, (_, __) {
      _validateTransaction();
    });

    ref.listen<Asset>(selectedAssetProvider, (_, __) {
      _validateTransaction();
    });

    return widget.child;
  }
}
