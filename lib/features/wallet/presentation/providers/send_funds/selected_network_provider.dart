import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';

final selectedNetworkProvider = StateProvider<Blockchain>((ref) => Blockchain.lightning);