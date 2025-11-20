import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';

final feeSpeedProvider = StateProvider<FeeSpeed>((ref) => FeeSpeed.medium);
