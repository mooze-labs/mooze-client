import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';

/// Provider that holds the current PixDeposit created during the receive flow.
/// This allows the deposit to be passed between screens (receive -> payment).
final currentDepositProvider = StateProvider<PixDeposit?>((ref) => null);