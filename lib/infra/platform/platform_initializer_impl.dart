import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/failures/failure.dart';
import '../../domain/services/platform_initializer.dart';
import '../../shared/platform/platform_warmup.dart';

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
      // FFI inits are kicked off from `main()` via `PlatformWarmup.start()`
      // so they overlap with the rest of startup. By the time we reach
      // here they're usually already complete — this `await` is then a
      // no-op. `awaitAll` is also safe if `start` was never called
      // (lazy fallback inside the helper).
      await PlatformWarmup.awaitAll();
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
