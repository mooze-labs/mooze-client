import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as breez;
import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/failures/failure.dart';
import '../../domain/services/platform_initializer.dart';

/// Performs all idempotent platform-level setup needed before any service
/// can be constructed: FFI inits, prefs warm-up, etc.
class PlatformInitializerImpl implements PlatformInitializer {
  PlatformInitializerImpl();

  bool _ran = false;

  @override
  Future<Either<PlatformFailure, Unit>> run() async {
    if (_ran) return const Right(unit);
    try {
      // Flutter binding is required for plugin channels to work. Caller
      // (main.dart) will normally have done this; we still call it for
      // robustness.
      WidgetsFlutterBinding.ensureInitialized();
      await LibLwk.init();
      await breez.FlutterBreezLiquid.init();
      await SharedPreferences.getInstance();
      _ran = true;
      return const Right(unit);
    } on PlatformException catch (e, st) {
      return Left(PlatformFailure('platform exception: ${e.message}',
          cause: e, stackTrace: st));
    } catch (e, st) {
      if (kDebugMode) {
        // surface FFI errors loudly during development
        debugPrint('[PlatformInitializer] init failed: $e\n$st');
      }
      return Left(PlatformFailure('platform init failed: $e',
          cause: e, stackTrace: st));
    }
  }
}
