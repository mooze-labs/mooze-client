import 'package:mooze_mobile/repositories/identity.dart';
import 'package:mooze_mobile/repositories/user.dart';
import 'package:mooze_mobile/repositories/wallet/breez.dart';
import 'package:mooze_mobile/repositories/wallet/node_config.dart';
import 'package:mooze_mobile/repositories/wallet/wollet.dart';

class AppBootstrapService {
  final BitcoinWolletRepository _bitcoinWolletRepository;
  final LiquidWolletRepository _liquidWolletRepository;
  final BreezRepository _breezRepository;
  final IdentityRepository _identityRepository;
  final UserRepository _userRepository;

  AppBootstrapService({
    required BitcoinWolletRepository bitcoinWolletRepository,
    required LiquidWolletRepository liquidWolletRepository,
    required BreezRepository breezRepository,
    required UserRepository userRepository,
    required IdentityRepository identityRepository,
  }) : _bitcoinWolletRepository = bitcoinWolletRepository,
       _liquidWolletRepository = liquidWolletRepository,
       _breezRepository = breezRepository,
       _userRepository = userRepository,
       _identityRepository = identityRepository;

  Future<void> bootstrap() async {
  }
}
